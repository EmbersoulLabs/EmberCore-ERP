#!/usr/bin/env node
/**
 * Step 1 — SaaS registration smoke: submit user_registration_requests
 * the same way /userSignup does (unauthenticated Firestore client write).
 *
 *   node scripts/submit_registration_smoke.js
 *   node scripts/submit_registration_smoke.js --email custom@example.com
 *   node scripts/submit_registration_smoke.js --json
 *   node scripts/submit_registration_smoke.js --cleanup   # delete test doc (admin)
 */
const { initializeApp } = require("firebase/app");
const {
  getFirestore,
  doc,
  setDoc,
  getDoc,
  serverTimestamp,
} = require("firebase/firestore");
const admin = require("firebase-admin");
const { initializeAdmin } = require("./admin_init");

const PROJECT_ID = "embercore-erp";
const WEB_SIGNUP_URL = "https://embercore-erp.web.app/userSignup";
const REGISTRATION_COLLECTION = "user_registration_requests";

const { loadWebClientConfig } = require("./load_web_client_config");

const firebaseConfig = loadWebClientConfig("production");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const asJson = process.argv.includes("--json");
const cleanup = process.argv.includes("--cleanup");
const emailArg = argValue("--email");
const testEmail =
  (emailArg || process.env.REG_TEST_EMAIL || "").trim().toLowerCase() ||
  `saas-e2e-${new Date().toISOString().replace(/[:.]/g, "-")}@embersoullabs.com`;
const requestId = testEmail;

function log(message) {
  if (!asJson) {
    console.log(message);
  }
}

function buildPayload() {
  const companyName = `E2E Test Co ${new Date().toISOString().slice(0, 10)}`;
  return {
    email: testEmail,
    name: "E2E Test Director",
    phone: "+60123456789",
    account_type: "company",
    status: "pending",
    company_name: companyName,
    company_uen: "",
    company_address: "Kuala Lumpur, Malaysia",
    company_phone: "+60123456789",
    company_email: testEmail,
    created_time: serverTimestamp(),
  };
}

async function submitAsAnonymousClient(payload) {
  const app = initializeApp(firebaseConfig, "registration-smoke-client");
  const db = getFirestore(app);
  const ref = doc(db, REGISTRATION_COLLECTION, requestId);

  const existing = await getDoc(ref).catch((error) => {
    if (error.code === "permission-denied") {
      return null;
    }
    throw error;
  });
  if (existing?.exists()) {
    const status = existing.data()?.status;
    if (status === "pending") {
      throw new Error(
        `Registration already pending for ${testEmail}. Use --cleanup or another --email.`,
      );
    }
    if (status === "approved") {
      throw new Error(
        `Registration already approved for ${testEmail}. Use another --email.`,
      );
    }
  }

  await setDoc(ref, payload);
  return ref.path;
}

async function verifyAnonymousReadBlocked() {
  const app = initializeApp(firebaseConfig, "registration-smoke-read");
  const db = getFirestore(app);
  const ref = doc(db, REGISTRATION_COLLECTION, requestId);
  try {
    await getDoc(ref);
    return { ok: false, detail: "anonymous read succeeded (expected denied)" };
  } catch (error) {
    if (error.code === "permission-denied") {
      return { ok: true, detail: "anonymous read denied as expected" };
    }
    return { ok: false, detail: error.message || String(error) };
  }
}

async function verifyAdminRead() {
  initializeAdmin(PROJECT_ID);
  const db = admin.firestore();
  const snap = await db.doc(`${REGISTRATION_COLLECTION}/${requestId}`).get();
  if (!snap.exists) {
    return { ok: false, detail: "document missing after submit" };
  }
  const data = snap.data() || {};
  const ok =
    data.status === "pending" &&
    data.email === testEmail &&
    data.account_type === "company" &&
    typeof data.company_name === "string" &&
    data.company_name.length > 0;
  return {
    ok,
    detail: ok ? "pending company registration visible to admin" : data,
    data: {
      status: data.status,
      company_name: data.company_name,
      account_type: data.account_type,
    },
  };
}

async function cleanupDoc() {
  initializeAdmin(PROJECT_ID);
  await admin.firestore().doc(`${REGISTRATION_COLLECTION}/${requestId}`).delete();
}

async function main() {
  const payload = buildPayload();
  const result = {
    step: "C1 registration submit",
    project: PROJECT_ID,
    email: testEmail,
    requestId,
    signupUrl: WEB_SIGNUP_URL,
    approvalPath: "/registrationRequests",
    checks: {},
  };

  try {
    result.checks.submit = {
      ok: true,
      path: await submitAsAnonymousClient(payload),
    };
  } catch (error) {
    result.checks.submit = {
      ok: false,
      error: error.message || String(error),
    };
    result.ok = false;
    if (asJson) {
      console.log(JSON.stringify(result, null, 2));
    } else {
      console.error("Submit failed:", error.message || error);
    }
    process.exit(1);
  }

  result.checks.anonymousReadBlocked = await verifyAnonymousReadBlocked();
  result.checks.adminVerify = await verifyAdminRead();
  result.ok =
    result.checks.submit.ok &&
    result.checks.anonymousReadBlocked.ok &&
    result.checks.adminVerify.ok;

  if (cleanup && result.ok) {
    await cleanupDoc();
    result.cleanedUp = true;
  }

  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    log("");
    log("=== Step 1 registration smoke ===");
    log(`Project:     ${PROJECT_ID}`);
    log(`Email:       ${testEmail}`);
    log(`Doc ID:      ${requestId}`);
    log(`Company:     ${payload.company_name}`);
    log(`Submit:      ${result.checks.submit.ok ? "PASS" : "FAIL"}`);
    log(
      `Anon read:   ${result.checks.anonymousReadBlocked.ok ? "PASS (denied)" : "FAIL"}`,
    );
    log(`Admin read:  ${result.checks.adminVerify.ok ? "PASS" : "FAIL"}`);
    log(`Overall:     ${result.ok ? "PASS" : "FAIL"}`);
    log("");
    log("Next — Step 2 (superadmin):");
    log(`  1. Open https://embercore-erp.web.app/registrationRequests`);
    log(`  2. Find pending request for ${testEmail}`);
    log(`  3. Approve (leave password blank → copy reset link for director)`);
    if (cleanup) {
      log("");
      log("(Test document deleted with --cleanup)");
    }
  }

  process.exit(result.ok ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
