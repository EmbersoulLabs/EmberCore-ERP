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
  trialContractForCountry,
  normalizeCountry,
} = require("./saas_pricing_v1");

const REGISTRATION_COLLECTION = "user_registration_requests";
const AUDIT_COLLECTION = "audit_logs";
const SUPERADMIN_ROLE = "superadmin";
const PROVISIONING_LEASE_MS = 2 * 60 * 1000;
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
      db.collection("trial_quota").doc(id),
      db
        .collection("trial_staff_slots")
        .doc(id)
        .collection("slots")
        .doc("1"),
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
      const auth = created.auth || admin.auth();
      await auth.deleteUser(created.authUid);
    } catch (_) {
      // ignore — best effort
    }
  }
}

function timestampMillis(value) {
  if (!value) {
    return 0;
  }
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (typeof value === "number") {
    return value;
  }
  return 0;
}

function serverTimestamp() {
  return admin.firestore.FieldValue.serverTimestamp();
}

async function writeAudit(db, entry) {
  await db.collection(AUDIT_COLLECTION).add({
    ...entry,
    created_at: serverTimestamp(),
  });
}

/**
 * Claims a pending request so two approvals cannot provision two tenants.
 * A completed approval returns the existing tenant. A fresh in-progress claim
 * is rejected. A stale claim can be recovered with the same company id.
 */
async function claimRegistration(db, requestId, reviewerUid, nowMs) {
  const reqRef = db.collection(REGISTRATION_COLLECTION).doc(requestId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(reqRef);
    if (!snap.exists) {
      throw httpsError("not-found", "Registration request not found.");
    }
    const req = snap.data() || {};
    if (req.status === "approved" && trimmed(req.provisioned_company_id)) {
      return {
        action: "reuse",
        req,
        companyId: trimmed(req.provisioned_company_id),
        authUid: trimmed(req.provisioned_user_uid),
      };
    }
    if (req.status === "rejected") {
      throw httpsError("failed-precondition", "This request was rejected.");
    }
    if (req.status === "provisioning") {
      const stale =
        nowMs - timestampMillis(req.provisioning_started_at) >
        PROVISIONING_LEASE_MS;
      if (!stale) {
        throw httpsError("aborted", "Approval is already in progress.");
      }
    } else if (req.status !== "pending") {
      throw httpsError(
        "failed-precondition",
        "This request is no longer pending.",
      );
    }

    const country = normalizeCountry(req.country);
    if (!trialContractForCountry(country)) {
      throw httpsError(
        "failed-precondition",
        "Registration country must be Malaysia (MY) or Singapore (SG).",
      );
    }
    const companyId =
      trimmed(req.provisioned_company_id) || db.collection("Companies").doc().id;
    await tx.update(reqRef, {
      status: "provisioning",
      provisioning_started_at: serverTimestamp(),
      reviewed_by_uid: reviewerUid,
      provisioned_company_id: companyId,
      country,
    });
    return { action: "provision", req: { ...req, country }, companyId };
  });
}

async function releaseClaim(db, requestId) {
  await db.collection(REGISTRATION_COLLECTION).doc(requestId).update({
    status: "pending",
    provisioning_started_at: admin.firestore.FieldValue.delete(),
  });
}

/**
 * Approves a pending registration request and provisions a tenant.
 * Repeated calls return the tenant already created for this request.
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} data { requestId, initialPassword? }
 * @param {string} reviewerUid superadmin uid
 * @param {object} [options] test seams: auth, nowMs
 */
