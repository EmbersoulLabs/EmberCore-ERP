/**
 * Server-authoritative SaaS pricing contract, version v1.
 * Amounts are minor currency units (sen / cents). No payment provider is called.
 */
const PRICING_VERSION = "v1";
const TRIAL_DAYS = 14;

const PLAN_TIERS = ["starter", "pro", "business"];

const COUNTRY_PRICES = {
  MY: {
    currency: "MYR",
    starter: 6900,
    pro: 19900,
    business: 39900,
  },
  SG: {
    currency: "SGD",
    starter: 2900,
    pro: 7900,
    business: 15900,
  },
};

/** Annual amounts are minor units. Ten times the monthly price. */
const ANNUAL_COUNTRY_PRICES = {
  MY: {
    currency: "MYR",
    starter: 69000,
    pro: 199000,
    business: 399000,
  },
  SG: {
    currency: "SGD",
    starter: 29000,
    pro: 79000,
    business: 159000,
  },
};

const { trialEntitlementFields } = require("./plan_entitlements");

const TRIAL_LIMITS = {
  max_staff: 3,
  max_orders: 100,
  max_companies: 1,
  capability_tier: "pro",
  paid_provider_activation: false,
};

function normalizeCountry(value) {
  const raw = typeof value === "string" ? value.trim().toUpperCase() : "";
  if (raw === "MALAYSIA") {
    return "MY";
  }
  if (raw === "SINGAPORE") {
    return "SG";
  }
  return raw;
}

function normalizeInterval(value) {
  const raw = typeof value === "string" ? value.trim().toLowerCase() : "";
  return raw === "year" || raw === "yearly" || raw === "annual" ? "year" : "month";
}

function normalizePlanTier(value) {
  const raw = typeof value === "string" ? value.trim().toLowerCase() : "";
  return PLAN_TIERS.includes(raw) ? raw : "";
}

/** Server price quote. Client amounts, currencies and Price IDs are ignored. */
function listPriceMinor(country, planTier, interval) {
  const code = normalizeCountry(country);
  const plan = normalizePlanTier(planTier);
  if (!plan) {
    return null;
  }
  const period = normalizeInterval(interval);
  const table = period === "year" ? ANNUAL_COUNTRY_PRICES : COUNTRY_PRICES;
  const row = table[code];
  if (!row || typeof row[plan] !== "number") {
    return null;
  }
  return {
    country: code,
    currency: row.currency,
    planTier: plan,
    interval: period,
    amountMinor: row[plan],
  };
}

function pricingForCountry(country) {
  const code = normalizeCountry(country);
  const row = COUNTRY_PRICES[code];
  if (!row) {
    return null;
  }
  return {
    pricing_version: PRICING_VERSION,
    country: code,
    currency: row.currency,
    prices: {
      starter: row.starter,
      pro: row.pro,
      business: row.business,
    },
  };
}

/**
 * Trial snapshot written only by the server. Capabilities match Pro.
 * Limits stay at the trial caps. No payment provider is activated.
 */
function trialContractForCountry(country) {
  const pricing = pricingForCountry(country);
  if (!pricing) {
    return null;
  }
  return {
    pricing_version: pricing.pricing_version,
    billing_country: pricing.country,
    currency: pricing.currency,
    list_price_minor: pricing.prices.pro,
    capability_tier: TRIAL_LIMITS.capability_tier,
    plan_tier: TRIAL_LIMITS.capability_tier,
    subscription_status: "trialing",
    trial_days: TRIAL_DAYS,
    trial_limits: {
      max_staff: TRIAL_LIMITS.max_staff,
      max_orders: TRIAL_LIMITS.max_orders,
      max_companies: TRIAL_LIMITS.max_companies,
    },
    max_staff_seats: TRIAL_LIMITS.max_staff,
    max_orders_per_month: TRIAL_LIMITS.max_orders,
    max_companies: TRIAL_LIMITS.max_companies,
    paid_provider_activation: false,
    stripe_customer_id: null,
    stripe_subscription_id: null,
    current_period_end: null,
    ...trialEntitlementFields(),
  };
}

function evaluateTrialLimits(usage, limits) {
  const caps = limits || TRIAL_LIMITS;
  const reasons = [];
  if ((usage && usage.staffCount) > caps.max_staff) {
    reasons.push("staff");
  }
  if ((usage && usage.orderCount) > caps.max_orders) {
    reasons.push("orders");
  }
  if ((usage && usage.companyCount) > caps.max_companies) {
    reasons.push("companies");
  }
  return { allowed: reasons.length === 0, reasons };
}

/** Companies with no subscription status stay on the legacy access path. */
function legacyTenantUnenforced(companyData) {
  const status =
    companyData && typeof companyData.subscription_status === "string"
      ? companyData.subscription_status.trim()
      : "";
  return status.length === 0;
}

module.exports = {
  PRICING_VERSION,
  TRIAL_DAYS,
  TRIAL_LIMITS,
  PLAN_TIERS,
  COUNTRY_PRICES,
  ANNUAL_COUNTRY_PRICES,
  normalizeCountry,
  normalizeInterval,
  normalizePlanTier,
  listPriceMinor,
  pricingForCountry,
  trialContractForCountry,
  evaluateTrialLimits,
  legacyTenantUnenforced,
};
