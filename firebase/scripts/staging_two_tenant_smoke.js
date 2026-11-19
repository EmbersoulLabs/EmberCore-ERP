#!/usr/bin/env node
/**
 * Destructive-to-test-data-only two-tenant smoke test for EmberCore staging.
 *
 * Creates uniquely named temporary Auth users, company/profile/order documents,
 * and tenant media. It verifies allow/deny decisions through the client SDK and
 * removes every test resource in a finally block.
 */
const { randomUUID } = require("node:crypto");
const admin = require("firebase-admin");
const { initializeApp, deleteApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, signOut } = require("firebase/auth");
const {
  getFirestore,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
} = require("firebase/firestore");
const {
  getStorage,
  ref,
  uploadBytes,
  getBytes,
  deleteObject,
} = require("firebase/storage");
const { initializeAdmin } = require("./admin_init");
const { loadWebClientConfig } = require("./load_web_client_config");

const PROJECT_ID = "embercore-erp-staging";
const runId = `closure_${Date.now()}_${randomUUID().slice(0, 8)}`;
const password = `Ec!${randomUUID()}aA1`;
const ids = {
  companyA: `${runId}_a`,
  companyB: `${runId}_b`,
  orderA: `${runId}_order_a`,
  orderB: `${runId}_order_b`,
  productA: `${runId}_product_a`,
};
const storagePaths = {
  own: `tenant_media/${ids.companyA}/product_images/${ids.productA}/smoke.png`,
  foreign: `tenant_media/${ids.companyB}/product_images/${runId}_product_b/smoke.png`,
};

function denied(error) {
  const code = error?.code || "";
  const message = error?.message || String(error);
  return code.includes("permission-denied") ||
    code.includes("unauthorized") ||
    message.toLowerCase().includes("permission");
}

async function expectDenied(name, operation, checks) {
  try {
    await operation();
    checks.push({ name, ok: false, detail: "operation unexpectedly succeeded" });
  } catch (error) {
    checks.push({
      name,
      ok: denied(error),
      detail: denied(error) ? error.code || "permission denied" : error.message,
    });
  }
}

