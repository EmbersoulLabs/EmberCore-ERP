#!/usr/bin/env node
/**
 * Point cloud.firestore release at an existing ruleset (rollback / promote without :test).
 *
 *   node scripts/release_firestore_ruleset.js --ruleset f9c3ac1f-725e-4fff-9be6-df4f3903518e
 *   node scripts/release_firestore_ruleset.js --ruleset 6c5f329e-8ed5-45d7-abe1-547594ae6a21
 */
const fs = require("fs");
const os = require("os");
const path = require("path");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId =
  argValue("--project") || process.env.FIREBASE_PROJECT || "embercore-erp";
const rulesetId = argValue("--ruleset");
if (!rulesetId) {
  console.error("Usage: node scripts/release_firestore_ruleset.js --ruleset RULESET_ID");
  process.exit(1);
}

const configPath = path.join(
  os.homedir(),
  ".config",
  "configstore",
  "firebase-tools.json",
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const token = config?.tokens?.access_token;
if (!token) {
  console.error("Run firebase login first.");
  process.exit(1);
}

const rulesetName = `projects/${projectId}/rulesets/${rulesetId}`;
const releaseName = `projects/${projectId}/releases/cloud.firestore`;

async function main() {
  const response = await fetch(
    `https://firebaserules.googleapis.com/v1/${releaseName}`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        release: { name: releaseName, rulesetName },
        updateMask: "rulesetName",
      }),
    },
  );
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`PATCH ${releaseName} failed (${response.status}): ${text}`);
  }
  console.log(`Released ${rulesetName} to cloud.firestore`);
  console.log(text);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
