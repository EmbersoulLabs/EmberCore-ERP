/**
 * Cloud Storage security rules tests (claims-based; no Firestore bridge).
 *
 * Run: npm run test:storage-rules (from firebase/)
 */
require("firebase/compat/app");
require("firebase/compat/firestore");
require("firebase/compat/storage");

const fs = require("fs");
const path = require("path");
const { describe, it, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "demo-tfg-vday-storage";
const STORAGE_RULES = fs.readFileSync(
  path.resolve(__dirname, "../storage.rules"),
  "utf8",
);
const BUCKET = `gs://${PROJECT_ID}.appspot.com`;

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: { rules: STORAGE_RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

function staffContext(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, {
    sub: uid,
    ...claims,
  });
}

function storageRef(uid, objectPath, claims) {
  const ctx = uid
    ? staffContext(uid, claims)
    : testEnv.unauthenticatedContext();
  return ctx.storage(BUCKET).ref(objectPath);
}

function uploadBytes(storageReference, bytes) {
  return storageReference.put(bytes, { contentType: "image/jpeg" });
}

describe("storage rules (claims-based)", () => {
  it("allows only the owning tenant to read delivery proof", async () => {
    const objectPath =
      "tenant_media/companyA/delivery_proof_images/orderA/proof.jpg";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
      await context.storage(BUCKET).ref(objectPath).put(bytes, {
        contentType: "image/jpeg",
      });
    });
    await assertSucceeds(
      storageRef("staffA", objectPath, {
        role: "florist",
        companyId: "companyA",
      }).getDownloadURL(),
    );
    await assertFails(storageRef(null, objectPath).getDownloadURL());
    await assertFails(
      storageRef("staffB", objectPath, {
        role: "florist",
        companyId: "companyB",
      }).getDownloadURL(),
    );
  });

  it("denies unauthenticated write to delivery proof path", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          null,
          "tenant_media/companyA/delivery_proof_images/orderA/proof.jpg",
        ),
        bytes,
      ),
    );
  });

  it("denies authenticated write without staff role claims", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "unknownUser",
          "tenant_media/companyA/delivery_proof_images/orderA/proof.jpg",
        ),
        bytes,
      ),
    );
  });

  it("allows account staff to upload invoice payment proof (tenant path)", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertSucceeds(
      uploadBytes(
        storageRef(
          "accountUser",
          "invoice_payment_proof_images/companyA/inv1/proof.jpg",
          { role: "account", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("denies account staff invoice proof for another company", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "accountUser",
          "invoice_payment_proof_images/companyB/inv1/proof.jpg",
          { role: "account", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("allows florist staff to upload product image", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertSucceeds(
      uploadBytes(
        storageRef(
          "floristUser",
          "tenant_media/companyA/product_images/product123/photo.jpg",
          { role: "florist", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("denies florist product image write for another tenant", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "floristUser",
          "tenant_media/companyB/product_images/product123/photo.jpg",
          { role: "florist", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("allows driver with assigned order claim to upload delivery proof", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertSucceeds(
      uploadBytes(
        storageRef(
          "driverUser",
          "tenant_media/companyA/delivery_proof_images/orderA/proof.jpg",
          {
            role: "driver",
            companyId: "companyA",
            assignedOrderIds: ["orderA"],
          },
        ),
        bytes,
      ),
    );
  });

  it("denies driver without assigned order claim", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "driverUser",
          "tenant_media/companyA/delivery_proof_images/orderB/proof.jpg",
          {
            role: "driver",
            companyId: "companyA",
            assignedOrderIds: ["orderA"],
          },
        ),
        bytes,
      ),
    );
  });

  it("denies driver delivery proof write for another tenant", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "driverUser",
          "tenant_media/companyB/delivery_proof_images/orderA/proof.jpg",
          {
            role: "driver",
            companyId: "companyA",
            assignedOrderIds: ["orderA"],
          },
        ),
        bytes,
      ),
    );
  });

  it("denies all access to legacy unscoped sensitive media", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    const legacyPath = "delivery_proof_images/orderA/proof.jpg";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.storage(BUCKET).ref(legacyPath).put(bytes, {
        contentType: "image/jpeg",
      });
    });
    await assertFails(
      storageRef("staffA", legacyPath, {
        role: "florist",
        companyId: "companyA",
      }).getDownloadURL(),
    );
    await assertFails(
      uploadBytes(
        storageRef("staffA", "product_images/product123/photo.jpg", {
          role: "florist",
          companyId: "companyA",
        }),
        bytes,
      ),
    );
  });

  it("allows user-scoped write under users/{uid}/", async () => {
    const bytes = new Uint8Array([0x01, 0x02]);
    await assertSucceeds(
      uploadBytes(storageRef("userA", "users/userA/avatar.jpg"), bytes),
    );
  });

  it("denies write to unknown top-level path", async () => {
    const bytes = new Uint8Array([0x01, 0x02]);
    await assertFails(
      uploadBytes(storageRef("userA", "random_bucket_path/file.bin"), bytes),
    );
  });
});
