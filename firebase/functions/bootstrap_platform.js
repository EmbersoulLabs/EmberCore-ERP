/**
 * One-time / idempotent platform bootstrap for a fresh Firebase project.
 * Invoked by HTTPS function using Admin SDK (no local service account required).
 */
const admin = require("firebase-admin");

const DEFAULT_COMPANY_ID = "demo_company";
const DEFAULT_COMPANY_NAME = "EmberCore Demo Florist";
const DEFAULT_SUPERADMIN_EMAIL = "admin@embersoullabs.com";
const DEFAULT_DIRECTOR_EMAIL = "demo.director@embersoullabs.com";
const DEFAULT_SUPERADMIN_NAME = "EmberCore Superadmin";
const DEFAULT_DIRECTOR_NAME = "Demo Director";

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

const DEFAULT_STAFF_ROLES = ["admin", "senior_florist", "florist", "driver"];
const DEFAULT_CATEGORIES = [
  "Hand Bouquet",
  "Wreath",
  "Opening Stand",
  "Table arrangement",
  "AdHoc",
];

function readBootstrapConfig() {
  const secret =
    process.env.BOOTSTRAP_SECRET ||
    process.env.bootstrap_secret ||
    "";
  const superadminEmail =
    process.env.BOOTSTRAP_SUPERADMIN_EMAIL ||
    process.env.bootstrap_superadmin_email ||
    DEFAULT_SUPERADMIN_EMAIL;
  const directorEmail =
    process.env.BOOTSTRAP_DIRECTOR_EMAIL ||
    process.env.bootstrap_director_email ||
    DEFAULT_DIRECTOR_EMAIL;
  const superadminPassword =
    process.env.BOOTSTRAP_SUPERADMIN_PASSWORD ||
    process.env.bootstrap_superadmin_password ||
    "";
  const directorPassword =
    process.env.BOOTSTRAP_DIRECTOR_PASSWORD ||
    process.env.bootstrap_director_password ||
    "";
  return {
    secret,
    superadminEmail: superadminEmail.trim().toLowerCase(),
    directorEmail: directorEmail.trim().toLowerCase(),
    superadminPassword,
    directorPassword,
  };
}

async function ensureAuthUser({ email, password, displayName }) {
  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
    if (password) {
      await admin.auth().updateUser(user.uid, {
        password,
        displayName,
        disabled: false,
      });
    }
    return { uid: user.uid, action: "exists" };
  } catch (err) {
    if (err.code !== "auth/user-not-found") {
      throw err;
    }
    if (!password) {
      throw new Error(`Missing password for new user ${email}`);
    }
    user = await admin.auth().createUser({
      email,
      password,
      displayName,
      disabled: false,
    });
    return { uid: user.uid, action: "created" };
  }
}

