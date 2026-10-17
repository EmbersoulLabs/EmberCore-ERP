/**
 * Stripe subscription billing for EmberCore SaaS tenants.
 *
 * Amounts and currencies come from saas_pricing_v1.js.
 * Stripe Price IDs come only from server config, never from the client.
 *
 * Test-mode config (env or firebase functions:config), one key per
 * country, plan and interval:
 *   STRIPE_SECRET_KEY
 *   STRIPE_WEBHOOK_SECRET
 *   STRIPE_PRICE_MY_STARTER_MONTHLY ... STRIPE_PRICE_SG_BUSINESS_YEARLY
 *   BILLING_APP_URL
 * Legacy MY monthly/yearly keys STRIPE_PRICE_STARTER_MONTHLY still resolve
 * for Malaysia only. Live keys must not be placed in source control.
 */
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const {
  listPriceMinor,
  normalizeCountry,
  normalizeInterval,
  normalizePlanTier,
} = require("./saas_pricing_v1");
const { PAID_LIMITS, paidEntitlementPatch } = require("./plan_entitlements");

const TRIAL_DAYS = 14;
const EVENT_COLLECTION = "stripe_webhook_events";

const PLAN_LIMITS = PAID_LIMITS;

const PRICE_IDS = [
  "my_starter_monthly",
  "my_starter_yearly",
  "my_pro_monthly",
  "my_pro_yearly",
  "my_business_monthly",
  "my_business_yearly",
  "sg_starter_monthly",
  "sg_starter_yearly",
  "sg_pro_monthly",
  "sg_pro_yearly",
  "sg_business_monthly",
  "sg_business_yearly",
  "starter_monthly",
  "starter_yearly",
  "pro_monthly",
  "pro_yearly",
  "business_monthly",
  "business_yearly",
];

const BILLING_ROLES = new Set(["director", "admin", "superadmin"]);

function httpsError(code, message) {
  return new functions.https.HttpsError(code, message);
}

function trimmed(value) {
  return typeof value === "string" ? value.trim() : "";
}

function readStripeConfig() {
  const cfg = functions.config().stripe || {};
  const prices = {};
  for (const id of PRICE_IDS) {
    const envName = `STRIPE_PRICE_${id.toUpperCase()}`;
    prices[id] = trimmed(process.env[envName] || cfg[`price_${id}`] || "");
  }
  return {
    secretKey: trimmed(
      process.env.STRIPE_SECRET_KEY || cfg.secret_key || cfg.secret || "",
    ),
    webhookSecret: trimmed(
      process.env.STRIPE_WEBHOOK_SECRET || cfg.webhook_secret || "",
    ),
    appUrl: (
      process.env.BILLING_APP_URL ||
      cfg.app_url ||
      "https://embercore-erp.web.app"
    ).replace(/\/$/, ""),
    prices,
  };
}

function getStripe() {
  const { secretKey } = readStripeConfig();
  if (!secretKey) {
    return null;
  }
  // eslint-disable-next-line global-require
  const Stripe = require("stripe");
  return new Stripe(secretKey, { apiVersion: "2024-06-20" });
}

/**
 * Unused by provisioning. Trial tenants are written by trialContractForCountry
 * (Pro modules, 3 staff, 100 lifetime orders). Paid caps are applied only
 * after a verified subscription event.
 */
function defaultSubscriptionFields(planTier = "starter") {
  const trialEnds = new Date();
  trialEnds.setUTCDate(trialEnds.getUTCDate() + TRIAL_DAYS);
  return {
    plan_tier: planTier,
    subscription_status: "trialing",
    trial_ends_at: admin.firestore.Timestamp.fromDate(trialEnds),
    current_period_end: null,
    stripe_customer_id: null,
    stripe_subscription_id: null,
    max_staff_seats: 3,
    max_orders_per_month: 100,
  };
}

