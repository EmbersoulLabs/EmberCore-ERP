const { describe, it, beforeEach, afterEach } = require("node:test");
const assert = require("node:assert/strict");
const Stripe = require("../functions/node_modules/stripe");

const { listPriceMinor } = require("../functions/saas_pricing_v1");
const {
  defaultSubscriptionFields,
  isSubscriptionWriteAllowed,
  mapStripeSubscriptionStatus,
  priceIdForPlan,
  planTierFromPriceId,
  constructStripeEvent,
  createCheckoutSessionImpl,
  createPortalSessionImpl,
  handleStripeWebhookEvent,
} = require("../functions/stripe_billing");

const PRICE_ENV = {
  STRIPE_PRICE_MY_STARTER_MONTHLY: "price_my_starter_month",
  STRIPE_PRICE_MY_PRO_MONTHLY: "price_my_pro_month",
  STRIPE_PRICE_MY_BUSINESS_MONTHLY: "price_my_business_month",
  STRIPE_PRICE_SG_STARTER_YEARLY: "price_sg_starter_year",
  STRIPE_PRICE_SG_BUSINESS_YEARLY: "price_sg_business_year",
};

function createFakeDb(seed) {
  const docs = new Map(Object.entries(seed || {}));
  let queue = Promise.resolve();
  let auto = 0;

  function ref(path) {
    return {
      path,
      id: path.split("/").pop(),
      async get() {
        if (!docs.has(path)) {
          return { exists: false, data: () => undefined };
        }
        return { exists: true, data: () => ({ ...docs.get(path) }) };
      },
      async set(data, options) {
        const prev = options && options.merge ? docs.get(path) || {} : {};
        docs.set(path, { ...prev, ...data });
      },
      async update(data) {
        docs.set(path, { ...(docs.get(path) || {}), ...data });
      },
      async delete() {
        docs.delete(path);
      },
    };
  }

  return {
    docs,
    collection(name) {
      return {
        doc(id) {
          return ref(`${name}/${id || `auto-${++auto}`}`);
        },
        async add(data) {
          const document = ref(`${name}/auto-${++auto}`);
          await document.set(data);
          return document;
        },
      };
    },
    runTransaction(fn) {
      const run = queue.then(() =>
        fn({
          async get(document) {
            return document.get();
          },
          set(document, data) {
            return document.set(data);
          },
        }),
      );
      queue = run.then(
        () => {},
        () => {},
      );
      return run;
    },
  };
}

function directorContext(companyId) {
  return { auth: { uid: "director-1", token: { role: "director" } } };
}

function subscription(priceId, overrides) {
  return {
    id: "sub_1",
    status: "active",
    customer: "cus_owner",
    metadata: { companyId: "coA" },
    current_period_start: 1700000000,
    current_period_end: 1800000000,
    items: { data: [{ price: { id: priceId } }] },
    ...overrides,
  };
}

describe("stripe_billing helpers", () => {
  it("defaultSubscriptionFields sets trialing starter", () => {
    const fields = defaultSubscriptionFields("starter");
    assert.equal(fields.plan_tier, "starter");
    assert.equal(fields.subscription_status, "trialing");
    assert.equal(fields.max_staff_seats, 3);
    assert.equal(fields.max_orders_per_month, 100);
    assert.ok(fields.trial_ends_at);
  });

  it("legacy company without status allows writes", () => {
    assert.equal(isSubscriptionWriteAllowed({ is_active: true }), true);
  });

  it("past_due blocks writes", () => {
    assert.equal(
      isSubscriptionWriteAllowed({
        is_active: true,
        subscription_status: "past_due",
      }),
      false,
    );
  });

  it("active trialing before trial end allows writes", () => {
    const future = new Date(Date.now() + 86400000);
    assert.equal(
      isSubscriptionWriteAllowed({
        is_active: true,
        subscription_status: "trialing",
        trial_ends_at: { toDate: () => future },
      }),
      true,
    );
  });

  it("maps stripe statuses", () => {
    assert.equal(mapStripeSubscriptionStatus("active"), "active");
    assert.equal(mapStripeSubscriptionStatus("past_due"), "past_due");
    assert.equal(mapStripeSubscriptionStatus("canceled"), "cancelled");
  });

  it("priceIdForPlan returns empty without env", () => {
    assert.equal(priceIdForPlan("starter", "month"), "");
  });
});