async function ensureUserProfile({
  uid,
  email,
  name,
  role,
  companyRef = null,
}) {
  const db = admin.firestore();
  const ref = db.collection("users").doc(uid);
  const data = {
    uid,
    email,
    name,
    display_name: name,
    role,
    is_active: true,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (companyRef) {
    data.companyRef = companyRef;
  }
  await ref.set(data, { merge: true });
  return ref.path;
}

async function ensureCompany(db, companyId) {
  const ref = db.collection("Companies").doc(companyId);
  const snap = await ref.get();
  if (snap.exists) {
    return { companyId, action: "exists", companyRef: ref };
  }
  await ref.set({
    Company_name: DEFAULT_COMPANY_NAME,
    is_active: true,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { companyId, action: "created", companyRef: ref };
}

async function ensureCounters(db, companyId) {
  const results = [];
  for (const suffix of ["delivery", "retail", "invoice", "customer"]) {
    const ref = db.collection("counter").doc(`${companyId}_${suffix}`);
    const snap = await ref.get();
    if (snap.exists) {
      results.push({ counter: ref.id, action: "exists" });
      continue;
    }
    await ref.set({ current: 0 });
    results.push({ counter: ref.id, action: "created" });
  }
  return results;
}

async function ensureTenantConfig(db, companyId) {
  const ref = db.collection("tenant_platform_config").doc(companyId);
  const snap = await ref.get();
  if (snap.exists) {
    return { path: ref.path, action: "exists" };
  }
  await ref.set({
    ...GENERIC_PLATFORM_CONFIG,
    updated_at: new Date().toISOString(),
  });
  return { path: ref.path, action: "created" };
}

async function ensureStaffRoles(db, companyRef, companyId) {
  const ref = db.collection("staff_roles").doc(companyId);
  const snap = await ref.get();
  if (snap.exists) {
    return { path: ref.path, action: "exists" };
  }
  await ref.set({
    companyRef,
    roles: DEFAULT_STAFF_ROLES,
    updated_time: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { path: ref.path, action: "created" };
}

async function ensureRolePermissions(db, companyRef, companyId) {
  const ref = db.collection("role_permissions").doc(companyId);
  const snap = await ref.get();
  if (snap.exists) {
    return { path: ref.path, action: "exists" };
  }
  await ref.set({
    companyRef,
    roles: {},
    updated_time: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { path: ref.path, action: "created" };
}

async function ensureProductCategories(db, companyRef, companyId) {
  const ref = db.collection("product_categories").doc(companyId);
  const snap = await ref.get();
  if (snap.exists) {
    return { path: ref.path, action: "exists" };
  }
  await ref.set({
    companyRef,
    categories: DEFAULT_CATEGORIES,
    updated_time: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { path: ref.path, action: "created" };
}

async function ensureDemoProduct(db, companyRef, companyId) {
  const existing = await db
    .collection("product")
    .where("companyRef", "==", companyRef)
    .limit(1)
    .get();
  if (!existing.empty) {
    return { action: "exists", productId: existing.docs[0].id };
  }
  const ref = db.collection("product").doc();
  await ref.set({
    name: "Demo Rose Bouquet",
    category: "Hand Bouquet",
    price: 88,
    is_active: true,
    companyRef,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { action: "created", productId: ref.id };
}

async function bootstrapEmbercorePlatform() {
  const config = readBootstrapConfig();
  if (!config.superadminPassword || !config.directorPassword) {
    throw new Error(
      "Set BOOTSTRAP_SUPERADMIN_PASSWORD and BOOTSTRAP_DIRECTOR_PASSWORD",
    );
  }

  const db = admin.firestore();
  const company = await ensureCompany(db, DEFAULT_COMPANY_ID);
  const companyRef = company.companyRef;

  const counters = await ensureCounters(db, DEFAULT_COMPANY_ID);
  const platformConfig = await ensureTenantConfig(db, DEFAULT_COMPANY_ID);
  const staffRoles = await ensureStaffRoles(db, companyRef, DEFAULT_COMPANY_ID);
  const rolePermissions = await ensureRolePermissions(
    db,
    companyRef,
    DEFAULT_COMPANY_ID,
  );
  const categories = await ensureProductCategories(
    db,
    companyRef,
    DEFAULT_COMPANY_ID,
  );
  const product = await ensureDemoProduct(db, companyRef, DEFAULT_COMPANY_ID);

  const superadmin = await ensureAuthUser({
    email: config.superadminEmail,
    password: config.superadminPassword,
    displayName: DEFAULT_SUPERADMIN_NAME,
  });
  const director = await ensureAuthUser({
    email: config.directorEmail,
    password: config.directorPassword,
    displayName: DEFAULT_DIRECTOR_NAME,
  });

  const superadminProfile = await ensureUserProfile({
    uid: superadmin.uid,
    email: config.superadminEmail,
    name: DEFAULT_SUPERADMIN_NAME,
    role: "superadmin",
  });
  const directorProfile = await ensureUserProfile({
    uid: director.uid,
    email: config.directorEmail,
    name: DEFAULT_DIRECTOR_NAME,
    role: "director",
    companyRef,
  });

  return {
    company,
    counters,
    platformConfig,
    staffRoles,
    rolePermissions,
    categories,
    product,
    superadmin: {
      ...superadmin,
      profile: superadminProfile,
      email: config.superadminEmail,
    },
    director: {
      ...director,
      profile: directorProfile,
      email: config.directorEmail,
    },
    webUrl: "https://embercore-erp.web.app",
  };
}

module.exports = {
  bootstrapEmbercorePlatform,
  readBootstrapConfig,
  DEFAULT_COMPANY_ID,
};
