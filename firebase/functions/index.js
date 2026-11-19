const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { handleShopifyPaidWebhook } = require("./shopify/webhook_handler");
const {
  loadStaffProfile,
  staffCanCreateOrders,
  staffCanEditCompanyProfile,
  resolveStaffCompanyId,
} = require("./shopify/staff_auth");
const {
  StorefrontSyncError,
  parseStorefrontWebsite,
  syncStorefrontCatalog,
} = require("./shopify/sync_storefront_catalog");
const { approveShopifyReviews } = require("./shopify/approve_reviews");
const { deleteShopifyReviews } = require("./shopify/delete_reviews");
const { TrialLimitError } = require("./trial_quota");
const { PlanModuleError } = require("./plan_entitlements");
const { PlanQuotaError } = require("./monthly_usage");
const { sendStaffNoticePush } = require("./staff_notice_push");
const {
  syncStaffAuthClaims,
  driverUidFromAssignedRef,
} = require("./staff_auth_claims");
const {
  BUSINESS_TIMEZONE,
  sendTomorrowPrepReminders,
  sendTodayOpsReminders,
} = require("./operation_reminders");
const {
  bootstrapEmbercorePlatform,
  readBootstrapConfig,
} = require("./bootstrap_platform");
const { parseOrderMessageWithGemini } = require("./order_import_parser");
const {
  assertCallerIsSuperadmin,
  approveRegistrationRequestImpl,
  rejectRegistrationRequestImpl,
  recordDirectorFirstLoginImpl,
} = require("./registration_provisioning");
const { createBranchImpl } = require("./branch_provisioning");
const {
  createCheckoutSessionImpl,
  createPortalSessionImpl,
  handleStripeWebhookEvent,
  readStripeConfig,
  getStripe,
} = require("./stripe_billing");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FUNCTION_REGION = "asia-southeast1";

function readConfig() {
  const secret =
    process.env.SHOPIFY_WEBHOOK_SECRET ||
    functions.config().shopify?.webhook_secret ||
    "";
  const companyId =
    process.env.SHOPIFY_DEFAULT_COMPANY_ID ||
    functions.config().shopify?.default_company_id ||
    "";
  return { secret, companyId };
}

function rawBodyBuffer(req) {
  if (Buffer.isBuffer(req.rawBody)) {
    return req.rawBody;
  }
  if (typeof req.rawBody === "string") {
    return Buffer.from(req.rawBody, "utf8");
  }
  if (req.body == null) {
    return Buffer.alloc(0);
  }
  return Buffer.from(
    typeof req.body === "string" ? req.body : JSON.stringify(req.body),
    "utf8",
  );
}

/**
 * POST /shopifyOrderCreated
 * Legacy stable public URL. Production Shopify topic: orders/paid.
 * HMAC-verified payload is staged in shopify_reviews (not orders).
 */
exports.shopifyOrderCreated = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    const { secret, companyId } = readConfig();
    return handleShopifyPaidWebhook(req, res, { secret, companyId, db });
  });

/**
 * Authenticated staff approval gate: pending Shopify review → official order.
 */
exports.approveShopifyReviews = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required",
      );
    }

    const reviewIds = Array.isArray(data?.reviewIds) ? data.reviewIds : [];
    if (reviewIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "reviewIds is required",
      );
    }

    const profile = await loadStaffProfile(db, context.auth.uid);
    if (!profile) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Staff profile not found",
      );
    }
    const allowed = await staffCanCreateOrders(db, profile);
    if (!allowed) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Missing permission to approve Shopify reviews",
      );
    }

    const staff = {
      uid: context.auth.uid,
      email: context.auth.token?.email || profile.data.email || "",
      name: profile.data.name || "",
      role: profile.data.role || "",
      profile: profile.data,
    };

    try {
      const result = await approveShopifyReviews(db, reviewIds, staff);
      functions.logger.info("Shopify reviews approval finished", {
        uid: staff.uid,
        approved: result.approved.length,
        alreadyApproved: result.alreadyApproved.length,
        failed: result.failed.length,
      });
      return result;
    } catch (error) {
      if (
        error instanceof TrialLimitError ||
        error instanceof PlanModuleError ||
        error instanceof PlanQuotaError ||
        error.code === "trial-limit" ||
        error.code === "plan-module" ||
        error.code === "plan-quota" ||
        error.code === "subscription-inactive"
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          error.message || "Plan or trial limit",
        );
      }
      throw error;
    }
  });