describe("stripe billing contract", () => {
  const previous = {};

  beforeEach(() => {
    for (const [key, value] of Object.entries(PRICE_ENV)) {
      previous[key] = process.env[key];
      process.env[key] = value;
    }
  });

  afterEach(() => {
    for (const key of Object.keys(PRICE_ENV)) {
      if (previous[key] === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = previous[key];
      }
    }
  });

  it("prices Malaysia and Singapore monthly and annual amounts", () => {
    assert.deepEqual(listPriceMinor("MY", "starter", "month"), {
      country: "MY",
      currency: "MYR",
      planTier: "starter",
      interval: "month",
      amountMinor: 6900,
    });
    assert.equal(listPriceMinor("SG", "pro", "month").amountMinor, 7900);
    assert.equal(listPriceMinor("MY", "business", "year").amountMinor, 399000);
    assert.equal(listPriceMinor("SG", "business", "year").amountMinor, 159000);
    assert.equal(listPriceMinor("US", "pro", "month"), null);
  });

  it("selects the server price and ignores client amounts", () => {
    assert.equal(priceIdForPlan("business", "year", "SG"), "price_sg_business_year");
    assert.equal(priceIdForPlan("pro", "month", "MY"), "price_my_pro_month");
    assert.equal(planTierFromPriceId("price_my_business_month"), "business");
    assert.equal(planTierFromPriceId("price_client_hack"), null);
  });

  it("rejects a bad webhook signature and accepts a valid one", () => {
    const stripe = new Stripe("sk_test_local_signature_only");
    const secret = "whsec_test_secret";
    const payload = JSON.stringify({
      id: "evt_sig",
      object: "event",
      type: "customer.subscription.updated",
    });
    const header = stripe.webhooks.generateTestHeaderString({
      payload,
      secret,
    });
    const event = constructStripeEvent(stripe, Buffer.from(payload), header, secret);
    assert.equal(event.id, "evt_sig");
    assert.throws(() =>
      constructStripeEvent(stripe, Buffer.from(`${payload} `), header, secret),
    );
  });

  it("checkout uses the company country and drops client price fields", async () => {
    const db = createFakeDb({
      "users/director-1": {
        role: "director",
        email: "owner@shop.test",
        companyRef: { id: "coA" },
      },
      "Companies/coA": {
        Company_name: "Shop A",
        billing_country: "SG",
        is_active: true,
        subscription_status: "trialing",
      },
    });
    const capture = {};
    const stripe = {
      customers: {
        async create(payload) {
          capture.customer = payload;
          return { id: "cus_new" };
        },
        async retrieve() {
          throw new Error("no existing customer");
        },
      },
      checkout: {
        sessions: {
          async create(payload) {
            capture.session = payload;
            return { url: "https://checkout.test/session", id: "cs_test" };
          },
        },
      },
    };
    const result = await createCheckoutSessionImpl(
      db,
      {
        companyId: "coA",
        planTier: "business",
        interval: "year",
        amount: 1,
        currency: "USD",
        priceId: "price_client_hack",
        billingCountry: "MY",
      },
      directorContext(),
      { stripe },
    );
    assert.equal(result.url, "https://checkout.test/session");
    assert.equal(capture.session.line_items[0].price, "price_sg_business_year");
    assert.equal(capture.session.metadata.billingCountry, "SG");
    assert.equal(db.docs.get("Companies/coA").subscription_status, "trialing");
  });

  it("denies checkout for another tenant and for staff", async () => {
    const db = createFakeDb({
      "users/director-1": {
        role: "director",
        companyRef: { id: "coA" },
      },
      "users/florist-1": { role: "florist", companyRef: { id: "coA" } },
      "Companies/coB": { billing_country: "MY", is_active: true },
    });
    const stripe = {
      customers: { async create() { throw new Error("should not create"); } },
      checkout: { sessions: { async create() { throw new Error("should not create"); } } },
    };
    await assert.rejects(
      () =>
        createCheckoutSessionImpl(
          db,
          { companyId: "coB", planTier: "starter" },
          directorContext(),
          { stripe },
        ),
      (error) => error.code === "permission-denied",
    );
    await assert.rejects(
      () =>
        createCheckoutSessionImpl(
          db,
          { companyId: "coA", planTier: "starter" },
          { auth: { uid: "florist-1", token: { role: "florist" } } },
          { stripe },
        ),
      (error) => error.code === "permission-denied",
    );
  });

  it("opens the portal only for the company's customer", async () => {
    const db = createFakeDb({
      "users/director-1": { role: "director", companyRef: { id: "coA" } },
      "Companies/coA": { stripe_customer_id: "cus_owner", billing_country: "MY" },
    });
    const capture = {};
    const stripe = {
      customers: {
        async retrieve(id) {
          return { id, metadata: { companyId: "coA" } };
        },
      },
      billingPortal: {
        sessions: {
          async create(payload) {
            capture.portal = payload;
            return { url: "https://billing.test/portal" };
          },
        },
      },
    };
    const result = await createPortalSessionImpl(
      db,
      { companyId: "coA" },
      directorContext(),
      { stripe },
    );
    assert.equal(result.url, "https://billing.test/portal");
    assert.equal(capture.portal.customer, "cus_owner");
  });

  it("applies, deduplicates and orders subscription events without deleting data", async () => {
    const db = createFakeDb({
      "Companies/coA": {
        Company_name: "Shop A",
        billing_country: "MY",
        subscription_status: "trialing",
        stripe_customer_id: "cus_owner",
        max_orders_per_month: 100,
        max_staff_seats: 3,
      },
      "trial_quota/coA": { orders_consumed: 4, staff_consumed: 1 },
    });
    const stripe = {
      subscriptions: {
        async retrieve(id) {
          return subscription("price_my_pro_month", {
            id,
            status: "past_due",
          });
        },
      },
    };
    const activated = await handleStripeWebhookEvent(db, {
      id: "evt_activate",
      type: "customer.subscription.updated",
      created: 20,
      data: { object: subscription("price_my_pro_month") },
    });
    assert.equal(activated.applied, true);
    assert.equal(db.docs.get("Companies/coA").subscription_status, "active");
    assert.equal(db.docs.get("Companies/coA").plan_tier, "pro");
    assert.equal(db.docs.get("Companies/coA").usage_period_id, "1700000000");
    assert.equal(db.docs.get("Companies/coA").max_orders_per_month, 3000);
    assert.equal(db.docs.get("Companies/coA").max_staff_seats, 10);
    assert.equal(db.docs.get("Companies/coA").broadcast_quota_monthly, 2000);
    assert.equal(
      db.docs.get("Companies/coA").plan_modules.includes("shopifyImport"),
      true,
    );
    assert.equal(db.docs.get("Companies/coA").Company_name, "Shop A");
    assert.equal(db.docs.get("trial_quota/coA").orders_consumed, 4);

    const duplicate = await handleStripeWebhookEvent(db, {
      id: "evt_activate",
      type: "customer.subscription.updated",
      created: 20,
      data: { object: subscription("price_my_starter_month") },
    });
    assert.equal(duplicate.duplicate, true);
    assert.equal(db.docs.get("Companies/coA").plan_tier, "pro");

    const stale = await handleStripeWebhookEvent(db, {
      id: "evt_old",
      type: "customer.subscription.updated",
      created: 10,
      data: { object: subscription("price_my_starter_month") },
    });
    assert.equal(stale.reason, "stale-event");
    assert.equal(db.docs.get("Companies/coA").plan_tier, "pro");

    const upgraded = await handleStripeWebhookEvent(db, {
      id: "evt_business",
      type: "customer.subscription.updated",
      created: 30,
      data: { object: subscription("price_my_business_month") },
    });
    assert.equal(upgraded.planTier, "business");
    assert.equal(db.docs.get("Companies/coA").max_companies, 1);
    assert.equal(db.docs.get("Companies/coA").max_staff_seats, 30);
    assert.equal(db.docs.get("Companies/coA").broadcast_quota_monthly, 10000);
    assert.equal(db.docs.get("Companies/coA").priority_support, true);

    const downgraded = await handleStripeWebhookEvent(db, {
      id: "evt_starter",
      type: "customer.subscription.updated",
      created: 40,
      data: { object: subscription("price_my_starter_month") },
    });
    assert.equal(downgraded.planTier, "starter");
    assert.equal(db.docs.get("Companies/coA").max_companies, 1);
    assert.equal(db.docs.get("Companies/coA").max_staff_seats, 2);
    assert.equal(db.docs.get("Companies/coA").Company_name, "Shop A");
    assert.equal(db.docs.get("trial_quota/coA").orders_consumed, 4);
    assert.equal(
      db.docs.get("Companies/coA").plan_modules.includes("shopifyImport"),
      false,
    );

    const failed = await handleStripeWebhookEvent(
      db,
      {
        id: "evt_fail",
        type: "invoice.payment_failed",
        created: 50,
        data: { object: { subscription: "sub_1" } },
      },
      { stripe },
    );
    assert.equal(failed.status, "past_due");
    assert.equal(db.docs.get("Companies/coA").Company_name, "Shop A");

    const renewed = await handleStripeWebhookEvent(db, {
      id: "evt_renew",
      type: "customer.subscription.updated",
      created: 60,
      data: {
        object: subscription("price_my_starter_month", {
          status: "active",
          current_period_end: 1900000000,
        }),
      },
    });
    assert.equal(renewed.status, "active");

    const cancelled = await handleStripeWebhookEvent(db, {
      id: "evt_cancel",
      type: "customer.subscription.deleted",
      created: 70,
      data: { object: subscription("price_my_starter_month", { status: "canceled" }) },
    });
    assert.equal(cancelled.status, "cancelled");
    assert.equal(db.docs.has("Companies/coA"), true);
    assert.equal(db.docs.get("trial_quota/coA").orders_consumed, 4);

    const mismatch = await handleStripeWebhookEvent(db, {
      id: "evt_other_customer",
      type: "customer.subscription.updated",
      created: 80,
      data: {
        object: subscription("price_my_pro_month", { customer: "cus_other" }),
      },
    });
    assert.equal(mismatch.reason, "customer-mismatch");
    assert.equal(db.docs.get("Companies/coA").subscription_status, "cancelled");
  });
});