async function main() {
  initializeAdmin(PROJECT_ID);
  const adminDb = admin.firestore();
  const adminAuth = admin.auth();
  const bucket = admin.storage().bucket(`${PROJECT_ID}.firebasestorage.app`);
  const companyARef = adminDb.doc(`Companies/${ids.companyA}`);
  const companyBRef = adminDb.doc(`Companies/${ids.companyB}`);
  const cleanupDocs = [];
  const cleanupUsers = [];
  const apps = [];
  const checks = [];

  try {
    const users = await Promise.all(["a", "b"].map(async (suffix) => {
      const companyId = ids[`company${suffix.toUpperCase()}`];
      const user = await adminAuth.createUser({
        email: `${runId}.${suffix}@example.invalid`,
        password,
        emailVerified: true,
      });
      cleanupUsers.push(user.uid);
      await adminAuth.setCustomUserClaims(user.uid, { role: "admin", companyId });
      return user;
    }));

    const seed = [
      [companyARef, { Company_name: "Closure Tenant A", is_active: true }],
      [companyBRef, { Company_name: "Closure Tenant B", is_active: true }],
      [adminDb.doc(`users/${users[0].uid}`), {
        email: users[0].email,
        role: "admin",
        companyRef: companyARef,
        trial_enforced: false,
      }],
      [adminDb.doc(`users/${users[1].uid}`), {
        email: users[1].email,
        role: "admin",
        companyRef: companyBRef,
        trial_enforced: false,
      }],
      [adminDb.doc(`orders/${ids.orderA}`), {
        Order_Id: ids.orderA,
        status: "pending",
        orderstatus: "pending",
        companyRef: companyARef,
      }],
      [adminDb.doc(`orders/${ids.orderB}`), {
        Order_Id: ids.orderB,
        status: "pending",
        orderstatus: "pending",
        companyRef: companyBRef,
      }],
    ];
    const batch = adminDb.batch();
    for (const [reference, data] of seed) {
      batch.set(reference, data);
      cleanupDocs.push(reference);
    }
    await batch.commit();
    await bucket.file(storagePaths.foreign).save(Buffer.from([137, 80, 78, 71]), {
      contentType: "image/png",
    });

    const config = loadWebClientConfig("staging");
    const appA = initializeApp(config, `${runId}-a`);
    apps.push(appA);
    const authA = getAuth(appA);
    await signInWithEmailAndPassword(authA, users[0].email, password);
    await authA.currentUser.getIdToken(true);
    const dbA = getFirestore(appA);
    const storageA = getStorage(appA);

    const ownOrder = await getDoc(doc(dbA, "orders", ids.orderA));
    checks.push({ name: "firestore_read_own_tenant", ok: ownOrder.exists() });
    await expectDenied(
      "firestore_read_cross_tenant",
      () => getDoc(doc(dbA, "orders", ids.orderB)),
      checks,
    );

    const ownProductRef = doc(dbA, "product", ids.productA);
    await setDoc(ownProductRef, {
      name: "Closure Smoke Product",
      price: 1,
      image: "",
      companyRef: doc(dbA, "Companies", ids.companyA),
    });
    cleanupDocs.push(adminDb.doc(`product/${ids.productA}`));
    checks.push({ name: "firestore_write_own_tenant", ok: true });
    await expectDenied(
      "firestore_write_cross_tenant",
      () => setDoc(doc(dbA, "product", `${runId}_foreign_write`), {
        name: "Blocked",
        price: 1,
        image: "",
        companyRef: doc(dbA, "Companies", ids.companyB),
      }),
      checks,
    );
    await expectDenied(
      "firestore_update_cross_tenant",
      () => updateDoc(doc(dbA, "orders", ids.orderB), { status: "completed" }),
      checks,
    );
    await expectDenied(
      "firestore_delete_cross_tenant",
      () => deleteDoc(doc(dbA, "orders", ids.orderB)),
      checks,
    );
    await expectDenied(
      "firestore_enumerate_cross_tenant",
      () => getDocs(query(
        collection(dbA, "orders"),
        where("companyRef", "==", doc(dbA, "Companies", ids.companyB)),
      )),
      checks,
    );

    const clientOrderRef = doc(dbA, "orders", `${runId}_client_order`);
    await setDoc(clientOrderRef, {
      Order_Id: `${runId}_client_order`,
      status: "pending",
      orderstatus: "pending",
      companyRef: doc(dbA, "Companies", ids.companyA),
    });
    cleanupDocs.push(adminDb.doc(`orders/${runId}_client_order`));
    checks.push({ name: "existing_order_create_compatible", ok: true });

    const ownMedia = ref(storageA, storagePaths.own);
    await uploadBytes(ownMedia, Buffer.from([137, 80, 78, 71]), {
      contentType: "image/png",
    });
    await getBytes(ownMedia);
    checks.push({ name: "storage_read_write_own_tenant", ok: true });
    await expectDenied(
      "storage_read_cross_tenant",
      () => getBytes(ref(storageA, storagePaths.foreign)),
      checks,
    );
    await expectDenied(
      "storage_write_cross_tenant",
      () => uploadBytes(ref(storageA, storagePaths.foreign), Buffer.from([1]), {
        contentType: "image/png",
      }),
      checks,
    );
    await expectDenied(
      "storage_delete_cross_tenant",
      () => deleteObject(ref(storageA, storagePaths.foreign)),
      checks,
    );
    await signOut(authA);

    const ok = checks.every((check) => check.ok);
    console.log(JSON.stringify({ ok, projectId: PROJECT_ID, runId, checks }, null, 2));
    process.exitCode = ok ? 0 : 1;
  } finally {
    await Promise.allSettled(apps.map((app) => deleteApp(app)));
    await Promise.allSettled([
      bucket.file(storagePaths.own).delete({ ignoreNotFound: true }),
      bucket.file(storagePaths.foreign).delete({ ignoreNotFound: true }),
    ]);
    if (cleanupDocs.length) {
      const cleanup = adminDb.batch();
      for (const reference of cleanupDocs) cleanup.delete(reference);
      await cleanup.commit();
    }
    await Promise.allSettled(cleanupUsers.map((uid) => adminAuth.deleteUser(uid)));
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || error);
  process.exitCode = 1;
});
