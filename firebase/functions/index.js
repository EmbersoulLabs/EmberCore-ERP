const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { verifyShopifyWebhookHmac } = require("./shopify/verify_hmac");
const { importShopifyOrder } = require("./shopify/import_service");
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
 * Shopify orders/create webhook → ERP order + staff notice + audit log.
 */
exports.shopifyOrderCreated = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).json({ error: "Method not allowed" });
    }

    const { secret, companyId } = readConfig();
    if (!secret) {
      functions.logger.error("SHOPIFY_WEBHOOK_SECRET is not configured");
      return res.status(500).json({ error: "Webhook secret not configured" });
    }
    if (!companyId) {
      functions.logger.error("SHOPIFY_DEFAULT_COMPANY_ID is not configured");
      return res.status(500).json({ error: "Company id not configured" });
    }

    const hmacHeader = req.get("x-shopify-hmac-sha256");
    const rawBody = rawBodyBuffer(req);
    if (!verifyShopifyWebhookHmac(rawBody, hmacHeader, secret)) {
      functions.logger.warn("Shopify HMAC verification failed");
      return res.status(401).json({ error: "Invalid webhook signature" });
    }

    let shopifyOrder;
    try {
      shopifyOrder = JSON.parse(rawBody.toString("utf8"));
    } catch (error) {
      functions.logger.error("Invalid JSON body", error);
      return res.status(400).json({ error: "Invalid JSON body" });
    }

    if (!shopifyOrder?.id) {
      return res.status(400).json({ error: "Missing Shopify order id" });
    }

    try {
      const result = await importShopifyOrder(db, shopifyOrder, companyId);
      functions.logger.info("Shopify order processed", {
        duplicate: result.duplicate,
        externalOrderId: result.externalOrderId,
        orderPath: result.orderRef.path,
      });
      return res.status(200).json({
        ok: true,
        duplicate: result.duplicate,
        orderId: result.orderId,
        externalOrderId: result.externalOrderId,
        externalOrderName: result.externalOrderName,
        orderPath: result.orderRef.path,
        noticesCreated: result.noticesCreated ?? 0,
      });
    } catch (error) {
      functions.logger.error("Shopify import failed", error);
      return res.status(500).json({ error: "Import failed" });
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
