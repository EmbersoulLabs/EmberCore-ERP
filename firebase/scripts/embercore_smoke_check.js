#!/usr/bin/env node
/**
 * Post-deploy smoke checks against embercore-erp Firebase + Hosting.
 *
 *   set EMBERCORE_SUPERADMIN_PASSWORD=<password>
 *   node scripts/embercore_smoke_check.js
 *   node scripts/embercore_smoke_check.js --json
 */
const { initializeApp } = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const { getFirestore, doc, getDoc } = require("firebase/firestore");
const {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
  deleteObject,
} = require("firebase/storage");

const WEB_URL = "https://embercore-erp.web.app";
const SUPERADMIN_EMAIL =
  process.env.EMBERCORE_SUPERADMIN_EMAIL || "kahliantoo@gmail.com";
const DIRECTOR_EMAIL =
  process.env.EMBERCORE_DIRECTOR_EMAIL || "demo.director@embersoullabs.com";
const COMPANY_ID = "demo_company";

const firebaseConfig = {
  apiKey: "REDACTED_API_KEY",
  authDomain: "embercore-erp.firebaseapp.com",
  projectId: "embercore-erp",
  storageBucket: "embercore-erp.firebasestorage.app",
  messagingSenderId: "1098308969895",
  appId: "1:1098308969895:web:15747b5faa30917cff8282",
};

const asJson = process.argv.includes("--json");
const superadminPassword = process.env.EMBERCORE_SUPERADMIN_PASSWORD;
const directorPassword = process.env.EMBERCORE_DIRECTOR_PASSWORD;

async function checkHosting() {
  const response = await fetch(WEB_URL, { redirect: "follow" });
  const html = await response.text();
  return {
    name: "hosting",
    ok: response.ok && html.includes("flutter"),
    status: response.status,
    url: WEB_URL,
    hasFlutterAssets: html.includes("flutter"),
  };
}

async function checkRoleAuth(app, email, password, expectedRole) {
  if (!password) {
    return {
      name: `auth_${expectedRole}`,
      ok: false,
      error: `Password not set for ${email}`,
    };
  }

  const auth = getAuth(app);
  const db = getFirestore(app);
  await signInWithEmailAndPassword(auth, email, password);
  const uid = auth.currentUser?.uid;
  if (!uid) {
    throw new Error(`Signed in as ${email} but uid is missing`);
  }

  const userSnap = await getDoc(doc(db, "users", uid));
  const role = userSnap.exists() ? userSnap.data().role : null;
  const ok = role === expectedRole;
  await signOut(auth);
  return {
    name: `auth_${expectedRole}`,
    ok,
    email,
    uid,
    role,
  };
}

async function checkDirectorTenant(app) {
  if (!directorPassword) {
    return {
      name: "director_tenant",
      ok: false,
      error: "EMBERCORE_DIRECTOR_PASSWORD is not set",
    };
  }

  const auth = getAuth(app);
  const db = getFirestore(app);
  await signInWithEmailAndPassword(auth, DIRECTOR_EMAIL, directorPassword);

  const companySnap = await getDoc(doc(db, "Companies", COMPANY_ID));
  let configSnap = null;
  try {
    configSnap = await getDoc(doc(db, "tenant_platform_config", COMPANY_ID));
  } catch (_) {
    configSnap = null;
  }

  let storageOk = false;
  let storageNote = null;
  try {
    const storage = getStorage(app);
    const ownLogoPath = `company_logos/${COMPANY_ID}/_smoke_${Date.now()}.txt`;
    const ownLogoRef = ref(storage, ownLogoPath);
    await uploadBytes(ownLogoRef, Buffer.from("embercore-smoke"), {
      contentType: "text/plain",
    });
    const downloadUrl = await getDownloadURL(ownLogoRef);
    await deleteObject(ownLogoRef);
    storageOk = Boolean(downloadUrl);
  } catch (error) {
    storageNote =
      error.code === "storage/unknown"
        ? "Firebase Storage not initialized in Console yet"
        : error.message || String(error);
  }

  await signOut(auth);

  const firestoreOk =
    companySnap.exists() && companySnap.data()?.is_active !== false;

  return {
    name: "director_tenant",
    ok: firestoreOk,
    companyId: COMPANY_ID,
    hasPlatformConfig: configSnap?.exists() === true,
    storageOk,
    storageNote,
  };
}

async function runCheck(name, fn) {
  try {
    const result = await fn();
    return { ...result, name: result.name || name };
  } catch (error) {
    return {
      name,
      ok: false,
      error: error.message || String(error),
    };
  }
}

async function main() {
  const app = initializeApp(firebaseConfig, "embercore-smoke");
  const checks = [
    await runCheck("hosting", () => checkHosting()),
    await runCheck("auth_superadmin", () =>
      checkRoleAuth(app, SUPERADMIN_EMAIL, superadminPassword, "superadmin"),
    ),
    await runCheck("auth_director", () =>
      checkRoleAuth(app, DIRECTOR_EMAIL, directorPassword, "director"),
    ),
    await runCheck("director_tenant", () => checkDirectorTenant(app)),
  ];

  const ok = checks.every((check) => check.ok);
  const payload = { ok, projectId: firebaseConfig.projectId, checks };
  if (asJson) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    for (const check of checks) {
      console.log(`${check.ok ? "PASS" : "FAIL"} ${check.name}`);
      if (check.error) {
        console.log(`  error: ${check.error}`);
      }
      if (check.storageNote) {
        console.log(`  storage: ${check.storageNote}`);
      }
    }
    console.log(ok ? "\nAll smoke checks passed." : "\nSmoke checks failed.");
  }
  process.exit(ok ? 0 : 1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