function priceIdForPlan(planTier, interval, country) {
  const plan = normalizePlanTier(planTier);
  const period = normalizeInterval(interval) === "year" ? "yearly" : "monthly";
  const code = normalizeCountry(country).toLowerCase();
  if (!plan) {
    return "";
  }
  const { prices } = readStripeConfig();
  if (code === "my" || code === "sg") {
    const specific = prices[`${code}_${plan}_${period}`];
    if (specific) {
      return specific;
    }
  }
  if (code === "my") {
    return prices[`${plan}_${period}`] || "";
  }
  return "";
}

function mapStripeSubscriptionStatus(stripeStatus) {
  switch (stripeStatus) {
    case "trialing":
      return "trialing";
    case "active":
      return "active";
    case "past_due":
      return "past_due";
    case "canceled":
    case "cancelled":
      return "cancelled";
    case "unpaid":
      return "unpaid";
    case "incomplete":
    case "incomplete_expired":
      return "cancelled";
    default:
      return "active";
  }
}

function planTierFromPriceId(priceId) {
  if (!priceId) {
    return null;
  }
  const { prices } = readStripeConfig();
  for (const [key, value] of Object.entries(prices)) {
    if (value && value === priceId) {
      if (key.includes("business")) {
        return "business";
      }
      if (key.includes("pro")) {
        return "pro";
      }
      if (key.includes("starter")) {
        return "starter";
      }
    }
  }
  return null;
}

function customerIdOf(value) {
  if (!value) {
    return "";
  }
  if (typeof value === "string") {
    return value;
  }
  return trimmed(value.id);
}

function subscriptionPriceId(subscription) {
  return (
    subscription &&
    subscription.items &&
    subscription.items.data &&
    subscription.items.data[0] &&
    subscription.items.data[0].price &&
    subscription.items.data[0].price.id
  ) || "";
}

/** Whether tenant writes (e.g. create order) should be allowed from subscription data. */
function isSubscriptionWriteAllowed(companyData) {
  const data = companyData || {};
  if (data.is_active === false) {
    return false;
  }
  const status = trimmed(data.subscription_status);
  if (!status) {
    return true;
  }
  if (status === "active") {
    return true;
  }
  if (status === "trialing") {
    const trialEnds = data.trial_ends_at;
    if (!trialEnds) {
      return true;
    }
    const date =
      typeof trialEnds.toDate === "function" ? trialEnds.toDate() : trialEnds;
    return date instanceof Date && date.getTime() > Date.now();
  }
  return false;
}

async function assertCallerCanManageBilling(db, context, companyId) {
  if (!context.auth || !context.auth.uid) {
    throw httpsError("unauthenticated", "Sign in to manage billing.");
  }
  const uid = context.auth.uid;
  const tokenRole =
    context.auth.token && typeof context.auth.token.role === "string"
      ? context.auth.token.role
      : null;
  const userSnap = await db.collection("users").doc(uid).get();
  const profile = userSnap.exists ? userSnap.data() : {};
  const role = tokenRole || profile.role || "";
  if (!BILLING_ROLES.has(role)) {
    throw httpsError(
      "permission-denied",
      "Only directors and admins can manage billing.",
    );
  }
  if (role === "superadmin") {
    return { uid, role, companyRef: null };
  }
  const companyRef = profile.companyRef;
  if (!companyRef || companyRef.id !== companyId) {
    throw httpsError(
      "permission-denied",
      "You can only manage billing for your own company.",
    );
  }
  return { uid, role, companyRef };
}

async function ensureStripeCustomer(stripe, db, companyId, companyData, email) {
  const existing = trimmed(companyData.stripe_customer_id);
  if (existing) {
    const customer = await stripe.customers.retrieve(existing);
    const owner = customer && customer.metadata && customer.metadata.companyId;
    if (owner && owner !== companyId) {
      throw httpsError(
        "permission-denied",
        "Stripe customer does not belong to this company.",
      );
    }
    return existing;
  }
  const customer = await stripe.customers.create({
    email: trimmed(email) || undefined,
    name: trimmed(companyData.Company_name) || undefined,
    metadata: { companyId },
  });
  await db.collection("Companies").doc(companyId).update({
    stripe_customer_id: customer.id,
  });
  return customer.id;
}

