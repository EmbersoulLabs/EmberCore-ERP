const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  parseStorefrontWebsite,
  expandRows,
  mapCategory,
  keepInternalProduct,
  namesAlign,
  syncStorefrontCatalog,
} = require("../functions/shopify/sync_storefront_catalog");
const {
  staffCanEditCompanyProfile,
  resolveStaffCompanyId,
} = require("../functions/shopify/staff_auth");
const { FakeFirestore } = require("./fake_firestore");

const COMPANY_A = "companyA";
const COMPANY_B = "companyB";

function jsonResponse(body, ok = true) {
  return {
    ok,
    status: ok ? 200 : 500,
    json: async () => body,
  };
}

function storefrontFetch(productsByPage) {
  return async (url) => {
    const page = Number(new URL(url).searchParams.get("page") || "1");
    return jsonResponse({ products: productsByPage[page - 1] || [] });
  };
}

describe("parseStorefrontWebsite", () => {
  it("normalizes host and origin", () => {
    assert.deepEqual(parseStorefrontWebsite("https://www.theflowerguy.sg/"), {
      host: "www.theflowerguy.sg",
      origin: "https://www.theflowerguy.sg",
      website: "https://www.theflowerguy.sg",
    });
    assert.equal(parseStorefrontWebsite("www.theflowerguy.sg").host, "www.theflowerguy.sg");
    assert.equal(parseStorefrontWebsite(""), null);
    assert.equal(parseStorefrontWebsite("not a url"), null);
  });
});

describe("catalog helpers", () => {
  it("maps funeral and bouquet categories", () => {
    assert.equal(mapCategory({ product_type: "Condolence Stand" }), "Funeral");
    assert.equal(mapCategory({ title: "x", handle: "red-roses-box" }), "Hand Bouquet");
  });

  it("keeps delivery and funeral extras", () => {
    assert.equal(keepInternalProduct({ name: "Delivery", sku: "001" }), true);
    assert.equal(keepInternalProduct({ name: "缴库", category: "Funeral" }), true);
    assert.equal(
      keepInternalProduct({ name: "Purple Hearts", category: "Hand Bouquet" }),
      false,
    );
  });

  it("does not align renamed leftover SKUs", () => {
    assert.equal(
      namesAlign("SS02 - Sympathy Condolence Flower Stand", {
        name: "Empathy 01 - Fresh Flower Condolence Stand",
        title: "Empathy 01 - Fresh Flower Condolence Stand",
      }),
      false,
    );
  });

  it("expands priced variants and skips zero", () => {
    const rows = expandRows(
      [
        {
          id: 1,
          title: "Omakase",
          handle: "omakase",
          variants: [
            { id: 11, option1: "Small", price: "78.00", sku: "OM-S" },
            { id: 12, option1: "Default Title", price: "0.00" },
          ],
        },
      ],
      "www.theflowerguy.sg",
    );
    assert.equal(rows.length, 1);
    assert.equal(rows[0].name, "Omakase - Small");
    assert.equal(rows[0].price, 78);
  });
});

describe("staffCanEditCompanyProfile", () => {
  it("allows admin and denies florist by default", async () => {
    const db = new FakeFirestore();
    const companyRef = db.collection("Companies").doc(COMPANY_A);
    assert.equal(
      await staffCanEditCompanyProfile(db, { data: { role: "admin", companyRef } }),
      true,
    );
    assert.equal(
      await staffCanEditCompanyProfile(db, { data: { role: "florist", companyRef } }),
      false,
    );
  });

  it("blocks cross-company sync for non-superadmin", () => {
    assert.throws(
      () =>
        resolveStaffCompanyId(
          { data: { role: "admin", companyRef: { id: COMPANY_A } } },
          COMPANY_B,
        ),
      /another tenant/,
    );
    assert.equal(
      resolveStaffCompanyId(
        { data: { role: "superadmin", companyRef: { id: COMPANY_A } } },
        COMPANY_B,
      ),
      COMPANY_B,
    );
  });
});

describe("syncStorefrontCatalog", () => {
  it("creates missing, updates price, and deactivates extra retail", async () => {
    const db = new FakeFirestore();
    const companyRef = db.collection("Companies").doc(COMPANY_A);
    await companyRef.set({ Company_name: "TFG", is_active: true });
    await db.collection("product").doc("keep").set({
      name: "Rose Bouquet",
      sku: "RB-01",
      price: 80,
      category: "Hand Bouquet",
      isActive: true,
      companyRef,
    });
    await db.collection("product").doc("extra").set({
      name: "Old Extra Bouquet",
      sku: "OLD-1",
      price: 50,
      category: "Hand Bouquet",
      isActive: true,
      companyRef,
    });
    await db.collection("product").doc("funeral").set({
      name: "缴库",
      sku: "fu",
      price: 600,
      category: "Funeral",
      isActive: true,
      companyRef,
    });

    const result = await syncStorefrontCatalog(db, {
      companyId: COMPANY_A,
      website: "https://www.theflowerguy.sg",
      fetchImpl: storefrontFetch([
        [
          {
            id: 99,
            title: "Rose Bouquet",
            handle: "rose-bouquet",
            product_type: "Hand Bouquet",
            variants: [{ id: 991, option1: "Default Title", price: "98.00", sku: "RB-01" }],
          },
          {
            id: 100,
            title: "New Lily",
            handle: "new-lily",
            product_type: "Hand Bouquet",
            variants: [{ id: 1001, option1: "Default Title", price: "68.00", sku: "NL-01" }],
          },
        ],
      ]),
    });

    assert.equal(result.createdCount, 1);
    assert.equal(result.priceUpdateCount, 1);
    assert.equal(result.deactivatedCount, 1);
    assert.equal(result.created[0].name, "New Lily");
    assert.equal(result.priceUpdates[0].to, 98);
    assert.equal(result.deactivated[0].name, "Old Extra Bouquet");
    assert.equal(result.keptInternal[0].name, "缴库");
    const extra = await db.collection("product").doc("extra").get();
    assert.equal(extra.data().isActive, false);
    const rose = await db.collection("product").doc("keep").get();
    assert.equal(rose.data().price, 98);
    const company = await companyRef.get();
    assert.equal(company.data().website, "https://www.theflowerguy.sg");
  });
});