/**
 * Authenticated staff gate: remove staged Shopify reviews.
 * Does not delete official Order List rows.
 */
exports.deleteShopifyReviews = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required",
      );
    }

    const reviewIds = Array.isArray(data?.reviewIds) ? data.reviewIds : [];
    if (reviewIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "reviewIds is required",
      );
    }

    const profile = await loadStaffProfile(db, context.auth.uid);
    if (!profile) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Staff profile not found",
      );
    }
    const allowed = await staffCanCreateOrders(db, profile);
    if (!allowed) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Missing permission to delete Shopify reviews",
      );
    }

    const staff = {
      uid: context.auth.uid,
      email: context.auth.token?.email || profile.data.email || "",
      name: profile.data.name || "",
      role: profile.data.role || "",
      profile: profile.data,
    };

    const result = await deleteShopifyReviews(db, reviewIds, staff);
    functions.logger.info("Shopify reviews delete finished", {
      uid: staff.uid,
      deleted: result.deleted.length,
      failed: result.failed.length,
    });
    return result;
  });

/**
 * Authenticated catalog sync from the company Website (Shopify products.json).
 */
exports.syncStorefrontCatalog = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "512MB",
  })
  .https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required",
      );
    }

    const profile = await loadStaffProfile(db, context.auth.uid);
    if (!profile) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Staff profile not found",
      );
    }
    const allowed = await staffCanEditCompanyProfile(db, profile);
    if (!allowed) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Missing permission to update company catalog",
      );
    }

    let companyId;
    try {
      companyId = resolveStaffCompanyId(profile, data?.companyId);
    } catch (err) {
      throw new functions.https.HttpsError(
        err.code || "permission-denied",
        err.message || "Company belongs to another tenant",
      );
    }
    if (!companyId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No company linked to your account",
      );
    }

    const companySnap = await db.collection("Companies").doc(companyId).get();
    if (!companySnap.exists) {
      throw new functions.https.HttpsError("not-found", "Company not found");
    }
    const website =
      String(data?.website || "").trim() ||
      String(companySnap.data()?.website || "").trim();
    const parsed = parseStorefrontWebsite(website);
    if (!parsed) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Enter a valid website, e.g. https://shop.example.com",
      );
    }

    try {
      const result = await syncStorefrontCatalog(db, {
        companyId,
        website: parsed.website,
        deactivateExtra: true,
      });
      functions.logger.info("Storefront catalog sync finished", {
        uid: context.auth.uid,
        companyId,
        created: result.createdCount,
        priceUpdates: result.priceUpdateCount,
        deactivated: result.deactivatedCount,
      });
      return result;
    } catch (err) {
      if (err instanceof StorefrontSyncError) {
        throw new functions.https.HttpsError(err.code, err.message);
      }
      functions.logger.error("Storefront catalog sync failed", err);
      throw new functions.https.HttpsError(
        "internal",
        err.message || "Catalog sync failed",
      );
    }
  });

/**
 * staff_notices onCreate → FCM push to recipient devices (background / killed app).
 */
exports.onStaffNoticeCreated = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .firestore.document("staff_notices/{noticeId}")
  .onCreate(async (snap, context) => {
    const notice = snap.data();
    if (!notice?.recipient_user_ref) {
      functions.logger.warn("staff notice missing recipient", {
        noticeId: context.params.noticeId,
      });
      return null;
    }

    try {
      const result = await sendStaffNoticePush(
        db,
        notice,
        context.params.noticeId,
      );
      functions.logger.info("staff notice push sent", {
        noticeId: context.params.noticeId,
        ...result,
      });
      return result;
    } catch (error) {
      functions.logger.error("staff notice push failed", {
        noticeId: context.params.noticeId,
        error,
      });
      return null;
    }
  });

/**
 * Keep driver assignedOrderIds custom claims in sync for Storage delivery proof uploads.
 */
