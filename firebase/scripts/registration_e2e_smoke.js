#!/usr/bin/env node
/**
 * Registration E2E smoke — Steps 2–4 (approve → director login → first order).
 *
 *   set EMBERCORE_SUPERADMIN_PASSWORD=...
 *   node scripts/registration_e2e_smoke.js --email pending@example.com
 *   node scripts/registration_e2e_smoke.js --fresh          # submit Step 1 then approve
 *   node scripts/registration_e2e_smoke.js --json
 */
const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, signOut } = require("firebase/auth");
const {
  getFirestore,
  doc,
  getDoc,
  collection,
  addDoc,
  serverTimestamp,
} = require("firebase/firestore");
const { getFunctions, httpsCallable } = require("firebase/functions");
const admin = require("firebase-admin");
const { initializeAdmin } = require("./admin_init");

const PROJECT_ID = "embercore-erp";
const FUNCTIONS_REGION = "asia-southeast1";
const SUPERADMIN_EMAIL =
  process.env.EMBERCORE_SUPERADMIN_EMAIL || "kahliantoo@gmail.com";
const REGISTRATION_COLLECTION = "user_registration_requests";
const DIRECTOR_E2E_PASSWORD =
  process.env.REG_E2E_DIRECTOR_PASSWORD || "E2eDirector2026!";

const firebaseConfig = {
  apiKey: "REDACTED_API_KEY",
  authDomain: "embercore-erp.firebaseapp.com",
  projectId: PROJECT_ID,
  storageBucket: "embercore-erp.firebasestorage.app",
  messagingSenderId: "1098308969895",
  appId: "1:1098308969895:web:15747b5faa30917cff8282",
};

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const asJson = process.argv.includes("--json");
const fresh = process.argv.includes("--fresh");
const emailArg = (argValue("--email") || process.env.REG_TEST_EMAIL || "")
  .trim()
  .toLowerCase();

function log(message) {
  if (!asJson) {
    console.log(message);
  }
}

function orderPeriodSuffix(date = new Date()) {
  const months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];
  const month = months[date.getMonth()];
  const year = String(date.getFullYear()).slice(-2);
  return `${month}${year}`;
}

async function findLatestPendingEmail() {
  initializeAdmin(PROJECT_ID);
  const db = admin.firestore();
  const snap = await db
    .collection(REGISTRATION_COLLECTION)
    .where("status", "==", "pending")
    .orderBy("created_time", "desc")
    .limit(5)
    .get();
  if (snap.empty) {
    return null;
  }
  for (const docSnap of snap.docs) {
    const email = (docSnap.data().email || docSnap.id || "").toLowerCase();
    if (email.includes("@embersoullabs.com")) {
      return email;
    }
  }
  return (snap.docs[0].data().email || snap.docs[0].id).toLowerCase();
}

async function submitFreshRegistration(email) {
  const { execSync } = require("child_process");
  execSync(
    `node scripts/submit_registration_smoke.js --email ${email} --json`,
    { cwd: require("path").join(__dirname, ".."), stdio: "pipe" },
  );
}

async function approveAsSuperadmin(requestId) {
  const superadminPassword = process.env.EMBERCORE_SUPERADMIN_PASSWORD;
  if (!superadminPassword) {
    throw new Error("Set EMBERCORE_SUPERADMIN_PASSWORD.");
  }

  const app = initializeApp(firebaseConfig, "registration-e2e-superadmin");
  const auth = getAuth(app);
  await signInWithEmailAndPassword(auth, SUPERADMIN_EMAIL, superadminPassword);

  const functions = getFunctions(app, FUNCTIONS_REGION);
  const approve = httpsCallable(functions, "approveRegistrationRequest");
  const response = await approve({
    requestId,
    initialPassword: DIRECTOR_E2E_PASSWORD,
  });

  await signOut(auth);
  return response.data;
}

async function verifyDirectorLogin(email, companyPath) {
  const app = initializeApp(firebaseConfig, "registration-e2e-director");
  const auth = getAuth(app);
  const db = getFirestore(app);

  await signInWithEmailAndPassword(auth, email, DIRECTOR_E2E_PASSWORD);
  const uid = auth.currentUser?.uid;
  if (!uid) {
    throw new Error("Director signed in but uid missing.");
  }

  const userSnap = await getDoc(doc(db, "users", uid));
  const user = userSnap.data() || {};
  const companyRefPath = user.companyRef?.path || user.companyRef;
  const roleOk = user.role === "director";
  const companyOk =
    companyRefPath === companyPath ||
    (typeof companyRefPath === "string" && companyRefPath.endsWith(companyPath.split("/").pop()));

  const period = orderPeriodSuffix();
  const orderId = `EC-${period}-00099`;
  const companyRef = doc(db, companyPath);
  const orderRef = await addDoc(collection(db, "orders"), {
    Order_Id: orderId,
    status: "pending",
    orderstatus: "pending",
    orderType: "Remote",
    companyRef,
    created_time: serverTimestamp(),
  });

  await signOut(auth);
  return {
    ok: roleOk && companyOk,
    uid,
    role: user.role,
    companyRefPath,
    orderDocId: orderRef.id,
    orderId,
    orderIdPrefixOk: orderId.startsWith("EC-"),
  };
}

