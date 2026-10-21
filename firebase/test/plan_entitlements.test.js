const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  STARTER_MODULES,
  PRO_MODULES,
  PAID_LIMITS,
  PlanModuleError,
  companyModuleAllowed,
  assertCompanyModule,
  paidEntitlementPatch,
  modulePlanForCompany,
} = require("../functions/plan_entitlements");
const { trialContractForCountry } = require("../functions/saas_pricing_v1");

const starter = {
  subscription_status: "active",
  plan_tier: "starter",
  pricing_version: "v1",
};
const pro = { ...starter, plan_tier: "pro" };
const business = { ...starter, plan_tier: "business" };
const trial = {
  subscription_status: "trialing",
  plan_tier: "pro",
  pricing_version: "v1",
  max_staff_seats: 3,
  max_orders_per_month: 100,
};

describe("plan entitlements", () => {
  it("keeps starter on the core modules", () => {
    for (const moduleName of STARTER_MODULES) {
      assert.equal(companyModuleAllowed(starter, moduleName), true);
    }
    for (const moduleName of [
      "whatsappImport",
      "shopifyImport",
      "materialsBom",
      "productionMenu",
      "customerBroadcast",
    ]) {
      assert.equal(companyModuleAllowed(starter, moduleName), false);
    }
    assert.throws(
      () => assertCompanyModule(starter, "shopifyImport"),
      PlanModuleError,
    );
  });

  it("opens Pro modules for Pro, Business and trial", () => {
    for (const company of [pro, business, trial]) {
      for (const moduleName of PRO_MODULES) {
        assert.equal(companyModuleAllowed(company, moduleName), true, moduleName);
      }
      assert.doesNotThrow(() => assertCompanyModule(company, "shopifyImport"));
    }
    assert.equal(modulePlanForCompany(trial), "pro");
    assert.equal(trial.max_orders_per_month, 100);
    assert.notEqual(trial.max_orders_per_month, PAID_LIMITS.pro.max_orders_per_month);
  });

  it("keeps appointments unavailable and legacy tenants unrestricted", () => {
    assert.equal(companyModuleAllowed(pro, "appointments"), false);
    assert.equal(companyModuleAllowed({}, "shopifyImport"), true);
    assert.equal(companyModuleAllowed({ is_active: true }, "materialsBom"), true);
    assert.equal(modulePlanForCompany({ Company_name: "Old" }), null);
  });

  it("writes paid caps without deleting the caller’s other fields", () => {
    assert.deepEqual(
      {
        staff: PAID_LIMITS.starter.max_staff_seats,
        orders: PAID_LIMITS.starter.max_orders_per_month,
        companies: PAID_LIMITS.starter.max_companies,
        broadcast: PAID_LIMITS.starter.broadcast_quota_monthly,
      },
      { staff: 2, orders: 500, companies: 1, broadcast: 0 },
    );
    assert.equal(PAID_LIMITS.pro.max_staff_seats, 10);
    assert.equal(PAID_LIMITS.pro.max_orders_per_month, 3000);
    assert.equal(PAID_LIMITS.pro.broadcast_quota_monthly, 2000);
    assert.equal(PAID_LIMITS.business.max_staff_seats, 30);
    assert.equal(PAID_LIMITS.business.max_orders_per_month, 10000);
    assert.equal(PAID_LIMITS.business.broadcast_quota_monthly, 10000);
    assert.equal(PAID_LIMITS.business.max_companies, 1);
    assert.equal(PAID_LIMITS.business.priority_support, true);
    const patch = paidEntitlementPatch("starter");
    assert.equal(patch.plan_modules.includes("shopifyImport"), false);
    assert.equal(paidEntitlementPatch("business").priority_support, true);
  });

  it("keeps the trial contract on Pro modules and trial caps", () => {
    const contract = trialContractForCountry("MY");
    assert.equal(contract.max_staff_seats, 3);
    assert.equal(contract.max_orders_per_month, 100);
    assert.equal(contract.max_companies, 1);
    assert.equal(contract.plan_tier, "pro");
    assert.equal(contract.broadcast_quota_monthly, 2000);
    assert.equal(contract.plan_modules.includes("shopifyImport"), true);
    assert.equal(contract.plan_modules.includes("appointments"), false);
  });

  it("blocks new imports after the subscription is cancelled", () => {
    assert.throws(
      () =>
        assertCompanyModule(
          { subscription_status: "cancelled", plan_tier: "pro" },
          "shopifyImport",
        ),
      (error) => error.code === "subscription-inactive",
    );
  });
});