exports.onOrderAssignedDriverChanged = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .firestore.document("orders/{orderId}")
  .onWrite(async (change, context) => {
    const beforeDriver = driverUidFromAssignedRef(
      change.before.exists ? change.before.data()?.assigned_driver : null,
    );
    const afterDriver = driverUidFromAssignedRef(
      change.after.exists ? change.after.data()?.assigned_driver : null,
    );

    const uids = new Set([beforeDriver, afterDriver].filter(Boolean));
    if (uids.size === 0) {
      return null;
    }

    const results = [];
    for (const uid of uids) {
      try {
        results.push(await syncStaffAuthClaims(db, uid));
      } catch (error) {
        functions.logger.error("driver claims sync failed", {
          orderId: context.params.orderId,
          uid,
          error,
        });
      }
    }

    functions.logger.info("driver claims sync complete", {
      orderId: context.params.orderId,
      results,
    });
    return results;
  });

/**
 * Sync role/company claims when a staff profile is created or updated.
 */
exports.onStaffUserProfileChanged = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .firestore.document("users/{userId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) {
      return null;
    }
    try {
      const result = await syncStaffAuthClaims(db, context.params.userId);
      functions.logger.info("staff claims sync complete", result);
      return result;
    } catch (error) {
      functions.logger.error("staff claims sync failed", {
        userId: context.params.userId,
        error,
      });
      return null;
    }
  });

/**
 * Weekday close (Mon–Fri 19:00 SGT): remind staff about tomorrow's unfinished orders.
 * Friday run covers Sat + Sun + Mon.
 */
exports.scheduledTomorrowPrepReminderWeekday = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .pubsub.schedule("0 19 * * 1-5")
  .timeZone(BUSINESS_TIMEZONE)
  .onRun(async () => {
    const results = await sendTomorrowPrepReminders(db, new Date());
    functions.logger.info("tomorrow prep reminder (weekday)", { results });
    return results;
  });

/**
 * Weekend close (Sat–Sun 16:00 SGT): remind staff about tomorrow's unfinished orders.
 */
exports.scheduledTomorrowPrepReminderWeekend = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .pubsub.schedule("0 16 * * 0,6")
  .timeZone(BUSINESS_TIMEZONE)
  .onRun(async () => {
    const results = await sendTomorrowPrepReminders(db, new Date());
    functions.logger.info("tomorrow prep reminder (weekend)", { results });
    return results;
  });

/**
 * Daily open (09:15 SGT): remind staff about today's unfinished delivery orders.
 */
exports.scheduledTodayOpsReminder = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .pubsub.schedule("15 9 * * *")
  .timeZone(BUSINESS_TIMEZONE)
  .onRun(async () => {
    const results = await sendTodayOpsReminders(db, new Date());
    functions.logger.info("today ops reminder", { results });
    return results;
  });

/**
 * POST /bootstrapEmbercorePlatform
 * One-time HTTPS bootstrap for embercore-erp (superadmin + demo tenant).
 * Header: x-bootstrap-secret must match BOOTSTRAP_SECRET env / functions config.
 */
exports.bootstrapEmbercorePlatform = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).json({ error: "Method not allowed" });
    }

    const cfg = functions.config().bootstrap || {};
    if (!process.env.BOOTSTRAP_SECRET && cfg.secret) {
      process.env.BOOTSTRAP_SECRET = cfg.secret;
    }

    const { secret } = readBootstrapConfig();
    const provided =
      req.get("x-bootstrap-secret") || req.get("X-Bootstrap-Secret") || "";
    if (!secret || provided !== secret) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const body =
      typeof req.body === "object" && req.body != null ? req.body : {};
    if (body.superadminPassword) {
      process.env.BOOTSTRAP_SUPERADMIN_PASSWORD = String(
        body.superadminPassword,
      );
    }
    if (body.directorPassword) {
      process.env.BOOTSTRAP_DIRECTOR_PASSWORD = String(body.directorPassword);
    }
    if (body.superadminEmail) {
      process.env.BOOTSTRAP_SUPERADMIN_EMAIL = String(body.superadminEmail);
    }
    if (body.directorEmail) {
      process.env.BOOTSTRAP_DIRECTOR_EMAIL = String(body.directorEmail);
    }

    try {
      const result = await bootstrapEmbercorePlatform();
      functions.logger.info("embercore platform bootstrap complete", result);
      return res.status(200).json({ ok: true, result });
    } catch (error) {
      functions.logger.error("embercore platform bootstrap failed", { error });
      return res.status(500).json({
        error: error.message || "Bootstrap failed",
      });
    }
  });

/**
 * Callable: parseOrderImport
 * AI-assisted order field extraction (Gemini). Client merges with local regex parser.
 */
