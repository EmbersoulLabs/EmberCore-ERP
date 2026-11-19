const functions = require("firebase-functions");
const { verifyShopifyWebhookHmac } = require("./verify_hmac");
const { classifyShopifyWebhookTopic } = require("./topics");
const { ingestShopifyPaidOrder } = require("./ingest_paid_order");

function rawBodyBuffer(req) {
  if (Buffer.isBuffer(req.rawBody)) {
    return req.rawBody;
  }
  if (typeof req.rawBody === "string") {
    return Buffer.from(req.rawBody, "utf8");
  }
  if (req.body == null) {
    return Buffer.alloc(0);
  }
  return Buffer.from(
    typeof req.body === "string" ? req.body : JSON.stringify(req.body),
    "utf8",
  );
}

/**
 * Legacy stable public endpoint handler for shopifyOrderCreated.
 * Production Shopify topic authority: orders/paid.
 * The exported Cloud Function name is URL identity, not the topic.
 */
async function handleShopifyPaidWebhook(req, res, { secret, companyId, db }) {
  if (req.method !== "POST") {
    res.set("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed" });
  }

  if (!secret) {
    functions.logger.error("SHOPIFY_WEBHOOK_SECRET is not configured");
    return res.status(500).json({ error: "Webhook secret not configured" });
  }
  if (!companyId) {
    functions.logger.error("SHOPIFY_DEFAULT_COMPANY_ID is not configured");
    return res.status(500).json({ error: "Company id not configured" });
  }

  const hmacHeader = req.get("x-shopify-hmac-sha256");
  const rawBody = rawBodyBuffer(req);
  if (!verifyShopifyWebhookHmac(rawBody, hmacHeader, secret)) {
    functions.logger.warn("Shopify HMAC verification failed");
    return res.status(401).json({ error: "Invalid webhook signature" });
  }

  const topicDecision = classifyShopifyWebhookTopic(req.get("x-shopify-topic"));
  if (topicDecision.action !== "ingest") {
    functions.logger.info("Shopify webhook ignored", {
      topic: topicDecision.topic,
      reason: topicDecision.reason,
    });
    return res.status(200).json({
      ok: true,
      ignored: true,
      topic: topicDecision.topic,
      reason: topicDecision.reason,
    });
  }

  let shopifyOrder;
  try {
    shopifyOrder = JSON.parse(rawBody.toString("utf8"));
  } catch (error) {
    functions.logger.error("Invalid JSON body", error);
    return res.status(400).json({ error: "Invalid JSON body" });
  }

  if (!shopifyOrder?.id) {
    return res.status(400).json({ error: "Missing Shopify order id" });
  }

  try {
    const result = await ingestShopifyPaidOrder(db, shopifyOrder, companyId, {
      topic: topicDecision.topic,
    });
    functions.logger.info("Shopify paid order staged for review", {
      duplicate: result.duplicate,
      alreadyApproved: result.alreadyApproved,
      shopifyOrderId: result.shopifyOrderId,
      reviewId: result.reviewId,
      reviewStatus: result.reviewStatus,
    });
    return res.status(200).json({
      ok: true,
      duplicate: result.duplicate,
      alreadyApproved: Boolean(result.alreadyApproved),
      reviewId: result.reviewId,
      shopifyOrderId: result.shopifyOrderId,
      shopifyOrderName: result.shopifyOrderName,
      reviewStatus: result.reviewStatus,
      officialOrderId: result.officialOrderId,
      noticesCreated: result.noticesCreated ?? 0,
    });
  } catch (error) {
    if (
      error.code === "trial-limit" ||
      error.code === "plan-module" ||
      error.code === "plan-quota" ||
      error.code === "subscription-inactive"
    ) {
      functions.logger.warn("Shopify ingest blocked by plan or trial limit");
      return res.status(200).json({
        ok: false,
        limited: true,
        error: error.message,
      });
    }
    functions.logger.error("Shopify paid ingest failed", error);
    return res.status(500).json({ error: "Ingest failed" });
  }
}

module.exports = {
  rawBodyBuffer,
  handleShopifyPaidWebhook,
};
