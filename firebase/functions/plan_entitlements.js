/**
 * Canonical SaaS module entitlements, version v1.
 *
 * Ordinary access is the intersection of an implemented module, the tenant
 * industry config, this plan, RBAC, and the subscription lifecycle.
 * Legacy companies (no subscription_status) are not migrated onto Starter.
 * Trial uses Pro modules but keeps the separate 3-staff / 100-order trial cap.
 * Appointments stays unavailable until the module is implemented.
 */
const STARTER_MODULES = Object.freeze([
  "orders",
  "pos",
  "customers",
  "products",
  "drivers",
  "fieldService",
  "invoices",
  "reports",
]);

const PRO_MODULES = Object.freeze([
  ...STARTER_MODULES,
  "whatsappImport",
  "shopifyImport",
  "materialsBom",
  "productionMenu",
  "customerBroadcast",
]);

const PAID_LIMITS = Object.freeze({
  starter: Object.freeze({
    max_staff_seats: 2,
    max_orders_per_month: 500,
    max_companies: 1,
    broadcast_quota_monthly: 0,
    capability_tier: "starter",
    priority_support: false,
  }),
  pro: Object.freeze({
    max_staff_seats: 10,
    max_orders_per_month: 3000,
    max_companies: 1,
    broadcast_quota_monthly: 2000,
    capability_tier: "pro",
    priority_support: false,
  }),
  business: Object.freeze({
    max_staff_seats: 30,
    max_orders_per_month: 10000,
    max_companies: 1,
    broadcast_quota_monthly: 10000,
    capability_tier: "business",
    priority_support: true,
  }),
});

const TRIAL_BROADCAST_QUOTA_MONTHLY = 2000;

class PlanModuleError extends Error {
  constructor(message) {
    super(message);
    this.name = "PlanModuleError";
    this.code = "plan-module";
  }
}

function subscriptionStatusOf(company) {
  return company && typeof company.subscription_status === "string"
    ? company.subscription_status.trim()
    : "";
}

function legacyCompany(company) {
  return subscriptionStatusOf(company).length === 0;
}

function modulePlanForCompany(company) {
  if (legacyCompany(company)) {
    return null;
  }
  if (subscriptionStatusOf(company) === "trialing") {
    return "pro";
  }
  const tier =
    company && typeof company.plan_tier === "string"
      ? company.plan_tier.trim().toLowerCase()
      : "";
  return tier === "pro" || tier === "business" || tier === "starter"
    ? tier
    : "starter";
}

function modulesForPlan(plan) {
  return plan === "pro" || plan === "business" ? PRO_MODULES : STARTER_MODULES;
}

function companyModuleAllowed(company, moduleKey) {
  if (moduleKey === "appointments") {
    return false;
  }
  if (legacyCompany(company)) {
    return true;
  }
  return modulesForPlan(modulePlanForCompany(company)).includes(moduleKey);
}

function subscriptionWritesOpen(company) {
  const status = subscriptionStatusOf(company);
  return !status || status === "active" || status === "trialing";
}

function assertCompanyModule(company, moduleKey) {
  if (!subscriptionWritesOpen(company)) {
    const error = new PlanModuleError(
      "Subscription does not allow this operation.",
    );
    error.code = "subscription-inactive";
    throw error;
  }
  if (!companyModuleAllowed(company, moduleKey)) {
    throw new PlanModuleError(
      `${moduleKey} is not included in the current plan. Upgrade to Pro to use it.`,
    );
  }
}

function paidEntitlementPatch(planTier) {
  const limits = PAID_LIMITS[planTier] || PAID_LIMITS.starter;
  const plan = PAID_LIMITS[planTier] ? planTier : "starter";
  return {
    max_staff_seats: limits.max_staff_seats,
    max_orders_per_month: limits.max_orders_per_month,
    max_companies: limits.max_companies,
    broadcast_quota_monthly: limits.broadcast_quota_monthly,
    capability_tier: limits.capability_tier,
    priority_support: limits.priority_support,
    plan_modules: modulesForPlan(plan).slice(),
  };
}

function trialEntitlementFields() {
  return {
    plan_modules: modulesForPlan("pro").slice(),
    broadcast_quota_monthly: TRIAL_BROADCAST_QUOTA_MONTHLY,
    priority_support: false,
  };
}

module.exports = {
  STARTER_MODULES,
  PRO_MODULES,
  PAID_LIMITS,
  TRIAL_BROADCAST_QUOTA_MONTHLY,
  PlanModuleError,
  legacyCompany,
  modulePlanForCompany,
  modulesForPlan,
  companyModuleAllowed,
  subscriptionWritesOpen,
  assertCompanyModule,
  paidEntitlementPatch,
  trialEntitlementFields,
};
