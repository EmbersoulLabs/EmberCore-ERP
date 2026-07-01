/**
 * Server-side tenant provisioning for approved registration requests.
 *
 * Replaces the legacy client-side approval flow (which created the director
 * Auth user from the superadmin's session and signed the superadmin out).
 * Running on the Admin SDK lets us:
 *   - create the director Auth user without touching the caller's session,
 *   - write all tenant docs atomically (single batch),
 *   - keep `user_registration_requests/{id}` `pending` if anything fails,
 *   - stamp `reviewed_by_uid` / `provisioned_*` for audit.
 */
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const {
  defaultSubscriptionFields,
  maybeCreateStripeCustomerForCompany,
} = require("./stripe_billing");

const REGISTRATION_COLLECTION = "user_registration_requests";
const SUPERADMIN_ROLE = "superadmin";
const DIRECTOR_ROLE = "director";
const DEFAULT_STAFF_ROLES = ["admin", "senior_florist", "florist", "driver"];
const DEFAULT_CATEGORIES = ["AdHoc"];

// New SaaS tenants start on the neutral generic preset (matches the Flutter
// `TenantPlatformConfig.genericDefaults()` and the bootstrap function).
const GENERIC_PLATFORM_CONFIG = {
  industry_key: "generic",
  enabled_modules: [
    "orders",
    "pos",
    "fieldService",
    "drivers",
    "customers",
    "invoices",
    "products",
    "reports",
    "customerBroadcast",
    "whatsappImport",
  ],
  order_types: ["OnSite", "WalkIn", "Remote"],
  order_id_prefix: "EC",
  field_labels_en: {
    recipient_name: "Contact name",
    recipient_phone: "Contact phone",
    service_notes: "Service notes",
    scheduled_date: "Scheduled date",
    time_window: "Time window",
    service_address: "Service address",
    customer_id: "Customer ID",
  },
  field_labels_zh: {
    recipient_name: "联系人",
    recipient_phone: "联系电话",
    service_notes: "服务备注",
    scheduled_date: "预约日期",
    time_window: "时间段",
    service_address: "服务地址",
    customer_id: "客户编号",
  },
  status_labels_en: {
    pending: "Pending",
    processing: "Processing",
    ready: "Ready",
    out_for_delivery: "Out for delivery",
    completed: "Completed",
    cancelled: "Cancelled",
  },
  driver_role_label_en: "Field staff",
  driver_role_label_zh: "外勤人员",
};

function httpsError(code, message) {
  return new functions.https.HttpsError(code, message);
}

/** Resolves the caller's superadmin uid or throws an HttpsError. */
async function assertCallerIsSuperadmin(db, context) {
  if (!context.auth || !context.auth.uid) {
    throw httpsError("unauthenticated", "Sign in to approve registrations.");
  }
  const uid = context.auth.uid;
  const tokenRole =
    context.auth.token && typeof context.auth.token.role === "string"
      ? context.auth.token.role
      : null;
  if (tokenRole === SUPERADMIN_ROLE) {
    return uid;
  }
  // Custom claims can lag a profile change — fall back to the Firestore role.
  const snap = await db.collection("users").doc(uid).get();
  const role = snap.exists ? snap.data().role : null;
  if (role !== SUPERADMIN_ROLE) {
    throw httpsError(
      "permission-denied",
      "Only super admins can approve registration requests.",
    );
  }
  return uid;
}

function trimmed(value) {
  return typeof value === "string" ? value.trim() : "";
}

/** Best-effort cleanup so a failed approval leaves no orphan tenant docs. */
async function rollbackProvisioning(db, created) {
  if (created.companyId) {
    const id = created.companyId;
    const refs = [
      db.collection("Companies").doc(id),
      db.collection("tenant_platform_config").doc(id),
      db.collection("staff_roles").doc(id),
      db.collection("role_permissions").doc(id),
      db.collection("product_categories").doc(id),
      db.collection("counter").doc(`${id}_delivery`),
      db.collection("counter").doc(`${id}_retail`),
      db.collection("counter").doc(`${id}_invoice`),
      db.collection("counter").doc(`${id}_customer`),
    ];
    for (const ref of refs) {
      try {
        await ref.delete();
      } catch (_) {
        // ignore — best effort
      }
    }
  }
  if (created.authUserCreated && created.authUid) {
    try {
      await admin.auth().deleteUser(created.authUid);
    } catch (_) {
      // ignore — best effort
    }
  }
}

/**
 * Approves a pending registration request and provisions a tenant.
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} data { requestId, initialPassword? }
 * @param {string} reviewerUid superadmin uid
 */
