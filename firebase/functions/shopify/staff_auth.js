const DEFAULT_CREATE_ORDERS_ROLES = new Set([
  "superadmin",
  "admin",
  "director",
  "manager",
  "senior_florist",
  "florist",
]);

function canonicalCompanyDocId(companyId) {
  return companyId;
}

function parseBooleanOverride(value) {
  return typeof value === "boolean" ? value : null;
}

async function loadStaffProfile(db, uid) {
  if (!uid) {
    return null;
  }
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    return null;
  }
  return { id: snap.id, ref: snap.ref, data: snap.data() || {} };
}

const DEFAULT_EDIT_COMPANY_PROFILE_ROLES = new Set([
  "superadmin",
  "admin",
]);

function defaultCanCreateOrders(role) {
  return DEFAULT_CREATE_ORDERS_ROLES.has(role);
}

function defaultCanEditCompanyProfile(role) {
  return DEFAULT_EDIT_COMPANY_PROFILE_ROLES.has(role);
}

async function staffHasPermission(db, profile, permissionKey, defaultFn) {
  const data = profile?.data || {};
  const role = String(data.role || "").trim();
  if (!role) {
    return false;
  }
  if (data.is_active === false) {
    return false;
  }
  if (role === "superadmin") {
    return true;
  }

  const userOverride = parseBooleanOverride(
    data.permission_overrides?.[permissionKey] ??
      data.permissionOverrides?.[permissionKey],
  );
  if (userOverride != null) {
    return userOverride;
  }

  const companyId = canonicalCompanyDocId(data.companyRef?.id || "");
  if (companyId) {
    const rolePermSnap = await db.collection("role_permissions").doc(companyId).get();
    const roleOverride = parseBooleanOverride(
      rolePermSnap.data()?.roles?.[role]?.[permissionKey],
    );
    if (roleOverride != null) {
      return roleOverride;
    }
  }

  return defaultFn(role);
}

async function staffCanCreateOrders(db, profile) {
  return staffHasPermission(db, profile, "createOrders", defaultCanCreateOrders);
}

async function staffCanEditCompanyProfile(db, profile) {
  return staffHasPermission(
    db,
    profile,
    "editCompanyProfile",
    defaultCanEditCompanyProfile,
  );
}

function resolveStaffCompanyId(profile, requestedCompanyId) {
  const role = String(profile?.data?.role || "").trim();
  const ownId = canonicalCompanyDocId(profile?.data?.companyRef?.id || "");
  const requested = canonicalCompanyDocId(requestedCompanyId || "");
  if (role === "superadmin") {
    return requested || ownId;
  }
  if (requested && ownId && requested !== ownId) {
    const error = new Error("Company belongs to another tenant");
    error.code = "permission-denied";
    throw error;
  }
  return ownId || requested;
}

function assertReviewBelongsToStaff(reviewData, profile) {
  const role = String(profile?.data?.role || "").trim();
  if (role === "superadmin") {
    return;
  }
  const staffCompanyId = canonicalCompanyDocId(profile?.data?.companyRef?.id || "");
  const reviewCompanyId = canonicalCompanyDocId(
    reviewData?.companyId || reviewData?.companyRef?.id || "",
  );
  if (!staffCompanyId || !reviewCompanyId || staffCompanyId !== reviewCompanyId) {
    const error = new Error("Shopify review belongs to another company");
    error.code = "permission-denied";
    throw error;
  }
}

module.exports = {
  DEFAULT_CREATE_ORDERS_ROLES,
  DEFAULT_EDIT_COMPANY_PROFILE_ROLES,
  canonicalCompanyDocId,
  loadStaffProfile,
  staffCanCreateOrders,
  staffCanEditCompanyProfile,
  resolveStaffCompanyId,
  assertReviewBelongsToStaff,
};
