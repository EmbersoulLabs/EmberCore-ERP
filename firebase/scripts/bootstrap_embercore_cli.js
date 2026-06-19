#!/usr/bin/env node
/**
 * Bootstrap embercore-erp using Firebase CLI OAuth (no service account file).
 *
 *   set EMBERCORE_SUPERADMIN_PASSWORD=...
 *   set EMBERCORE_DIRECTOR_PASSWORD=...
 *   node scripts/bootstrap_embercore_cli.js
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { OAuth2Client } = require("google-auth-library");

const PROJECT_ID = "embercore-erp";
const DEFAULT_COMPANY_ID = "demo_company";
const DEFAULT_COMPANY_NAME = "EmberCore Demo Florist";
const CONFIG_PATH = path.join(
  os.homedir(),
  ".config",
  "configstore",
  "firebase-tools.json",
);

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

function loadCliCredentials() {
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
  const refreshToken = config?.tokens?.refresh_token;
  const clientId = config?.user?.azp;
  if (!refreshToken || !clientId) {
    throw new Error("Run firebase login first.");
  }
  return { refreshToken, clientId };
}

async function getAccessToken() {
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
  const accessToken = config?.tokens?.access_token;
  const expiresAt = config?.tokens?.expires_at || 0;
  if (accessToken && Date.now() < expiresAt - 60_000) {
    return accessToken;
  }
  const { refreshToken, clientId } = loadCliCredentials();
  const client = new OAuth2Client(clientId);
  client.setCredentials({ refresh_token: refreshToken });
  const response = await client.getAccessToken();
  if (!response.token) {
    throw new Error("Could not refresh Firebase CLI access token. Run firebase login.");
  }
  return response.token;
}

async function apiFetch(url, accessToken, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch (_) {
    body = text;
  }
  if (!response.ok) {
    const message =
      typeof body === "object" && body?.error?.message
        ? body.error.message
        : text;
    const error = new Error(message || `HTTP ${response.status}`);
    error.status = response.status;
    error.body = body;
    throw error;
  }
  return body;
}

function firestoreValue(value) {
  if (value && typeof value === "object" && value.__ref) {
    return {
      referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${value.__ref}`,
    };
  }
  if (value === null || value === undefined) {
    return { nullValue: null };
  }
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (typeof value === "boolean") {
    return { booleanValue: value };
  }
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === "string") {
    return { stringValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(firestoreValue) } };
  }
  if (typeof value === "object") {
    const fields = {};
    for (const [key, nested] of Object.entries(value)) {
      fields[key] = firestoreValue(nested);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function companyRef() {
  return { __ref: `Companies/${DEFAULT_COMPANY_ID}` };
}

async function patchDocument(accessToken, collection, docId, data) {
  const fields = {};
  const mask = [];
  for (const [key, value] of Object.entries(data)) {
    fields[key] = firestoreValue(value);
    mask.push(`updateMask.fieldPaths=${encodeURIComponent(key)}`);
  }
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}?` +
    mask.join("&");
  return apiFetch(url, accessToken, {
    method: "PATCH",
    body: JSON.stringify({ fields }),
  });
}

async function getDocument(accessToken, collection, docId) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
  try {
    return await apiFetch(url, accessToken, { method: "GET" });
  } catch (error) {
    if (error.status === 404) {
      return null;
    }
    throw error;
  }
}

async function ensureAuthUser(accessToken, { email, password, displayName }) {
  const lookupUrl = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:lookup`;
  let existing = null;
  try {
    existing = await apiFetch(lookupUrl, accessToken, {
      method: "POST",
      body: JSON.stringify({ email: [email] }),
    });
  } catch (_) {
    existing = null;
  }

  if (existing?.users?.length) {
    const uid = existing.users[0].localId;
    const updateUrl = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:update`;
    await apiFetch(updateUrl, accessToken, {
      method: "POST",
      body: JSON.stringify({
        localId: uid,
        password,
        displayName,
        disableUser: false,
        emailVerified: true,
      }),
    });
    return { uid, action: "updated" };
  }

  const createUrl = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts`;
  const created = await apiFetch(createUrl, accessToken, {
    method: "POST",
    body: JSON.stringify({
      email,
      password,
      displayName,
      disabled: false,
      emailVerified: true,
    }),
  });
  return { uid: created.localId, action: "created" };
}

async function ensureDoc(accessToken, collection, docId, data) {
  const exists = await getDocument(accessToken, collection, docId);
  if (exists) {
    return { path: `${collection}/${docId}`, action: "exists" };
  }
  await patchDocument(accessToken, collection, docId, data);
  return { path: `${collection}/${docId}`, action: "created" };
}

async function main() {
  const superadminEmail = (
    process.env.EMBERCORE_SUPERADMIN_EMAIL || "kahliantoo@gmail.com"
  )
    .trim()
    .toLowerCase();
  const directorEmail = (
    process.env.EMBERCORE_DIRECTOR_EMAIL || "demo.director@embersoullabs.com"
  )
    .trim()
    .toLowerCase();
  const superadminPassword = process.env.EMBERCORE_SUPERADMIN_PASSWORD;
  const directorPassword = process.env.EMBERCORE_DIRECTOR_PASSWORD;
  if (!superadminPassword || !directorPassword) {
    throw new Error(
      "Set EMBERCORE_SUPERADMIN_PASSWORD and EMBERCORE_DIRECTOR_PASSWORD.",
    );
  }

  const accessToken = await getAccessToken();
  const company = await ensureDoc(accessToken, "Companies", DEFAULT_COMPANY_ID, {
    Company_name: DEFAULT_COMPANY_NAME,
    is_active: true,
  });

  const counters = [];
  for (const suffix of ["delivery", "retail", "invoice", "customer"]) {
    counters.push(
      await ensureDoc(accessToken, "counter", `${DEFAULT_COMPANY_ID}_${suffix}`, {
        current: 0,
      }),
    );
  }

  const platformConfig = await ensureDoc(
    accessToken,
    "tenant_platform_config",
    DEFAULT_COMPANY_ID,
    {
      ...GENERIC_PLATFORM_CONFIG,
      updated_at: new Date().toISOString(),
    },
  );
  const staffRoles = await ensureDoc(
    accessToken,
    "staff_roles",
    DEFAULT_COMPANY_ID,
    {
      companyRef: companyRef(),
      roles: ["admin", "senior_florist", "florist", "driver"],
    },
  );
  const rolePermissions = await ensureDoc(
    accessToken,
    "role_permissions",
    DEFAULT_COMPANY_ID,
    {
      companyRef: companyRef(),
      roles: {},
    },
  );
  const categories = await ensureDoc(
    accessToken,
    "product_categories",
    DEFAULT_COMPANY_ID,
    {
      companyRef: companyRef(),
      categories: [
        "Hand Bouquet",
        "Wreath",
        "Opening Stand",
        "Table arrangement",
        "AdHoc",
      ],
    },
  );

  const superadmin = await ensureAuthUser(accessToken, {
    email: superadminEmail,
    password: superadminPassword,
    displayName: "EmberCore Superadmin",
  });
  const director = await ensureAuthUser(accessToken, {
    email: directorEmail,
    password: directorPassword,
    displayName: "Demo Director",
  });

  const superadminProfile = await ensureDoc(
    accessToken,
    "users",
    superadmin.uid,
    {
      uid: superadmin.uid,
      email: superadminEmail,
      name: "EmberCore Superadmin",
      display_name: "EmberCore Superadmin",
      role: "superadmin",
      is_active: true,
    },
  );
  const directorProfile = await ensureDoc(accessToken, "users", director.uid, {
    uid: director.uid,
    email: directorEmail,
    name: "Demo Director",
    display_name: "Demo Director",
    role: "director",
    is_active: true,
    companyRef: companyRef(),
  });

  console.log(
    JSON.stringify(
      {
        projectId: PROJECT_ID,
        company,
        counters,
        platformConfig,
        staffRoles,
        rolePermissions,
        categories,
        superadmin: { email: superadminEmail, ...superadmin, ...superadminProfile },
        director: { email: directorEmail, ...director, ...directorProfile },
        webUrl: "https://embercore-erp.web.app",
      },
      null,
      2,
    ),
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
