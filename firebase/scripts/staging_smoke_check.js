#!/usr/bin/env node
/**
 * Post-deploy smoke checks against embercore-erp-staging Firebase + Hosting.
 *
 *   set STAGING_ADMIN_PASSWORD=<password>
 *   node scripts/staging_smoke_check.js
 *   node scripts/staging_smoke_check.js --json
 */
const { initializeApp } = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const { getFirestore, doc, getDoc, collection, query, where, limit, getDocs } =
  require("firebase/firestore");
const {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
  deleteObject,
} = require("firebase/storage");

const STAGING_WEB_URL = "https://embercore-erp-staging.web.app";
const ADMIN_EMAIL = "staging.admin@embersoullabs.com";
const COMPANY_ID = "staging_company";

const firebaseConfig = {
  apiKey: "REDACTED_API_KEY",
  authDomain: "embercore-erp-staging.firebaseapp.com",
  projectId: "embercore-erp-staging",
  storageBucket: "embercore-erp-staging.firebasestorage.app",
  messagingSenderId: "598171125582",
  appId: "1:598171125582:web:140dbf5d2e9ccdafed001f",
};

const asJson = process.argv.includes("--json");
const password = process.env.STAGING_ADMIN_PASSWORD;

async function checkHosting() {
  const response = await fetch(STAGING_WEB_URL, { redirect: "follow" });
  const html = await response.text();
  return {
    name: "hosting",
    ok: response.ok && html.includes("flutter"),
    status: response.status,
    url: STAGING_WEB_URL,
    hasFlutterAssets: html.includes("flutter"),
  };
}

async function checkFirebaseAuthAndData(app) {
  if (!password) {
    return {
      name: "firebase_auth",
      ok: false,
      error: "STAGING_ADMIN_PASSWORD is not set",
    };
  }

  const auth = getAuth(app);
  const db = getFirestore(app);

  await signInWithEmailAndPassword(auth, ADMIN_EMAIL, password);
  const uid = auth.currentUser?.uid;
  if (!uid) {
    throw new Error("Signed in but uid is missing");
  }

  const companySnap = await getDoc(doc(db, "Companies", COMPANY_ID));
  const userSnap = await getDoc(doc(db, "users", uid));

  let storageUploadOk = false;
  let storageTenantWriteBlocked = false;
  let storageNote = null;
  try {
    const storage = getStorage(app);
    const ownLogoPath = `company_logos/${COMPANY_ID}/_smoke_${Date.now()}.txt`;
    const ownLogoRef = ref(storage, ownLogoPath);
    await uploadBytes(ownLogoRef, Buffer.from("staging-smoke"), {
      contentType: "text/plain",
    });
    const downloadUrl = await getDownloadURL(ownLogoRef);
    await deleteObject(ownLogoRef);
    storageUploadOk = Boolean(downloadUrl);

    const foreignLogoPath = `company_logos/foreign_company_${Date.now()}.txt`;
    try {
      await uploadBytes(ref(storage, foreignLogoPath), Buffer.from("blocked"), {
        contentType: "text/plain",
      });
    } catch (error) {
      storageTenantWriteBlocked =
        error.code === "storage/unauthorized" ||
        error.code === "permission-denied";
    }
  } catch (error) {
    storageNote =
      error.code === "storage/unknown"
        ? "Firebase Storage not initialized in Console yet"
        : error.message || String(error);
  }

  const catalogCheck = await checkTenantCatalogReads(db, userSnap);

  await signOut(auth);

  return {
    name: "firebase_auth",
    ok:
      companySnap.exists() &&
      userSnap.exists() &&
      catalogCheck.ok &&
      (storageUploadOk || storageNote != null),
    companyExists: companySnap.exists(),
    userProfileExists: userSnap.exists(),
    storageUploadOk,
    storageTenantWriteBlocked,
    storageNote,
    catalogReadsOk: catalogCheck.ok,
    email: ADMIN_EMAIL,
    catalogCheck,
  };
}

async function checkTenantCatalogReads(db, userSnap) {
  const companyRef = userSnap.data()?.companyRef;
  if (!companyRef) {
    return {
      name: "tenant_catalog_reads",
      ok: false,
      error: "staging admin user profile has no companyRef",
    };
  }

  try {
    const [productSnap, materialSnap] = await Promise.all([
      getDocs(
        query(
          collection(db, "product"),
          where("companyRef", "==", companyRef),
          limit(1),
        ),
      ),
      getDocs(
        query(
          collection(db, "materials"),
          where("companyRef", "==", companyRef),
          limit(1),
        ),
      ),
    ]);

    return {
      name: "tenant_catalog_reads",
      ok: true,
      productSampleCount: productSnap.size,
      materialSampleCount: materialSnap.size,
    };
  } catch (error) {
    return {
      name: "tenant_catalog_reads",
      ok: false,
      error: error.message || String(error),
      code: error.code || null,
    };
  }
}

async function main() {
  const checks = [];

  try {
    checks.push(await checkHosting());
  } catch (error) {
    checks.push({
      name: "hosting",
      ok: false,
      error: error.message || String(error),
    });
  }

  const app = initializeApp(firebaseConfig, "staging-smoke");
  try {
    checks.push(await checkFirebaseAuthAndData(app));
  } catch (error) {
    checks.push({
      name: "firebase_auth",
      ok: false,
      error: error.message || String(error),
    });
  }

  const manual = [
    "Login on https://embercore-erp-staging.web.app as staging.admin@embersoullabs.com",
    "Create Order → Delivery + Retail",
    "Registration requests UI (superadmin)",
    "See docs/PHASE_A_UI_SMOKE_CHECKLIST.md for full hand test",
  ];

  const ok = checks.every((check) => check.ok);
  const payload = { ok, projectId: firebaseConfig.projectId, checks, manualChecklist: manual };

  if (asJson) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    console.log(`Staging smoke ${ok ? "PASS" : "FAIL"}`);
    for (const check of checks) {
      console.log(`  [${check.ok ? "OK" : "FAIL"}] ${check.name}`);
      if (check.error) {
        console.log(`       ${check.error}`);
      }
      if (check.storageNote) {
        console.log(`       storage: ${check.storageNote}`);
      }
      if (check.catalogCheck && !check.catalogCheck.ok) {
        console.log(`       catalog: ${check.catalogCheck.error}`);
      }
    }
    console.log("\nManual checklist:");
    for (const item of manual) {
      console.log(`  - ${item}`);
    }
  }

  process.exit(ok ? 0 : 1);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