async function approveRegistrationRequestImpl(db, data, reviewerUid) {
  const requestId = trimmed(data && data.requestId);
  if (!requestId) {
    throw httpsError("invalid-argument", "requestId is required.");
  }
  const initialPassword =
    data && data.initialPassword ? String(data.initialPassword) : "";
  if (initialPassword && initialPassword.length < 6) {
    throw httpsError(
      "invalid-argument",
      "Initial password must be at least 6 characters.",
    );
  }

  const reqRef = db.collection(REGISTRATION_COLLECTION).doc(requestId);
  const reqSnap = await reqRef.get();
  if (!reqSnap.exists) {
    throw httpsError("not-found", "Registration request not found.");
  }
  const req = reqSnap.data() || {};
  if (req.status !== "pending") {
    throw httpsError(
      "failed-precondition",
      "This request is no longer pending.",
    );
  }

  const email = trimmed(req.email).toLowerCase();
  if (!email) {
    throw httpsError("failed-precondition", "Request has no email.");
  }
  const name = trimmed(req.name);
  const phone = trimmed(req.phone);
  const isCompany = req.account_type === "company";
  const companyName = isCompany ? trimmed(req.company_name) : name;
  if (!companyName) {
    throw httpsError(
      "failed-precondition",
      isCompany
        ? "Company name is missing on this request."
        : "Name is missing on this request.",
    );
  }

  const created = { companyId: null, authUserCreated: false, authUid: null };
  try {
    const companyRef = db.collection("Companies").doc();
    const companyId = companyRef.id;
    created.companyId = companyId;
    const serverTime = admin.firestore.FieldValue.serverTimestamp();

    // 1. Atomic tenant document creation.
    const batch = db.batch();
    const companyData = {
      Company_id: companyId,
      Company_name: companyName,
      Company_phone: isCompany ? trimmed(req.company_phone) || phone : phone,
      company_address: trimmed(req.company_address),
      company_uen: trimmed(req.company_uen),
      is_active: true,
      created_at: serverTime,
      ...defaultSubscriptionFields("starter"),
    };
    const logoUrl = trimmed(req.company_logo_url);
    if (logoUrl) {
      companyData.logo = logoUrl;
    }
    batch.set(companyRef, companyData);
    batch.set(db.collection("tenant_platform_config").doc(companyId), {
      ...GENERIC_PLATFORM_CONFIG,
      updated_at: new Date().toISOString(),
    });
    batch.set(db.collection("staff_roles").doc(companyId), {
      companyRef,
      roles: DEFAULT_STAFF_ROLES,
      updated_time: serverTime,
    });
    batch.set(db.collection("role_permissions").doc(companyId), {
      companyRef,
      roles: {},
      updated_time: serverTime,
    });
    batch.set(db.collection("product_categories").doc(companyId), {
      companyRef,
      categories: DEFAULT_CATEGORIES,
      updated_time: serverTime,
    });
    for (const suffix of ["delivery", "retail", "invoice", "customer"]) {
      batch.set(db.collection("counter").doc(`${companyId}_${suffix}`), {
        current: 0,
        comR: companyRef,
      });
    }
    await batch.commit();

    await maybeCreateStripeCustomerForCompany(
      db,
      companyId,
      companyName,
      email,
    );

    // 2. Director Auth user (reuse if the email already exists).
    let authUid;
    let passwordSet = false;
    try {
      const existing = await admin.auth().getUserByEmail(email);
      authUid = existing.uid;
      if (initialPassword) {
        await admin.auth().updateUser(authUid, {
          password: initialPassword,
          displayName: name || existing.displayName || undefined,
          disabled: false,
        });
        passwordSet = true;
      }
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
      const createParams = { email, disabled: false };
      if (name) {
        createParams.displayName = name;
      }
      if (initialPassword) {
        createParams.password = initialPassword;
      }
      const userRecord = await admin.auth().createUser(createParams);
      authUid = userRecord.uid;
      created.authUserCreated = true;
      created.authUid = authUid;
      passwordSet = Boolean(initialPassword);
    }

    // Passwordless onboarding: hand back a reset link the director can use.
    let passwordResetLink = null;
    if (!passwordSet) {
      try {
        passwordResetLink = await admin.auth().generatePasswordResetLink(email);
      } catch (_) {
        passwordResetLink = null;
      }
    }

    // 3. Director profile + immediate custom claims.
    const userRef = db.collection("users").doc(authUid);
    await userRef.set(
      {
        uid: authUid,
        email,
        name,
        display_name: name,
        role: DIRECTOR_ROLE,
        is_active: true,
        companyRef,
        phone_number: phone,
        created_time: serverTime,
      },
      { merge: true },
    );
    try {
      await admin.auth().setCustomUserClaims(authUid, {
        role: DIRECTOR_ROLE,
        companyId,
      });
    } catch (_) {
      // The users/{uid} onWrite trigger will reconcile claims shortly.
    }

    // 4. Mark request approved LAST so earlier failures keep it pending.
    await reqRef.update({
      status: "approved",
      reviewed_at: serverTime,
      reviewed_by_uid: reviewerUid,
      provisioned_company_ref: companyRef,
      provisioned_user_uid: authUid,
      initial_password_set: passwordSet,
    });

    return {
      ok: true,
      companyId,
      companyPath: companyRef.path,
      userUid: authUid,
      passwordSet,
      passwordResetLink,
    };
  } catch (error) {
    await rollbackProvisioning(db, created);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    functions.logger.error("approveRegistrationRequest provisioning failed", {
      requestId,
      message: error && error.message,
      code: error && error.code,
    });
    throw httpsError(
      "internal",
      (error && error.message) || "Tenant provisioning failed.",
    );
  }
}

module.exports = {
  assertCallerIsSuperadmin,
  approveRegistrationRequestImpl,
  GENERIC_PLATFORM_CONFIG,
};
