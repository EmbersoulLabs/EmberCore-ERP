#!/usr/bin/env node
/**
 * Enable Email/Password sign-in on a Firebase project (first-time Auth setup).
 *
 *   set GOOGLE_APPLICATION_CREDENTIALS=firebase/keys/embercore-erp-staging-serviceAccount.json
 *   node scripts/enable_staging_auth.js --project embercore-erp-staging
 */
const fs = require("fs");
const { GoogleAuth } = require("google-auth-library");
const { resolveKeyPathForProject } = require("./admin_init");

const projectId =
  process.argv.includes("--project") &&
  process.argv[process.argv.indexOf("--project") + 1]
    ? process.argv[process.argv.indexOf("--project") + 1]
    : "embercore-erp-staging";

async function getClient(projectId, keyPath) {
  const key = JSON.parse(fs.readFileSync(keyPath, "utf8"));
  const auth = new GoogleAuth({
    credentials: key,
    scopes: ["https://www.googleapis.com/auth/cloud-platform"],
  });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token;
}

async function apiCall(token, url, method, body) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "X-Goog-User-Project": projectId,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) {
    const err = new Error(`Failed (${res.status}): ${text}`);
    err.status = res.status;
    throw err;
  }
  return text ? JSON.parse(text) : {};
}

async function main() {
  const keyPath = resolveKeyPathForProject(projectId);
  if (!keyPath) {
    console.error(`No service account key for ${projectId}`);
    process.exit(1);
  }
  const token = await getClient(projectId, keyPath);

  console.log(`Enabling identitytoolkit service on ${projectId}...`);
  try {
    await apiCall(
      token,
      `https://serviceusage.googleapis.com/v1/projects/${projectId}/services:batchEnable`,
      "POST",
      { serviceIds: ["identitytoolkit.googleapis.com"] },
    );
  } catch (err) {
    if (err.status !== 409) {
      console.warn("Service enable:", err.message);
    }
  }

  console.log(`Initializing Identity Platform on ${projectId}...`);
  try {
    await apiCall(
      token,
      `https://identitytoolkit.googleapis.com/v2/projects/${projectId}/identityPlatform:initializeAuth`,
      "POST",
      {},
    );
    console.log("Identity Platform initialized.");
  } catch (err) {
    if (err.status === 409 || err.message.includes("ALREADY_EXISTS")) {
      console.log("Identity Platform already initialized.");
    } else {
      throw err;
    }
  }

  console.log("Enabling email/password sign-in...");
  await apiCall(
    token,
    `https://identitytoolkit.googleapis.com/v2/projects/${projectId}/config` +
      "?updateMask=signIn.email.enabled,signIn.email.passwordRequired",
    "PATCH",
    {
      signIn: {
        email: {
          enabled: true,
          passwordRequired: true,
        },
      },
    },
  );

  console.log(`Auth email/password enabled for ${projectId}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