exports.parseOrderImport = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
    secrets: ["GEMINI_API_KEY"],
  })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in to use order import.",
      );
    }

    const rawText = String(data?.text || "").trim();
    if (!rawText) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "text is required",
      );
    }
    if (rawText.length > 12000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "text is too long",
      );
    }

    const parseContext = {
      industryKey: data?.industryKey ? String(data.industryKey) : undefined,
      orderIdPrefix: data?.orderIdPrefix
        ? String(data.orderIdPrefix)
        : undefined,
    };

    try {
      const parsed = await parseOrderMessageWithGemini(rawText, parseContext);
      return { parsed, source: "gemini" };
    } catch (error) {
      functions.logger.error("parseOrderImport failed", {
        uid: context.auth.uid,
        error: error.message || error,
      });
      throw new functions.https.HttpsError(
        "internal",
        error.message || "Order import parsing failed",
      );
    }
  });

/**
 * Callable: approveRegistrationRequest
 * Superadmin-only. Provisions a tenant (Companies + config + counters +
 * staff_roles + role_permissions) and the director Auth user server-side, then
 * marks the request approved. Keeps the superadmin's session intact.
 */
exports.approveRegistrationRequest = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    const reviewerUid = await assertCallerIsSuperadmin(db, context);
    const result = await approveRegistrationRequestImpl(db, data, reviewerUid);
    functions.logger.info("registration request approved", {
      reviewerUid,
      companyId: result.companyId,
      userUid: result.userUid,
      passwordSet: result.passwordSet,
    });
    return result;
  });

/**
 * Callable: rejectRegistrationRequest
 * Superadmin-only. Marks a pending application rejected. Does not provision.
 */
exports.rejectRegistrationRequest = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    const reviewerUid = await assertCallerIsSuperadmin(db, context);
    const result = await rejectRegistrationRequestImpl(db, data, reviewerUid);
    functions.logger.info("registration request rejected", {
      reviewerUid,
      requestId: data && data.requestId,
    });
    return result;
  });

/**
 * Callable: recordDirectorFirstLogin
 * The signed-in director stamps first-login activation. Idempotent.
 */
exports.recordDirectorFirstLogin = functions
  .region(FUNCTION_REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required.",
      );
    }
    return recordDirectorFirstLoginImpl(db, context.auth.uid);
  });

/**
 * Callable: createBranch
 * Business plan — add a branch under HQ (superadmin or org director/admin).
 */
exports.createBranch = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    const result = await createBranchImpl(db, context, data);
    functions.logger.info("branch created", {
      branchId: result.branchId,
      orgId: result.orgId,
      headquartersCompanyId: result.headquartersCompanyId,
      callerUid: context.auth?.uid,
    });
    return result;
  });

/**
 * Callable: createCheckoutSession
 * Director/admin starts Stripe Checkout for Starter or Pro.
 */
exports.createCheckoutSession = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    return createCheckoutSessionImpl(db, data, context);
  });

/**
 * Callable: createPortalSession
 * Director/admin opens Stripe Customer Portal (renew, upgrade, cancel).
 */
exports.createPortalSession = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    return createPortalSessionImpl(db, data, context);
  });

/**
 * POST /stripeWebhook
 * Stripe subscription lifecycle → Firestore Companies subscription fields.
 */
exports.stripeWebhook = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).send("Method not allowed");
    }

    const stripe = getStripe();
    const { webhookSecret } = readStripeConfig();
    if (!stripe || !webhookSecret) {
      functions.logger.error("Stripe webhook not configured");
      return res.status(500).send("Stripe not configured");
    }

    const signature = req.headers["stripe-signature"];
    if (!signature) {
      return res.status(400).send("Missing stripe-signature");
    }

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        rawBodyBuffer(req),
        signature,
        webhookSecret,
      );
    } catch (error) {
      functions.logger.warn("Stripe webhook signature failed", {
        message: error.message,
      });
      return res.status(400).send(`Webhook Error: ${error.message}`);
    }

    try {
      await handleStripeWebhookEvent(db, event);
      return res.status(200).json({ received: true });
    } catch (error) {
      functions.logger.error("Stripe webhook handler failed", {
        type: event.type,
        message: error.message,
      });
      return res.status(500).send("Webhook handler failed");
    }
  });
