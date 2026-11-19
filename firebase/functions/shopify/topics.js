const SHOPIFY_TOPIC_ORDERS_PAID = "orders/paid";
const SHOPIFY_TOPIC_ORDERS_CREATE = "orders/create";

function normalizeShopifyTopic(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase();
}

/**
 * Production ingestion authority is orders/paid.
 * orders/create is accepted only as a no-op so Shopify retries stop after the
 * Admin topic switch; it must not create a review item or official order.
 */
function classifyShopifyWebhookTopic(rawTopic) {
  const topic = normalizeShopifyTopic(rawTopic);
  if (topic === SHOPIFY_TOPIC_ORDERS_PAID) {
    return { topic, action: "ingest" };
  }
  if (topic === SHOPIFY_TOPIC_ORDERS_CREATE) {
    return {
      topic,
      action: "ignore",
      reason: "orders/create is not the production ingestion authority",
    };
  }
  if (!topic) {
    return {
      topic,
      action: "ignore",
      reason: "Missing X-Shopify-Topic",
    };
  }
  return {
    topic,
    action: "ignore",
    reason: `Unsupported Shopify topic: ${topic}`,
  };
}

module.exports = {
  SHOPIFY_TOPIC_ORDERS_PAID,
  SHOPIFY_TOPIC_ORDERS_CREATE,
  normalizeShopifyTopic,
  classifyShopifyWebhookTopic,
};
