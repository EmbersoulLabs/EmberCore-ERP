/**
 * Durable Shopify identity + review document keys.
 *
 * Ember Core `Order_Id` remains the ERP business number (e.g. TFG-AUG26-0001).
 * Shopify payload.id is stored separately as shopifyOrderId / externalOrderId.
 */

const SOURCE_SHOPIFY = "shopify";
const REVIEWS_COLLECTION = "shopify_reviews";

function normalizeShopifyOrderId(raw) {
  const value = String(raw ?? "").trim();
  if (!value) {
    return "";
  }
  const gid = value.match(/gid:\/\/shopify\/Order\/(\d+)/i);
  if (gid) {
    return gid[1];
  }
  return value;
}

function shopifyReviewDocId(companyId, shopifyOrderId) {
  const company = String(companyId || "").trim();
  const orderId = normalizeShopifyOrderId(shopifyOrderId);
  if (!company || !orderId) {
    throw new Error("companyId and shopifyOrderId are required");
  }
  return `${company}_${orderId}`;
}

function pickShopifyOrderName(shopifyOrder, shopifyOrderId) {
  if (shopifyOrder?.name) {
    return String(shopifyOrder.name);
  }
  if (shopifyOrder?.order_number != null && shopifyOrder.order_number !== "") {
    return `#${shopifyOrder.order_number}`;
  }
  return shopifyOrderId ? `#${shopifyOrderId}` : "";
}

function pickShopifyOrderNumber(shopifyOrder) {
  if (shopifyOrder?.order_number == null || shopifyOrder.order_number === "") {
    return null;
  }
  const parsed = Number(shopifyOrder.order_number);
  return Number.isFinite(parsed) ? parsed : null;
}

function shopifyOfficialOrderQuery(db, companyRef, shopifyOrderId) {
  return db
    .collection("orders")
    .where("source", "==", SOURCE_SHOPIFY)
    .where("externalOrderId", "==", String(shopifyOrderId))
    .where("companyRef", "==", companyRef)
    .limit(1);
}

module.exports = {
  SOURCE_SHOPIFY,
  REVIEWS_COLLECTION,
  normalizeShopifyOrderId,
  shopifyReviewDocId,
  pickShopifyOrderName,
  pickShopifyOrderNumber,
  shopifyOfficialOrderQuery,
};
