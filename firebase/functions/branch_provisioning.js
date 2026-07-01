/**
 * Business plan: create a branch company under an HQ tenant.
 */
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const { appendTenantInitBatch } = require("./tenant_init");

const SUPERADMIN_ROLE = "superadmin";
const DIRECTOR_ROLE = "director";
const ADMIN_ROLE = "admin";
const BUSINESS_PLAN = "business";

function httpsError(code, message) {
  return new functions.https.HttpsError(code, message);
}

function trimmed(value) {
  return (value == null ? "" : String(value)).trim();
}

function normalizePlanTier(raw) {
  return trimmed(raw).toLowerCase();
}

function isBusinessPlanCompany(data) {
  return normalizePlanTier(data?.plan_tier) === BUSINESS_PLAN;
}

function companyKind(data) {
  const kind = trimmed(data?.company_kind).toLowerCase();
  if (kind === "branch" || kind === "hq") {
    return kind;
  }
  return "hq";
}

function hqOrgId(data, docId) {
  const orgId = trimmed(data?.org_id);
  if (orgId) {
    return orgId;
  }
  if (companyKind(data) === "branch") {
    return trimmed(data?.parent_org_ref?.id);
  }
  return docId;
}

async function loadCallerProfile(db, uid) {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw httpsError("permission-denied", "User profile not found.");
  }
  return snap.data();
}

async function assertCanCreateBranch(db, context, headquartersCompanyId) {
  if (!context.auth?.uid) {
    throw httpsError("unauthenticated", "Sign in to create a branch.");
  }
  const uid = context.auth.uid;
  const profile = await loadCallerProfile(db, uid);
  const role = trimmed(profile.role).toLowerCase();

  if (role === SUPERADMIN_ROLE) {
    const hqRef = db.collection("Companies").doc(headquartersCompanyId);
    const hqSnap = await hqRef.get();
    if (!hqSnap.exists) {
      throw httpsError("not-found", "Headquarters company not found.");
    }
    return {
      mode: "superadmin",
      uid,
      profile,
      hqRef,
      hqData: hqSnap.data(),
    };
  }

  if (role !== DIRECTOR_ROLE && role !== ADMIN_ROLE) {
    throw httpsError(
      "permission-denied",
      "Only the business owner or platform admin can add branches.",
    );
  }

  const callerCompanyRef = profile.companyRef;
  if (!callerCompanyRef) {
    throw httpsError("failed-precondition", "Your profile has no company.");
  }

  const hqRef = db.collection("Companies").doc(headquartersCompanyId);
  const hqSnap = await hqRef.get();
  if (!hqSnap.exists) {
    throw httpsError("not-found", "Headquarters company not found.");
  }
  const hqData = hqSnap.data();

  const callerCompanySnap = await callerCompanyRef.get();
  const callerCompanyId = callerCompanyRef.id;
  const callerOrgId = callerCompanySnap.exists
    ? hqOrgId(callerCompanySnap.data(), callerCompanyId)
    : callerCompanyId;

  const targetOrgId = hqOrgId(hqData, headquartersCompanyId);
  if (callerOrgId !== targetOrgId && callerCompanyId !== headquartersCompanyId) {
    throw httpsError(
      "permission-denied",
      "You can only add branches for your organization.",
    );
  }

  if (!isBusinessPlanCompany(hqData)) {
    throw httpsError(
      "failed-precondition",
      "Multi-branch requires the Business plan. Upgrade billing first.",
    );
  }

  return { mode: "owner", uid, profile, hqRef, hqData };
}

async function ensureHeadquartersOrgMetadata(db, hqRef, hqData) {
  const updates = {};
  const hqId = hqRef.id;
  if (!trimmed(hqData.org_id)) {
    updates.org_id = hqId;
  }
  const kind = companyKind(hqData);
  if (kind === "branch") {
    throw httpsError(
      "failed-precondition",
      "Cannot add branches under another branch. Select headquarters.",
    );
  }
  if (!trimmed(hqData.company_kind)) {
    updates.company_kind = "hq";
  }
  if (Object.keys(updates).length > 0) {
    await hqRef.set(updates, { merge: true });
    Object.assign(hqData, updates);
  }
  return hqData;
}

async function createBranchImpl(db, context, data) {
  const headquartersCompanyId = trimmed(data?.headquartersCompanyId);
  if (!headquartersCompanyId) {
    throw httpsError("invalid-argument", "headquartersCompanyId is required.");
  }

  const branchName = trimmed(data?.branchName);
  if (!branchName) {
    throw httpsError("invalid-argument", "branchName is required.");
  }

  const auth = await assertCanCreateBranch(db, context, headquartersCompanyId);
  const hqRef =
    auth.hqRef || db.collection("Companies").doc(headquartersCompanyId);
  let hqData = auth.hqData;
  if (!hqData) {
    hqData = (await hqRef.get()).data();
  }
  await ensureHeadquartersOrgMetadata(db, hqRef, hqData);

  const orgId = hqOrgId(hqData, headquartersCompanyId);
  const branchRef = db.collection("Companies").doc();
  const branchId = branchRef.id;
  const serverTime = admin.firestore.FieldValue.serverTimestamp();

  const batch = db.batch();
  batch.set(branchRef, {
    Company_id: branchId,
    Company_name: branchName,
    Company_phone: trimmed(data?.branchPhone),
    company_address: trimmed(data?.branchAddress),
    company_uen: trimmed(data?.branchUen) || trimmed(hqData.company_uen),
    is_active: true,
    created_at: serverTime,
    company_kind: "branch",
    org_id: orgId,
    parent_org_ref: hqRef,
    branch_code: trimmed(data?.branchCode),
    plan_tier: BUSINESS_PLAN,
  });
  appendTenantInitBatch(batch, db, branchRef, branchId, serverTime);
  await batch.commit();

  return {
    success: true,
    branchId,
    branchPath: branchRef.path,
    orgId,
    headquartersCompanyId,
  };
}

module.exports = {
  createBranchImpl,
  assertCanCreateBranch,
  isBusinessPlanCompany,
  BUSINESS_PLAN,
};
