const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

const {
  GENERIC_PLATFORM_CONFIG,
  approveRegistrationRequestImpl,
  rejectRegistrationRequestImpl,
  recordDirectorFirstLoginImpl,
  assertCallerIsSuperadmin,
} = require("../functions/registration_provisioning");
const {
  pricingForCountry,
  evaluateTrialLimits,
  legacyTenantUnenforced,
  TRIAL_DAYS,
} = require("../functions/saas_pricing_v1");

function applyField(target, key, value) {
  const method = value && value._methodName;
  if (method === "FieldValue.delete") {
    delete target[key];
    return;
  }
  if (method === "FieldValue.serverTimestamp") {
    target[key] = { toMillis: () => Date.now() };
    return;
  }
  target[key] = value;
}

function mergeData(data) {
  const out = {};
  Object.entries(data || {}).forEach(([key, value]) => applyField(out, key, value));
  return out;
}

function createFakeDb(seed) {
  const docs = new Map(Object.entries(seed || {}));
  let queue = Promise.resolve();

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
      async set(data) {
        docs.set(path, { ...(docs.get(path) || {}), ...mergeData(data) });
      },
      async update(data) {
        if (!docs.has(path)) {
          throw new Error(`missing ${path}`);
        }
        docs.set(path, { ...docs.get(path), ...mergeData(data) });
      },
      async delete() {
        docs.delete(path);
      },
      collection(name) {
        return {
          doc(id) {
            return ref(`${path}/${name}/${id}`);
          },
        };
      },
    };
  }

  return {
    docs,
    collection(name) {
      return {
        doc(id) {
          const docId = id || `gen-${docs.size + 1}`;
          return ref(`${name}/${docId}`);
        },
        async add(data) {
          const document = this.doc();
          await document.set(data);
          return document;
        },
      };
    },
    batch() {
      const ops = [];
      return {
        set(document, data) {
          ops.push(() => document.set(data));
        },
        async commit() {
          for (const op of ops) {
            await op();
          }
        },
      };
    },
    runTransaction(fn) {
      const run = queue.then(() =>
        fn({
          async get(document) {
            return document.get();
          },
          async update(document, data) {
            await document.update(data);
          },
          async set(document, data) {
            await document.set(data);
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

function createFakeAuth() {
  const users = new Map();
  let seq = 0;
  return {
    users,
    async getUserByEmail(email) {
      for (const user of users.values()) {
        if (user.email === email) {
          return user;
        }
      }
      const error = new Error("not found");
      error.code = "auth/user-not-found";
      throw error;
    },
    async createUser(params) {
      seq += 1;
      const user = { uid: `uid-${seq}`, ...params };
      users.set(user.uid, user);
      return user;
    },
    async updateUser(uid, patch) {
      Object.assign(users.get(uid), patch);
      return users.get(uid);
    },
    async deleteUser(uid) {
      users.delete(uid);
    },
    async generatePasswordResetLink() {
      return "https://example.test/reset";
    },
    async setCustomUserClaims() {},
  };
}

function pendingRequest(country = "SG") {
  return {
    email: "owner@shop.test",
    name: "Owner",
    phone: "+6590000000",
    account_type: "company",
    company_name: "Shop",
    status: "pending",
    country,
  };
}

describe("registration_provisioning", () => {
  it("generic platform config uses EC prefix and neutral order types", () => {
    assert.equal(GENERIC_PLATFORM_CONFIG.order_id_prefix, "EC");
    assert.deepEqual(GENERIC_PLATFORM_CONFIG.order_types, [
      "OnSite",
      "WalkIn",
      "Remote",
    ]);
    assert.equal(GENERIC_PLATFORM_CONFIG.industry_key, "generic");
  });

  it("generic platform config enables core SaaS modules", () => {
    const modules = GENERIC_PLATFORM_CONFIG.enabled_modules;
    assert.ok(modules.includes("orders"));
    assert.ok(modules.includes("whatsappImport"));
    assert.ok(modules.includes("customerBroadcast"));
  });

  it("field labels are neutral not florist-specific", () => {
    assert.equal(
      GENERIC_PLATFORM_CONFIG.field_labels_en.recipient_name,
      "Contact name",
    );
    assert.notEqual(
      GENERIC_PLATFORM_CONFIG.field_labels_en.service_notes,
      "Card message",
    );
  });
});

describe("saas pricing v1", () => {
  it("prices Malaysia and Singapore in minor units", () => {
    assert.deepEqual(pricingForCountry("MY").prices, {
      starter: 6900,
      pro: 19900,
      business: 39900,
    });
    assert.equal(pricingForCountry("singapore").currency, "SGD");
    assert.equal(pricingForCountry("SG").prices.pro, 7900);
    assert.equal(pricingForCountry("US"), null);
    assert.equal(TRIAL_DAYS, 14);
  });

  it("trial limits allow the cap and reject one past it", () => {
    const limits = { max_staff: 3, max_orders: 100, max_companies: 1 };
    assert.equal(
      evaluateTrialLimits(
        { staffCount: 3, orderCount: 100, companyCount: 1 },
        limits,
      ).allowed,
      true,
    );
    const over = evaluateTrialLimits(
      { staffCount: 4, orderCount: 101, companyCount: 2 },
      limits,
    );
    assert.equal(over.allowed, false);
    assert.deepEqual(over.reasons, ["staff", "orders", "companies"]);
  });

  it("leaves companies without a subscription status unenforced", () => {
    assert.equal(legacyTenantUnenforced({ Company_name: "Existing" }), true);
    assert.equal(
      legacyTenantUnenforced({ subscription_status: "trialing" }),
      false,
    );
  });
});

describe("tenant provisioning", () => {
  it("approves once, links the director, and reuses the tenant", async () => {
    const db = createFakeDb({
      "user_registration_requests/owner@shop.test": pendingRequest("MY"),
    });
    const auth = createFakeAuth();
    const first = await approveRegistrationRequestImpl(
      db,
      { requestId: "owner@shop.test" },
      "super-1",
      { auth },
    );
    const second = await approveRegistrationRequestImpl(
      db,
      { requestId: "owner@shop.test" },
      "super-1",
      { auth },
    );

    assert.equal(second.reused, true);
    assert.equal(second.companyId, first.companyId);
    assert.equal(auth.users.size, 1);
    const company = db.docs.get(`Companies/${first.companyId}`);
    assert.equal(company.subscription_status, "trialing");
    assert.equal(company.capability_tier, "pro");
    assert.equal(company.billing_country, "MY");
    assert.equal(company.currency, "MYR");
    assert.equal(company.list_price_minor, 19900);
    assert.equal(company.max_staff_seats, 3);
    assert.equal(company.max_orders_per_month, 100);
    assert.equal(company.paid_provider_activation, false);
    assert.equal(company.stripe_customer_id, null);
    const director = db.docs.get(`users/${first.userUid}`);
    assert.equal(director.role, "director");
    assert.equal(director.companyRef.path, `Companies/${first.companyId}`);
    assert.equal(director.activation_status, "pending_first_login");
    const request = db.docs.get("user_registration_requests/owner@shop.test");
    assert.equal(request.status, "approved");
    assert.equal(request.initial_password_set, false);
    assert.equal(request.password, undefined);
    assert.equal(
      db.docs.get(`tenant_platform_config/${first.companyId}`).order_id_prefix,
      "EC",
    );
  });

  it("rejects an unsupported country before creating a tenant", async () => {
    const db = createFakeDb({
      "user_registration_requests/owner@shop.test": pendingRequest("US"),
    });
    await assert.rejects(
      () =>
        approveRegistrationRequestImpl(
          db,
          { requestId: "owner@shop.test" },
          "super-1",
          { auth: createFakeAuth() },
        ),
      /Malaysia/,
    );
    assert.equal(db.docs.size, 1);
  });

  it("one of two concurrent approvals creates the tenant", async () => {
    const db = createFakeDb({
      "user_registration_requests/owner@shop.test": pendingRequest("SG"),
    });
    const auth = createFakeAuth();
    const results = await Promise.allSettled([
      approveRegistrationRequestImpl(
        db,
        { requestId: "owner@shop.test" },
        "super-1",
        { auth },
      ),
      approveRegistrationRequestImpl(
        db,
        { requestId: "owner@shop.test" },
        "super-2",
        { auth },
      ),
    ]);
    const fulfilled = results.filter((result) => result.status === "fulfilled");
    assert.ok(fulfilled.length >= 1);
    const companyIds = new Set(
      fulfilled.map((result) => result.value.companyId),
    );
    assert.equal(companyIds.size, 1);
    assert.equal(auth.users.size, 1);
    const companies = [...db.docs.keys()].filter((key) =>
      key.startsWith("Companies/"),
    );
    assert.equal(companies.length, 1);
    for (const result of results) {
      if (result.status === "rejected") {
        assert.match(String(result.reason.message), /already in progress/);
      }
    }
  });

  it("rolls a failed approval back to pending and retries the same company id", async () => {
    const db = createFakeDb({
      "user_registration_requests/owner@shop.test": pendingRequest("SG"),
    });
    const failingAuth = createFakeAuth();
    failingAuth.createUser = async () => {
      throw new Error("auth unavailable");
    };
    await assert.rejects(() =>
      approveRegistrationRequestImpl(
        db,
        { requestId: "owner@shop.test" },
        "super-1",
        { auth: failingAuth },
      ),
    );
    const request = db.docs.get("user_registration_requests/owner@shop.test");
    assert.equal(request.status, "pending");
    const companyId = request.provisioned_company_id;
    assert.ok(companyId);
    assert.equal(db.docs.has(`Companies/${companyId}`), false);

    const recovered = await approveRegistrationRequestImpl(
      db,
      { requestId: "owner@shop.test" },
      "super-1",
      { auth: createFakeAuth() },
    );
    assert.equal(recovered.companyId, companyId);
    assert.equal(
      db.docs.get("user_registration_requests/owner@shop.test").status,
      "approved",
    );
  });

  it("rejects a pending request and does not provision", async () => {
    const db = createFakeDb({
      "user_registration_requests/owner@shop.test": pendingRequest("MY"),
    });
    await rejectRegistrationRequestImpl(
      db,
      { requestId: "owner@shop.test", note: "Incomplete profile" },
      "super-1",
    );
    const request = db.docs.get("user_registration_requests/owner@shop.test");
    assert.equal(request.status, "rejected");
    assert.equal(request.rejection_note, "Incomplete profile");
    assert.equal(
      [...db.docs.keys()].some((key) => key.startsWith("Companies/")),
      false,
    );
  });

  it("denies approval when the caller is not a super admin", async () => {
    const db = createFakeDb({
      "users/staff-1": { role: "director" },
    });
    await assert.rejects(
      () =>
        assertCallerIsSuperadmin(db, {
          auth: { uid: "staff-1", token: { role: "director" } },
        }),
      /super admins/,
    );
  });

  it("records the director first login once", async () => {
    const db = createFakeDb({
      "users/uid-1": {
        role: "director",
        activation_status: "pending_first_login",
      },
    });
    const first = await recordDirectorFirstLoginImpl(db, "uid-1");
    const second = await recordDirectorFirstLoginImpl(db, "uid-1");
    assert.equal(first.recorded, true);
    assert.equal(second.recorded, false);
    assert.equal(db.docs.get("users/uid-1").activation_status, "active");
  });
});
