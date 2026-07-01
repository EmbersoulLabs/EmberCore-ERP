#!/usr/bin/env node
/**
 * Deploy Firestore rules via Rules Management API (bypasses firebase CLI :test when 503).
 *
 *   node scripts/deploy_firestore_rules.js --project embercore-erp
 */
const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");
const { initializeAdmin, resolveKeyPathForProject } = require("./admin_init");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId =
  argValue("--project") || process.env.FIREBASE_PROJECT || "embercore-erp";
const rulesPath = path.resolve(__dirname, "../firestore.rules");
const keyPath = resolveKeyPathForProject(projectId);

if (!keyPath) {
  console.error(`Missing service account key for ${projectId}`);
  process.exit(1);
}

const rulesContent = fs.readFileSync(rulesPath, "utf8");

async function apiRequest(auth, method, urlPath, body) {
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  const url = `https://firebaserules.googleapis.com/v1/${urlPath}`;
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token.token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = { raw: text };
  }
  if (!response.ok) {
    throw new Error(
      `${method} ${urlPath} failed (${response.status}): ${text}`,
    );
  }
  return json;
}

async function main() {
  const auth = new GoogleAuth({
    keyFile: keyPath,
    scopes: ["https://www.googleapis.com/auth/cloud-platform"],
  });

  console.log(`Creating ruleset for ${projectId}...`);
  const ruleset = await apiRequest(
    auth,
    "POST",
    `projects/${projectId}/rulesets`,
    {
      source: {
        files: [{ name: "firestore.rules", content: rulesContent }],
      },
    },
  );

  const rulesetName = ruleset.name;
  console.log(`Ruleset created: ${rulesetName}`);

  console.log("Releasing to cloud.firestore...");
  await apiRequest(
    auth,
    "POST",
    `projects/${projectId}/releases`,
    {
      name: `projects/${projectId}/releases/cloud.firestore`,
      rulesetName,
    },
  );

  console.log(`Firestore rules deployed to ${projectId}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