async function approveRegistrationRequestImpl(db, data, reviewerUid, options) {
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

  const opts = options || {};
  const auth = opts.auth || admin.auth();
  const nowMs = typeof opts.nowMs === "number" ? opts.nowMs : Date.now();
  const claim = await claimRegistration(db, requestId, reviewerUid, nowMs);
  if (claim.action === "reuse") {
    return {
      ok: true,
      reused: true,
      companyId: claim.companyId,
      companyPath: `Companies/${claim.companyId}`,
      userUid: claim.authUid,
      passwordSet: false,
      passwordResetLink: null,
    };
  }

  const reqRef = db.collection(REGISTRATION_COLLECTION).doc(requestId);
  const req = claim.req;
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

  const created = {
    companyId: claim.companyId,
    authUserCreated: false,
    authUid: null,
    auth,
  };
  try {
    const companyRef = db.collection("Companies").doc(claim.companyId);
    const companyId = claim.companyId;
    const serverTime = serverTimestamp();
    const trial = trialContractForCountry(req.country);

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
      ...trial,
      trial_ends_at: admin.firestore.Timestamp.fromDate(
        new Date(nowMs + trial.trial_days * 24 * 60 * 60 * 1000),
      ),
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
    batch.set(db.collection("trial_quota").doc(companyId), {
      orders_consumed: 0,
      staff_consumed: 1,
    });
    await batch.commit();

    // 2. Director Auth user (reuse if the email already exists).
    // Trial does not create a payment-provider customer.
    let authUid;
    let passwordSet = false;
    try {
      const existing = await auth.getUserByEmail(email);
      authUid = existing.uid;
      if (initialPassword) {
        await auth.updateUser(authUid, {
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
      const userRecord = await auth.createUser(createParams);
      authUid = userRecord.uid;
      created.authUserCreated = true;
      created.authUid = authUid;
      passwordSet = Boolean(initialPassword);
    }

    // Passwordless onboarding: hand back a reset link the director can use.
    let passwordResetLink = null;
    if (!passwordSet) {
      try {
        passwordResetLink = await auth.generatePasswordResetLink(email);
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
        activation_status: "pending_first_login",
        companyRef,
        phone_number: phone,
        created_time: serverTime,
        trial_slot: "1",
        trial_enforced: true,
      },
      { merge: true },
    );
    await db
      .collection("trial_staff_slots")
      .doc(companyId)
      .collection("slots")
      .doc("1")
      .set({ user_id: authUid });
    try {
      await auth.setCustomUserClaims(authUid, {
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
    await writeAudit(db, {
      action: "registration.approved",
      actor_uid: reviewerUid,
      request_id: requestId,
      companyRef,
      target_uid: authUid,
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
    try {
      await releaseClaim(db, requestId);
    } catch (_) {
      // The request stays claimable once the lease expires.
    }
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

async function rejectRegistrationRequestImpl(db, data, reviewerUid, options) {
  const requestId = trimmed(data && data.requestId);
  const note = trimmed(data && (data.note || data.rejectionNote));
  if (!requestId) {
    throw httpsError("invalid-argument", "requestId is required.");
  }
  if (!note) {
    throw httpsError("invalid-argument", "A rejection note is required.");
  }
  const nowMs =
    options && typeof options.nowMs === "number" ? options.nowMs : Date.now();
  const reqRef = db.collection(REGISTRATION_COLLECTION).doc(requestId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(reqRef);
    if (!snap.exists) {
      throw httpsError("not-found", "Registration request not found.");
    }
    const req = snap.data() || {};
    if (req.status === "approved") {
      throw httpsError("failed-precondition", "This request is already approved.");
    }
    if (req.status === "rejected") {
      return;
    }
    if (req.status === "provisioning") {
      const stale =
        nowMs - timestampMillis(req.provisioning_started_at) >
        PROVISIONING_LEASE_MS;
      if (!stale) {
        throw httpsError("aborted", "Approval is already in progress.");
      }
    } else if (req.status !== "pending") {
      throw httpsError(
        "failed-precondition",
        "This request is no longer pending.",
      );
    }
    await tx.update(reqRef, {
      status: "rejected",
      rejection_note: note,
      reviewed_at: serverTimestamp(),
      reviewed_by_uid: reviewerUid,
    });
  });
  await writeAudit(db, {
    action: "registration.rejected",
    actor_uid: reviewerUid,
    request_id: requestId,
  });
  return { ok: true };
}

/** Marks a provisioned director active on their first successful sign-in. */
async function recordDirectorFirstLoginImpl(db, uid) {
  if (!uid) {
    throw httpsError("unauthenticated", "Sign in required.");
  }
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    return { ok: true, recorded: false };
  }
  const data = snap.data() || {};
  if (data.activation_status !== "pending_first_login") {
    return { ok: true, recorded: false };
  }
  await ref.update({
    activation_status: "active",
    first_login_at: serverTimestamp(),
  });
  await writeAudit(db, {
    action: "director.first_login",
    actor_uid: uid,
    target_uid: uid,
    companyRef: data.companyRef || null,
  });
  return { ok: true, recorded: true };
}

module.exports = {
  assertCallerIsSuperadmin,
  approveRegistrationRequestImpl,
  rejectRegistrationRequestImpl,
  recordDirectorFirstLoginImpl,
  GENERIC_PLATFORM_CONFIG,
};