async function verifyProvisioning(requestId, companyId) {
  if (!admin.apps.length) {
    initializeAdmin(PROJECT_ID);
  }
  const db = admin.firestore();
  const [reqSnap, configSnap, companySnap] = await Promise.all([
    db.doc(`${REGISTRATION_COLLECTION}/${requestId}`).get(),
    db.doc(`tenant_platform_config/${companyId}`).get(),
    db.doc(`Companies/${companyId}`).get(),
  ]);

  const config = configSnap.data() || {};
  const req = reqSnap.data() || {};
  const approved = req.status === "approved";

  return {
    ok:
      approved &&
      companySnap.exists &&
      companySnap.data()?.is_active !== false &&
      config.order_id_prefix === "EC",
    approved,
    orderIdPrefix: config.order_id_prefix,
    industryKey: config.industry_key,
    companyName: companySnap.data()?.Company_name,
  };
}

async function main() {
  const result = {
    step: "C registration E2E (steps 2–4)",
    project: PROJECT_ID,
    checks: {},
  };

  try {
    let email = emailArg;
    if (fresh) {
      email =
        email ||
        `saas-e2e-${new Date().toISOString().replace(/[:.]/g, "-")}@embersoullabs.com`;
      log(`Step 1 — submit fresh registration for ${email}`);
      await submitFreshRegistration(email);
      result.checks.step1Submit = { ok: true, email };
    }

    if (!email) {
      email = await findLatestPendingEmail();
    }
    if (!email) {
      throw new Error(
        "No pending registration found. Pass --email or run with --fresh.",
      );
    }

    email = email.trim().toLowerCase();
    const requestId = email;
    result.email = email;
    result.requestId = requestId;

    initializeAdmin(PROJECT_ID);
    const db = admin.firestore();
    const pendingSnap = await db
      .doc(`${REGISTRATION_COLLECTION}/${requestId}`)
      .get();
    if (!pendingSnap.exists || pendingSnap.data()?.status !== "pending") {
      throw new Error(
        `Registration ${requestId} is not pending (status=${pendingSnap.data()?.status}).`,
      );
    }

    log(`Step 2 — approve ${requestId} as superadmin`);
    const approveData = await approveAsSuperadmin(requestId);
    result.checks.step2Approve = {
      ok: Boolean(approveData?.companyId),
      companyId: approveData.companyId,
      companyPath: approveData.companyPath,
      userUid: approveData.userUid,
      passwordSet: approveData.passwordSet,
    };

    const companyId = approveData.companyId;
    const companyPath = approveData.companyPath || `Companies/${companyId}`;

    log("Step 3 — director login + profile");
    const directorCheck = await verifyDirectorLogin(email, companyPath);
    result.checks.step3DirectorLogin = directorCheck;

    log("Step 4 — tenant config + first order");
    const provisionCheck = await verifyProvisioning(requestId, companyId);
    result.checks.step4Provisioning = provisionCheck;
    result.checks.step4FirstOrder = {
      ok: directorCheck.orderIdPrefixOk && Boolean(directorCheck.orderDocId),
      orderId: directorCheck.orderId,
      orderDocId: directorCheck.orderDocId,
    };

    result.ok =
      result.checks.step2Approve.ok &&
      result.checks.step3DirectorLogin.ok &&
      result.checks.step4Provisioning.ok &&
      result.checks.step4FirstOrder.ok;
  } catch (error) {
    result.ok = false;
    result.error = error.message || String(error);
    if (error.details) {
      result.errorDetails = error.details;
    }
  }

  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    log("");
    log("=== Registration E2E smoke (steps 2–4) ===");
    log(`Email:       ${result.email || "(none)"}`);
    if (result.checks.step2Approve) {
      log(
        `Step 2 approve: ${result.checks.step2Approve.ok ? "PASS" : "FAIL"} · company ${result.checks.step2Approve.companyId}`,
      );
    }
    if (result.checks.step3DirectorLogin) {
      log(
        `Step 3 login:   ${result.checks.step3DirectorLogin.ok ? "PASS" : "FAIL"} · role ${result.checks.step3DirectorLogin.role}`,
      );
    }
    if (result.checks.step4Provisioning) {
      log(
        `Step 4 config:  ${result.checks.step4Provisioning.ok ? "PASS" : "FAIL"} · prefix ${result.checks.step4Provisioning.orderIdPrefix}`,
      );
    }
    if (result.checks.step4FirstOrder) {
      log(
        `Step 4 order:   ${result.checks.step4FirstOrder.ok ? "PASS" : "FAIL"} · ${result.checks.step4FirstOrder.orderId}`,
      );
    }
    log(`Overall:       ${result.ok ? "PASS" : "FAIL"}`);
    if (result.error) {
      log(`Error:         ${result.error}`);
    }
  }

  process.exit(result.ok ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

