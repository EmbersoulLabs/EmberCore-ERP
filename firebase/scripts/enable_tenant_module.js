#!/usr/bin/env node
/**
 * Add a platform module to tenant_platform_config/{companyId}.enabled_modules.
 *
 *   node scripts/enable_tenant_module.js --company demo_company --module whatsappImport
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { OAuth2Client } = require("google-auth-library");

const PROJECT_ID = "embercore-erp";
const CONFIG_PATH = path.join(
  os.homedir(),
  ".config",
  "configstore",
  "firebase-tools.json",
);

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const companyId = argValue("--company") || "demo_company";
const moduleName = argValue("--module");
if (!moduleName) {
  console.error("Usage: node enable_tenant_module.js --company ID --module NAME");
  process.exit(1);
}

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
    throw error;
  }
  return body;
}

function firestoreValue(value) {
  if (typeof value === "string") {
    return { stringValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(firestoreValue) } };
  }
  return { stringValue: String(value) };
}

function decodeFirestoreValue(value) {
  if (!value || typeof value !== "object") {
    return null;
  }
  if ("stringValue" in value) {
    return value.stringValue;
  }
  if ("arrayValue" in value) {
    const values = value.arrayValue?.values || [];
    return values.map(decodeFirestoreValue);
  }
  return null;
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

async function main() {
  const accessToken = await getAccessToken();
  const doc = await getDocument(accessToken, "tenant_platform_config", companyId);
  if (!doc) {
    throw new Error(`tenant_platform_config/${companyId} not found. Run bootstrap first.`);
  }

  const current =
    decodeFirestoreValue(doc.fields?.enabled_modules) || [];
  if (current.includes(moduleName)) {
    console.log(
      JSON.stringify({
        companyId,
        module: moduleName,
        action: "already_enabled",
        enabled_modules: current,
      }),
    );
    return;
  }

  const updated = [...current, moduleName].sort();
  await patchDocument(accessToken, "tenant_platform_config", companyId, {
    enabled_modules: updated,
    updated_at: new Date().toISOString(),
  });

  console.log(
    JSON.stringify({
      companyId,
      module: moduleName,
      action: "enabled",
      enabled_modules: updated,
    }),
  );
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