async function syncSubscriptionToCompany(db, subscription, eventCreated) {
  const companyId = subscription.metadata && subscription.metadata.companyId;
  if (!companyId) {
    functions.logger.warn("Stripe subscription missing companyId metadata", {
      subscriptionId: subscription.id,
    });
    return { applied: false, reason: "missing-company" };
  }
  const companyRef = db.collection("Companies").doc(companyId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    return { applied: false, reason: "missing-company" };
  }
  const company = companySnap.data() || {};
  const customerId = customerIdOf(subscription.customer);
  if (
    trimmed(company.stripe_customer_id) &&
    customerId &&
    trimmed(company.stripe_customer_id) !== customerId
  ) {
    functions.logger.warn("Stripe customer does not match company", {
      companyId,
    });
    return { applied: false, reason: "customer-mismatch" };
  }
  const created = Number(eventCreated || 0);
  if (created < Number(company.stripe_event_created || 0)) {
    return { applied: false, reason: "stale-event" };
  }
  const priceId = subscriptionPriceId(subscription);
  const planTier = planTierFromPriceId(priceId);
  if (!planTier) {
    functions.logger.warn("Stripe price is not in the server catalog", {
      companyId,
    });
    return { applied: false, reason: "unknown-price" };
  }
  const limits = paidEntitlementPatch(planTier);
  const yearly = Object.entries(readStripeConfig().prices).some(
    ([key, value]) => value === priceId && key.endsWith("yearly"),
  );
  const interval = yearly ? "year" : "month";
  const quote = listPriceMinor(company.billing_country, planTier, interval);
  const status = mapStripeSubscriptionStatus(subscription.status);
  const patch = {
    plan_tier: planTier,
    capability_tier: limits.capability_tier,
    subscription_status: status,
    stripe_subscription_id: subscription.id,
    stripe_customer_id: customerId || company.stripe_customer_id || null,
    max_staff_seats: limits.max_staff_seats,
    max_orders_per_month: limits.max_orders_per_month,
    max_companies: limits.max_companies,
    broadcast_quota_monthly: limits.broadcast_quota_monthly,
    priority_support: limits.priority_support,
    plan_modules: limits.plan_modules,
    billing_interval: interval,
    paid_provider_activation: status === "active" || status === "past_due",
    stripe_event_created: created,
    current_period_end: subscription.current_period_end
      ? admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000)
      : null,
  };
  if (subscription.current_period_start) {
    patch.usage_period_id = String(subscription.current_period_start);
  }
  if (quote) {
    patch.currency = quote.currency;
    patch.list_price_minor = quote.amountMinor;
  }
  if (subscription.trial_end) {
    patch.trial_ends_at = admin.firestore.Timestamp.fromMillis(
      subscription.trial_end * 1000,
    );
  }
  await companyRef.set(patch, { merge: true });
  await db.collection("audit_logs").add({
    action: "billing.subscription_updated",
    entityType: "company",
    entityId: companyId,
    companyId,
    description: `Subscription ${status} on ${planTier}`,
    newValue: {
      planTier,
      status,
      interval,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { applied: true, planTier, status };
}

async function claimStripeEvent(db, event) {
  if (!event || !event.id) {
    return false;
  }
  const ref = db.collection(EVENT_COLLECTION).doc(event.id);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      return false;
    }
    tx.set(ref, {
      type: event.type || "",
      created: Number(event.created || 0),
    });
    return true;
  });
}

async function applySubscriptionEvent(db, stripe, event, subscriptionId) {
  if (!stripe) {
    throw new Error("Stripe is not configured");
  }
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  return syncSubscriptionToCompany(db, subscription, event.created);
}

