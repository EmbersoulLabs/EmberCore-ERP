/**
 * Deterministic Shopify SKU reconstruction used by the existing CSV exporter.
 * Not title matching. Identity is handle + variant/product id.
 */
function shopifyExportSku(handle, productId, variantId) {
  let raw = String(handle || "")
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  if (!raw) {
    raw = `SHOPIFY-${productId || ""}`;
  }
  if (raw.length > 40) {
    raw = raw.slice(0, 40).replace(/-+$/g, "");
  }
  const suffix = String(variantId || productId || "").slice(-6);
  return `${raw}-${suffix}`;
}

function skuKey(value) {
  return String(value || "").trim().toLowerCase();
}

module.exports = {
  shopifyExportSku,
  skuKey,
};
