const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  shopifyExportSku,
  skuKey,
} = require("../scripts/shopify_product_sku");

describe("shopifyExportSku", () => {
  it("matches the existing CSV exporter formula", () => {
    assert.equal(
      shopifyExportSku(
        "graceful-sympathy-condolence-flower-stand",
        "8738068922567",
        "46677869560007",
      ),
      "GRACEFUL-SYMPATHY-CONDOLENCE-FLOWER-STAN-560007",
    );
    assert.equal(
      shopifyExportSku(
        "bush-romance-lily-tulip-roses-mixed-flower-bouquet",
        "8805734121671",
        "46860717621447",
      ),
      "BUSH-ROMANCE-LILY-TULIP-ROSES-MIXED-FLOW-621447",
    );
  });

  it("skuKey is case-insensitive", () => {
    assert.equal(skuKey("QX-01"), skuKey("qx-01"));
  });
});