async function markSubscriptionCancelled(db, subscription, eventCreated) {
  const companyId = subscription.metadata && subscription.metadata.companyId;
  if (!companyId) {
    return { applied: false, reason: "missing-company" };
  }
  const companyRef = db.collection("Companies").doc(companyId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    return { applied: false, reason: "missing-company" };
  }
  const company = companySnap.data() || {};
  const customerId = customerIdOf(subscription.customer);
  if (
    trimmed(company.stripe_customer_id) &&
    customerId &&
    trimmed(company.stripe_customer_id) !== customerId
  ) {
    return { applied: false, reason: "customer-mismatch" };
  }
  const created = Number(eventCreated || 0);
  if (created < Number(company.stripe_event_created || 0)) {
    return { applied: false, reason: "stale-event" };
  }
  await companyRef.set(
    {
      subscription_status: "cancelled",
      stripe_subscription_id: null,
      paid_provider_activation: false,
      stripe_event_created: created,
    },
    { merge: true },
  );
  await db.collection("audit_logs").add({
    action: "billing.subscription_cancelled",
    entityType: "company",
    entityId: companyId,
    companyId,
    description: "Subscription cancelled",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { applied: true, status: "cancelled" };
}

async function handleStripeWebhookEvent(db, event, options) {
  const stripe = (options && options.stripe) || getStripe();
  const claimed = await claimStripeEvent(db, event);
  if (!claimed) {
    return { duplicate: true, applied: false };
  }
  try {
    const object = (event.data && event.data.object) || {};
    switch (event.type) {
      case "checkout.session.completed": {
        if (object.mode !== "subscription" || !object.subscription) {
          return { duplicate: false, applied: false, reason: "ignored" };
        }
        const result = await applySubscriptionEvent(
          db,
          stripe,
          event,
          object.subscription,
        );
        return { duplicate: false, ...result };
      }
      case "customer.subscription.deleted":
        return {
          duplicate: false,
          ...(await markSubscriptionCancelled(db, object, event.created)),
        };
      case "customer.subscription.created":
      case "customer.subscription.updated":
        return {
          duplicate: false,
          ...(await syncSubscriptionToCompany(db, object, event.created)),
        };
      case "invoice.payment_failed":
      case "invoice.payment_succeeded": {
        if (!object.subscription) {
          return { duplicate: false, applied: false, reason: "ignored" };
        }
        const result = await applySubscriptionEvent(
          db,
          stripe,
          event,
          object.subscription,
        );
        return { duplicate: false, ...result };
      }
      default:
        return { duplicate: false, applied: false, reason: "ignored" };
    }
  } catch (error) {
    try {
      await db.collection(EVENT_COLLECTION).doc(event.id).delete();
    } catch (_) {
      // The next delivery may see a duplicate claim and stop. Prefer retry.
    }
    throw error;
  }
}

function constructStripeEvent(stripe, rawBody, signature, secret) {
  return stripe.webhooks.constructEvent(rawBody, signature, secret);
}

async function createCheckoutSessionImpl(db, data, context, options) {
  const stripe = (options && options.stripe) || getStripe();
  if (!stripe) {
    throw httpsError(
      "failed-precondition",
      "Stripe is not configured on the server.",
    );
  }

  const companyId = trimmed(data && data.companyId);
  if (!companyId) {
    throw httpsError("invalid-argument", "companyId is required.");
  }
  const planTier = normalizePlanTier(data && data.planTier);
  if (!planTier) {
    throw httpsError(
      "invalid-argument",
      "planTier must be starter, pro or business.",
    );
  }
  const interval = normalizeInterval(data && data.interval);

  const caller = await assertCallerCanManageBilling(db, context, companyId);
  const companySnap = await db.collection("Companies").doc(companyId).get();
  if (!companySnap.exists) {
    throw httpsError("not-found", "Company not found.");
  }
  const companyData = companySnap.data() || {};
  const quote = listPriceMinor(companyData.billing_country, planTier, interval);
  if (!quote) {
    throw httpsError(
      "failed-precondition",
      "This company has no Malaysia or Singapore billing country.",
    );
  }
  const priceId = priceIdForPlan(planTier, interval, quote.country);
  if (!priceId) {
    throw httpsError(
      "failed-precondition",
      `Stripe price is not configured for ${quote.country} ${planTier} (${interval}).`,
    );
  }

  const userSnap = await db.collection("users").doc(caller.uid).get();
  const email = userSnap.exists ? trimmed(userSnap.data().email) : "";

  const customerId = await ensureStripeCustomer(
    stripe,
    db,
    companyId,
    companyData,
    email,
  );

  const { appUrl } = readStripeConfig();
  const returnPath = "/billingPage";
  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${appUrl}${returnPath}?billing=success`,
    cancel_url: `${appUrl}${returnPath}?billing=cancelled`,
    subscription_data: {
      metadata: {
        companyId,
        planTier,
        billingCountry: quote.country,
        interval,
      },
    },
    metadata: {
      companyId,
      planTier,
      billingCountry: quote.country,
      interval,
    },
    allow_promotion_codes: true,
  });

  return { url: session.url, sessionId: session.id };
}

async function createPortalSessionImpl(db, data, context, options) {
  const stripe = (options && options.stripe) || getStripe();
  if (!stripe) {
    throw httpsError(
      "failed-precondition",
      "Stripe is not configured on the server.",
    );
  }

  const companyId = trimmed(data && data.companyId);
  if (!companyId) {
    throw httpsError("invalid-argument", "companyId is required.");
  }

  await assertCallerCanManageBilling(db, context, companyId);
  const companySnap = await db.collection("Companies").doc(companyId).get();
  if (!companySnap.exists) {
    throw httpsError("not-found", "Company not found.");
  }
  const companyData = companySnap.data() || {};
  const customerId = trimmed(companyData.stripe_customer_id);
  if (!customerId) {
    throw httpsError(
      "failed-precondition",
      "No Stripe customer yet. Subscribe to a plan first.",
    );
  }
  const customer = await stripe.customers.retrieve(customerId);
  const owner = customer && customer.metadata && customer.metadata.companyId;
  if (owner && owner !== companyId) {
    throw httpsError(
      "permission-denied",
      "Stripe customer does not belong to this company.",
    );
  }

  const { appUrl } = readStripeConfig();
  const session = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: `${appUrl}/billingPage`,
  });

  return { url: session.url };
}

/**
 * Best-effort Stripe customer for a newly provisioned tenant (non-blocking).
 */
async function maybeCreateStripeCustomerForCompany(
  db,
  companyId,
  companyName,
  directorEmail,
) {
  const stripe = getStripe();
  if (!stripe) {
    return null;
  }
  try {
    const customer = await stripe.customers.create({
      email: trimmed(directorEmail) || undefined,
      name: trimmed(companyName) || undefined,
      metadata: { companyId },
    });
    await db.collection("Companies").doc(companyId).update({
      stripe_customer_id: customer.id,
    });
    return customer.id;
  } catch (error) {
    functions.logger.warn("Stripe customer creation skipped during provisioning", {
      companyId,
      message: error && error.message,
    });
    return null;
  }
}

module.exports = {
  TRIAL_DAYS,
  PLAN_LIMITS,
  readStripeConfig,
  getStripe,
  defaultSubscriptionFields,
  priceIdForPlan,
  planTierFromPriceId,
  mapStripeSubscriptionStatus,
  isSubscriptionWriteAllowed,
  constructStripeEvent,
  createCheckoutSessionImpl,
  createPortalSessionImpl,
  handleStripeWebhookEvent,
  maybeCreateStripeCustomerForCompany,
};
