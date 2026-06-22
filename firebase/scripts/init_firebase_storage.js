#!/usr/bin/env node
/**
 * Initialize Firebase Storage default bucket via REST API (replaces Console "Get started").
 *
 *   node scripts/init_firebase_storage.js --project embercore-erp --location asia-southeast1
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { OAuth2Client } = require("google-auth-library");

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

const projectId = argValue("--project") || "embercore-erp";
const location = argValue("--location") || "asia-southeast1";

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

async function main() {
  const accessToken = await getAccessToken();
  const url = `https://firebasestorage.googleapis.com/v1alpha/projects/${projectId}/defaultBucket`;
  const body = await apiFetch(url, accessToken, {
    method: "POST",
    body: JSON.stringify({ location }),
  });
  console.log(
    JSON.stringify({
      projectId,
      location,
      action: "created_or_linked",
      bucket: body?.name || body?.bucket?.name || `${projectId}.firebasestorage.app`,
      response: body,
    }),
  );
}

main().catch((error) => {
  console.error(error.message || error);
  if (error.body) {
    console.error(JSON.stringify(error.body, null, 2));
  }
  console.error("");
  console.error(
    `If this failed, open https://console.firebase.google.com/project/${projectId}/storage and click Get started.`,
  );
  process.exit(1);
});
