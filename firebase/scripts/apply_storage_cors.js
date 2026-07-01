#!/usr/bin/env node
/**
 * Apply CORS to Firebase Storage buckets (required for Flutter Web image loading).
 *
 *   node scripts/apply_storage_cors.js --project embercore-erp
 *
 * Uses gsutil when available; otherwise patches bucket metadata via Admin SDK.
 */
const { execSync, spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
} = require("./admin_init");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId =
  argValue("--project") || process.env.FIREBASE_PROJECT || "embercore-erp";
const bucket = `${projectId}.firebasestorage.app`;
const corsFile = path.resolve(__dirname, "../storage.cors.json");

if (!fs.existsSync(corsFile)) {
  console.error("Missing firebase/storage.cors.json");
  process.exit(1);
}

const corsConfig = JSON.parse(fs.readFileSync(corsFile, "utf8"));

function gsutilAvailable() {
  const result = spawnSync("gsutil", ["version"], { stdio: "ignore" });
  return result.status === 0;
}

function applyViaGsutil() {
  execSync(`gsutil cors set "${corsFile}" gs://${bucket}`, {
    stdio: "inherit",
  });
  console.log(`CORS applied to gs://${bucket} (gsutil)`);
}

async function applyViaAdminSdk() {
  try {
    initializeAdmin(projectId);
  } catch (err) {
    console.error(credentialsHelp(projectId));
    process.exit(1);
  }

  const storageBucket = admin.storage().bucket(bucket);
  await storageBucket.setMetadata({ cors: corsConfig });
  console.log(`CORS applied to gs://${bucket} (Admin SDK)`);
}

async function main() {
  if (gsutilAvailable()) {
    applyViaGsutil();
    return;
  }

  console.log("gsutil not found — applying CORS via Firebase Admin SDK...");
  await applyViaAdminSdk();
}

main().catch((err) => {
  console.error("");
  console.error(`Failed to apply CORS to gs://${bucket}`);
  console.error(err.message || err);
  console.error("");
  process.exit(1);
});
