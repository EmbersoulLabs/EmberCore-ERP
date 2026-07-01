/**
 * Stripe subscription billing for EmberCore SaaS tenants.
 *
 * Config (env or firebase functions:config):
 *   STRIPE_SECRET_KEY
 *   STRIPE_WEBHOOK_SECRET
 *   STRIPE_PRICE_STARTER_MONTHLY, STRIPE_PRICE_PRO_MONTHLY
 *   STRIPE_PRICE_STARTER_YEARLY, STRIPE_PRICE_PRO_YEARLY (optional)
 *   BILLING_APP_URL — e.g. https://embercore-erp.web.app
 */
const admin = require("firebase-admin");
const functions = require("firebase-functions");

const TRIAL_DAYS = 14;

const PLAN_LIMITS = {
  starter: { max_staff_seats: 5, max_orders_per_month: 500 },
  pro: { max_staff_seats: 20, max_orders_per_month: null },
};

const BILLING_ROLES = new Set(["director", "admin", "superadmin"]);

function httpsError(code, message) {
  return new functions.https.HttpsError(code, message);
}

function trimmed(value) {
  return typeof value === "string" ? value.trim() : "";
}

function readStripeConfig() {
  const cfg = functions.config().stripe || {};
  return {
    secretKey:
      process.env.STRIPE_SECRET_KEY || cfg.secret_key || cfg.secret || "",
    webhookSecret:
      process.env.STRIPE_WEBHOOK_SECRET || cfg.webhook_secret || "",
    appUrl:
      (process.env.BILLING_APP_URL || cfg.app_url || "https://embercore-erp.web.app")
        .replace(/\/$/, ""),
    prices: {
      starter_monthly:
        process.env.STRIPE_PRICE_STARTER_MONTHLY || cfg.price_starter_monthly || "",
      pro_monthly:
        process.env.STRIPE_PRICE_PRO_MONTHLY || cfg.price_pro_monthly || "",
      starter_yearly:
        process.env.STRIPE_PRICE_STARTER_YEARLY || cfg.price_starter_yearly || "",
      pro_yearly:
        process.env.STRIPE_PRICE_PRO_YEARLY || cfg.price_pro_yearly || "",
    },
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

/** Default Firestore fields for newly provisioned SaaS tenants. */
function defaultSubscriptionFields(planTier = "starter") {
  const limits = PLAN_LIMITS[planTier] || PLAN_LIMITS.starter;
  const trialEnds = new Date();
  trialEnds.setUTCDate(trialEnds.getUTCDate() + TRIAL_DAYS);
  return {
    plan_tier: planTier,
    subscription_status: "trialing",
    trial_ends_at: admin.firestore.Timestamp.fromDate(trialEnds),
    current_period_end: null,
    stripe_customer_id: null,
    stripe_subscription_id: null,
    max_staff_seats: limits.max_staff_seats,
    max_orders_per_month: limits.max_orders_per_month,
  };
}

function priceIdForPlan(planTier, interval) {
  const tier = trimmed(planTier).toLowerCase();
  const billing = trimmed(interval).toLowerCase() === "year" ? "yearly" : "monthly";
  const key = `${tier}_${billing}`;
  const { prices } = readStripeConfig();
  const map = {
    starter_monthly: prices.starter_monthly,
    pro_monthly: prices.pro_monthly,
    starter_yearly: prices.starter_yearly,
    pro_yearly: prices.pro_yearly,
  };
  return map[key] || "";
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
  const { prices } = readStripeConfig();
  if (!priceId) {
    return "starter";
  }
  if (priceId === prices.pro_monthly || priceId === prices.pro_yearly) {
    return "pro";
  }
  return "starter";
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

async function syncSubscriptionToCompany(db, subscription) {
  const companyId = subscription.metadata && subscription.metadata.companyId;
  if (!companyId) {
    functions.logger.warn("Stripe subscription missing companyId metadata", {
      subscriptionId: subscription.id,
    });
    return;
  }
  const priceId =
    subscription.items &&
    subscription.items.data &&
    subscription.items.data[0] &&
    subscription.items.data[0].price &&
    subscription.items.data[0].price.id;
  const planTier = planTierFromPriceId(priceId);
  const limits = PLAN_LIMITS[planTier] || PLAN_LIMITS.starter;
  const patch = {
    plan_tier: planTier,
    subscription_status: mapStripeSubscriptionStatus(subscription.status),
    stripe_subscription_id: subscription.id,
    stripe_customer_id:
      typeof subscription.customer === "string"
        ? subscription.customer
        : subscription.customer && subscription.customer.id,
    max_staff_seats: limits.max_staff_seats,
    max_orders_per_month: limits.max_orders_per_month,
    current_period_end: subscription.current_period_end
      ? admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000)
      : null,
  };
  if (subscription.trial_end) {
    patch.trial_ends_at = admin.firestore.Timestamp.fromMillis(
      subscription.trial_end * 1000,
    );
  }
  await db.collection("Companies").doc(companyId).set(patch, { merge: true });
}

async function handleStripeWebhookEvent(db, event) {
  const stripe = getStripe();
  if (!stripe) {
    throw new Error("Stripe is not configured");
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object;
      if (session.mode !== "subscription" || !session.subscription) {
        return;
      }
      const subscription = await stripe.subscriptions.retrieve(
        session.subscription,
      );
      await syncSubscriptionToCompany(db, subscription);
      return;
    }
    case "customer.subscription.created":
    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const subscription = event.data.object;
      if (event.type === "customer.subscription.deleted") {
        const companyId =
          subscription.metadata && subscription.metadata.companyId;
        if (companyId) {
          await db.collection("Companies").doc(companyId).set(
            {
              subscription_status: "cancelled",
              stripe_subscription_id: null,
            },
            { merge: true },
          );
        }
        return;
      }
      await syncSubscriptionToCompany(db, subscription);
      return;
    }
    case "invoice.payment_failed": {
      const invoice = event.data.object;
      if (!invoice.subscription) {
        return;
      }
      const subscription = await stripe.subscriptions.retrieve(
        invoice.subscription,
      );
      await syncSubscriptionToCompany(db, subscription);
      return;
    }
    default:
      return;
  }
}

async function createCheckoutSessionImpl(db, data, context) {
  const stripe = getStripe();
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
  const planTier = trimmed(data && data.planTier).toLowerCase() || "starter";
  if (planTier !== "starter" && planTier !== "pro") {
    throw httpsError("invalid-argument", "planTier must be starter or pro.");
  }
  const interval =
    trimmed(data && data.interval).toLowerCase() === "year" ? "year" : "month";
  const priceId = priceIdForPlan(planTier, interval);
  if (!priceId) {
    throw httpsError(
      "failed-precondition",
      `Stripe price is not configured for ${planTier} (${interval}).`,
    );
  }

  const caller = await assertCallerCanManageBilling(db, context, companyId);
  const companySnap = await db.collection("Companies").doc(companyId).get();
  if (!companySnap.exists) {
    throw httpsError("not-found", "Company not found.");
  }
  const companyData = companySnap.data() || {};

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
      metadata: { companyId, planTier },
    },
    metadata: { companyId, planTier },
    allow_promotion_codes: true,
  });

  return { url: session.url, sessionId: session.id };
}

async function createPortalSessionImpl(db, data, context) {
  const stripe = getStripe();
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
  mapStripeSubscriptionStatus,
  isSubscriptionWriteAllowed,
  createCheckoutSessionImpl,
  createPortalSessionImpl,
  handleStripeWebhookEvent,
  maybeCreateStripeCustomerForCompany,
};
