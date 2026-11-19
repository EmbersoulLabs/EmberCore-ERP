const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  IMAGE_SOURCE,
  indexProductImageCatalog,
  resolveShopifyLineItemImage,
  enrichReviewLineItemsWithImages,
  isTrustworthyImageUrl,
} = require("../functions/shopify/line_item_image");

const VARIANT_IMAGE = "https://cdn.shopify.com/variant.jpg";
const PRODUCT_IMAGE = "https://cdn.shopify.com/product.jpg";
const COMPANY_A_SKU_IMAGE = "https://cdn.shopify.com/sku-a.jpg";
const COMPANY_B_IMAGE = "https://cdn.shopify.com/company-b.jpg";

function catalog(products) {
  return indexProductImageCatalog(products);
}

describe("Shopify line item image resolution", () => {
  it("IMAGE-01 exact variant_id uses variant image", () => {
    const resolved = resolveShopifyLineItemImage(
      { variant_id: 111, product_id: 10, sku: "X" },
      catalog([
        {
          sku: "X",
          shopifyVariantId: "111",
          shopifyProductId: "10",
          image: VARIANT_IMAGE,
        },
        {
          sku: "Y",
          shopifyProductId: "10",
          image: PRODUCT_IMAGE,
        },
      ]),
    );
    assert.equal(resolved.imageUrl, VARIANT_IMAGE);
    assert.equal(resolved.imageSource, IMAGE_SOURCE.variant);
  });

  it("IMAGE-02 variant match without image falls back to product image", () => {
    const resolved = resolveShopifyLineItemImage(
      { variant_id: 111, product_id: 10, sku: "X" },
      catalog([
        { sku: "X", shopifyVariantId: "111", shopifyProductId: "10" },
        { sku: "Y", shopifyProductId: "10", image: PRODUCT_IMAGE },
      ]),
    );
    assert.equal(resolved.imageUrl, PRODUCT_IMAGE);
    assert.equal(resolved.imageSource, IMAGE_SOURCE.product);
  });

  it("IMAGE-03 exact product_id match uses product image", () => {
    const resolved = resolveShopifyLineItemImage(
      { product_id: "gid://shopify/Product/10", sku: "other" },
      catalog([
        { sku: "RB-01", shopifyProductId: "10", image: PRODUCT_IMAGE },
      ]),
    );
    assert.equal(resolved.imageUrl, PRODUCT_IMAGE);
    assert.equal(resolved.imageSource, IMAGE_SOURCE.product);
  });

  it("IMAGE-04 no local match returns null and keeps ingestion payload", () => {
    const resolved = resolveShopifyLineItemImage(
      { product_id: 99, variant_id: 98, sku: "NOPE", name: "Rose Box" },
      catalog([
        { sku: "RB-01", shopifyProductId: "10", image: PRODUCT_IMAGE, name: "Rose Box" },
      ]),
    );
    assert.equal(resolved.imageUrl, null);
    assert.equal(resolved.imageSource, IMAGE_SOURCE.none);
  });

  it("IMAGE-05 SKU fallback only when unique in company catalog", () => {
    const unique = resolveShopifyLineItemImage(
      { sku: "RB-01", name: "Other title" },
      catalog([{ sku: "RB-01", image: COMPANY_A_SKU_IMAGE, name: "Rose Box" }]),
    );
    assert.equal(unique.imageUrl, COMPANY_A_SKU_IMAGE);
    assert.equal(unique.imageSource, IMAGE_SOURCE.sku);

    const duplicate = resolveShopifyLineItemImage(
      { sku: "RB-01" },
      catalog([
        { sku: "RB-01", image: COMPANY_A_SKU_IMAGE },
        { sku: "RB-01", image: PRODUCT_IMAGE },
      ]),
    );
    assert.equal(duplicate.imageUrl, null);
    assert.equal(duplicate.imageSource, IMAGE_SOURCE.none);
  });

  it("IMAGE-06 title-only match is never used", () => {
    const resolved = resolveShopifyLineItemImage(
      { name: "Rose Box", title: "Rose Box" },
      catalog([{ sku: "RB-01", name: "Rose Box", image: PRODUCT_IMAGE }]),
    );
    assert.equal(resolved.imageUrl, null);
    assert.equal(resolved.imageSource, IMAGE_SOURCE.none);
  });

  it("IMAGE-07 company B products are not in company A catalog", () => {
    const companyACatalog = catalog([
      { sku: "RB-01", shopifyProductId: "10", image: COMPANY_A_SKU_IMAGE },
    ]);
    const resolved = resolveShopifyLineItemImage(
      { product_id: 77, variant_id: 88, sku: "B-ONLY" },
      companyACatalog,
    );
    assert.equal(resolved.imageUrl, null);
    assert.notEqual(resolved.imageUrl, COMPANY_B_IMAGE);
  });

  it("rejects data/blob URLs", () => {
    assert.equal(isTrustworthyImageUrl("data:image/png;base64,abc"), false);
    assert.equal(isTrustworthyImageUrl("blob:https://x/1"), false);
    const resolved = resolveShopifyLineItemImage(
      { image: "data:image/png;base64,abc" },
      catalog([]),
    );
    assert.equal(resolved.imageUrl, null);
  });

  it("INGEST-04 image resolution exception still returns a line item", () => {
    const throwingCatalog = {
      byVariantId: {
        get() {
          throw new Error("boom");
        },
      },
    };
    const enriched = enrichReviewLineItemsWithImages(
      [{ name: "Rose Box", qty: 1, variantId: "1" }],
      throwingCatalog,
    );
    assert.equal(enriched.length, 1);
    assert.equal(enriched[0].name, "Rose Box");
    assert.equal(enriched[0].imageUrl, null);
  });
});
