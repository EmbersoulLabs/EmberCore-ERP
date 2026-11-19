const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  pickCustomerName,
  pickSenderName,
  pickRecipientName,
  formatShippingAddress,
  formatShopifyBillingBlock,
  resolveOrderType,
  lineItemSummary,
  mapShopifyReviewLineItems,
  mapShopifyShippingLines,
  buildShopifyNoticeMessage,
  isActiveStaffRecipient,
  recipientMatchesNoticeCompany,
  staffNoticeRecipientRef,
} = require("./map_order");
const { extractShopifyFulfillmentDetails, extractSingaporePostal } = require("./fulfillment_attributes");
const {
  enrichReviewLineItemsWithImages,
  loadProductImageCatalog,
  indexProductImageCatalog,
} = require("./line_item_image");
const {
  SOURCE_SHOPIFY,
  REVIEWS_COLLECTION,
  normalizeShopifyOrderId,
  shopifyReviewDocId,
  pickShopifyOrderName,
  pickShopifyOrderNumber,
  shopifyOfficialOrderQuery,
} = require("./review_identity");
const {
  resolvePaidReviewStatus,
  REVIEW_STATUS,
  isApprovedReviewStatus,
} = require("./review_status");
const { SHOPIFY_TOPIC_ORDERS_PAID } = require("./topics");
const { assertCompanyModule } = require("../plan_entitlements");

const REVIEW_NOTICE_TYPE = "shopify_review_pending";
const REVIEW_NOTICE_NAV_TARGET = "shopify_review";
const REVIEW_AUDIT_ACTION = "shopify_review_received";

function parseShopifyDate(value) {
  if (!value) {
    return null;
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return Timestamp.fromDate(date);
}

async function loadNoticeRecipients(db, companyRef) {
  const companyId = companyRef.id;
  const snap = await db.collection("users").get();
  return snap.docs.filter((doc) => {
    const data = doc.data();
    if (!isActiveStaffRecipient(data)) {
      return false;
    }
    return recipientMatchesNoticeCompany(data, companyId);
  });
}

function firstNonEmpty(...values) {
  for (const value of values) {
    const text = value == null ? "" : String(value).trim();
    if (text) {
      return text;
    }
  }
  return "";
}

function buildShopifyReviewData(shopifyOrder, {
  companyId,
  companyRef,
  topic = SHOPIFY_TOPIC_ORDERS_PAID,
  now = FieldValue.serverTimestamp(),
  productCatalog = null,
}) {
  const shopifyOrderId = normalizeShopifyOrderId(shopifyOrder.id);
  const shopifyOrderName = pickShopifyOrderName(shopifyOrder, shopifyOrderId);
  const shopifyOrderNumber = pickShopifyOrderNumber(shopifyOrder);
  const shipping = shopifyOrder.shipping_address || {};
  const billing = shopifyOrder.billing_address || {};
  let lineItems = mapShopifyReviewLineItems(shopifyOrder.line_items || []);
  try {
    lineItems = enrichReviewLineItemsWithImages(lineItems, productCatalog);
  } catch (_) {
    // Image enrichment is optional. Review Gate still admits the paid order.
  }
  lineItems = [
    ...lineItems,
    ...mapShopifyShippingLines(shopifyOrder, lineItems),
  ];
  const totalPrice = Number(shopifyOrder.total_price || 0);
  const paidDecision = resolvePaidReviewStatus(shopifyOrder.financial_status);
  const fulfillment = extractShopifyFulfillmentDetails(shopifyOrder);
  const nativeShipping = formatShippingAddress(shipping);
  const nativeBilling = formatShippingAddress(billing);
  const shippingAddress = nativeShipping || fulfillment.propertyAddress || "";
  const senderPhone = firstNonEmpty(
    fulfillment.senderPhone,
    shopifyOrder.phone,
    shopifyOrder.customer?.phone,
    billing.phone,
  );
  const billingAddress = nativeBilling
    ? formatShopifyBillingBlock({
        senderName: pickSenderName(shopifyOrder),
        senderPhone,
        address: nativeBilling,
      })
    : "";
  const postalCode = firstNonEmpty(
    shipping.zip,
    extractSingaporePostal(shippingAddress),
  );
  const recipientPhone = firstNonEmpty(
    fulfillment.recipientPhone,
    shipping.phone,
  );
  const phone = firstNonEmpty(senderPhone, recipientPhone, billing.phone);

  return {
    companyId,
    companyRef,
    source: SOURCE_SHOPIFY,
    shopifyOrderId,
    shopifyOrderName,
    shopifyOrderNumber,
    financialStatus: paidDecision.financialStatus,
    currency: shopifyOrder.currency ? String(shopifyOrder.currency) : "",
    totalPrice,
    customerName: pickCustomerName(shopifyOrder),
    recipientName: pickRecipientName(shopifyOrder, fulfillment.recipientName),
    shippingAddress,
    billingAddress,
    region: firstNonEmpty(shipping.province, shipping.city),
    postalCode,
    phone,
    senderPhone,
    recipientPhone,
    notes: shopifyOrder.note || "",
    remarks: fulfillment.remarks || "",
    addons: fulfillment.addons,
    deliveryMethod: fulfillment.deliveryMethod || "",
    cardMessage: fulfillment.cardMessage || "",
    deliveryDate: fulfillment.deliveryDate,
    deliveryTimeSlot: fulfillment.deliveryTimeSlot || "",
    orderType: resolveOrderType(shopifyOrder, fulfillment),
    lineItems,
    itemSummary: lineItemSummary(shopifyOrder.line_items || []),
    createdAtShopify: parseShopifyDate(shopifyOrder.created_at),
    paidAt:
      parseShopifyDate(shopifyOrder.processed_at) ||
      parseShopifyDate(shopifyOrder.updated_at),
    receivedAt: now,
    reviewStatus: paidDecision.reviewStatus,
    quarantineReason: paidDecision.quarantineReason,
    topic,
    approvedAt: null,
    approvedBy: null,
    approvedByName: null,
    officialOrderId: null,
    officialOrderRef: null,
  };
}

async function writeReviewReceivedNotices(db, {
  companyRef,
  companyId,
  reviewRef,
  reviewData,
}) {
  const recipients = await loadNoticeRecipients(db, companyRef);
  if (recipients.length === 0) {
    return 0;
  }
  const now = FieldValue.serverTimestamp();
  const noticeMessage = buildShopifyNoticeMessage({
    externalOrderName: reviewData.shopifyOrderName,
    customerName: reviewData.customerName,
    totalAmount: Number(reviewData.totalPrice || 0).toFixed(2),
  });
  const batch = db.batch();
  for (const recipient of recipients) {
    const noticeRef = db.collection("staff_notices").doc();
    batch.set(noticeRef, {
      type: REVIEW_NOTICE_TYPE,
      recipient_user_ref: staffNoticeRecipientRef(db, recipient),
      order_ref: null,
      order_id: reviewData.shopifyOrderName,
      nav_target: REVIEW_NOTICE_NAV_TARGET,
      delivery_date: Timestamp.now(),
      item_summary: reviewData.itemSummary || "",
      message: noticeMessage,
      created_time: now,
      companyRef,
    });
  }
  const auditRef = db.collection("audit_logs").doc();
  batch.set(auditRef, {
    userId: "shopify_webhook",
    userName: "Shopify Webhook",
    userRole: "system",
    action: REVIEW_AUDIT_ACTION,
    entityType: "shopify_review",
    entityId: reviewRef.id,
    entityLabel: reviewData.shopifyOrderName,
    description: "Shopify paid order received for review",
    companyId,
    companyRef,
    newValue: {
      shopifyOrderId: reviewData.shopifyOrderId,
      shopifyOrderName: reviewData.shopifyOrderName,
      reviewStatus: reviewData.reviewStatus,
    },
    createdAt: now,
    created_at: now,
  });
  await batch.commit();
  return recipients.length;
}

/**
 * Persist a paid Shopify order as a review item. Never creates an official order.
 * Idempotent on (companyId, shopifyOrderId) via deterministic document id.
 */
async function ingestShopifyPaidOrder(db, shopifyOrder, companyId, {
  topic = SHOPIFY_TOPIC_ORDERS_PAID,
} = {}) {
  const companyRef = db.collection("Companies").doc(companyId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    throw new Error(`Companies/${companyId} does not exist`);
  }
  assertCompanyModule(companySnap.data(), "shopifyImport");

  const shopifyOrderId = normalizeShopifyOrderId(shopifyOrder?.id);
  if (!shopifyOrderId) {
    const error = new Error("Missing Shopify order id");
    error.code = "invalid-argument";
    throw error;
  }

  let productCatalog = indexProductImageCatalog([]);
  try {
    productCatalog = await loadProductImageCatalog(db, companyRef);
  } catch (_) {
    productCatalog = indexProductImageCatalog([]);
  }

  const reviewRef = db
    .collection(REVIEWS_COLLECTION)
    .doc(shopifyReviewDocId(companyId, shopifyOrderId));

  const result = await db.runTransaction(async (tx) => {
    const existingReview = await tx.get(reviewRef);
    if (existingReview.exists) {
      const data = existingReview.data() || {};
      if (isApprovedReviewStatus(data.reviewStatus)) {
        return {
          duplicate: true,
          alreadyApproved: true,
          reviewRef,
          reviewId: reviewRef.id,
          shopifyOrderId,
          shopifyOrderName:
            data.shopifyOrderName || pickShopifyOrderName(shopifyOrder, shopifyOrderId),
          reviewStatus: REVIEW_STATUS.APPROVED,
          officialOrderId: data.officialOrderId || null,
          officialOrderPath: data.officialOrderRef?.path || null,
          noticesCreated: 0,
        };
      }

      const reviewData = buildShopifyReviewData(shopifyOrder, {
        companyId,
        companyRef,
        topic,
        productCatalog,
      });
      const wasPending = data.reviewStatus === REVIEW_STATUS.PENDING_REVIEW;
      tx.set(reviewRef, {
        ...reviewData,
        receivedAt: data.receivedAt || reviewData.receivedAt,
        approvedAt: data.approvedAt || null,
        approvedBy: data.approvedBy || null,
        approvedByName: data.approvedByName || null,
        officialOrderId: data.officialOrderId || null,
        officialOrderRef: data.officialOrderRef || null,
      });
      return {
        duplicate: true,
        alreadyApproved: false,
        refreshed: true,
        shouldNotify: !wasPending,
        reviewRef,
        reviewId: reviewRef.id,
        shopifyOrderId,
        shopifyOrderName: reviewData.shopifyOrderName,
        reviewStatus: REVIEW_STATUS.PENDING_REVIEW,
        officialOrderId: data.officialOrderId || null,
        officialOrderPath: data.officialOrderRef?.path || null,
        noticesCreated: 0,
        reviewData,
      };
    }

    const existingOrders = await tx.get(
      shopifyOfficialOrderQuery(db, companyRef, shopifyOrderId),
    );
    if (!existingOrders.empty) {
      const orderDoc = existingOrders.docs[0];
      const orderData = orderDoc.data() || {};
      return {
        duplicate: true,
        alreadyApproved: true,
        reviewRef,
        reviewId: reviewRef.id,
        shopifyOrderId,
        shopifyOrderName:
          orderData.externalOrderName ||
          pickShopifyOrderName(shopifyOrder, shopifyOrderId),
        reviewStatus: REVIEW_STATUS.APPROVED,
        officialOrderId: orderData.Order_Id || null,
        officialOrderPath: orderDoc.ref.path,
        noticesCreated: 0,
        historicalOfficialOrder: true,
      };
    }

    const reviewData = buildShopifyReviewData(shopifyOrder, {
      companyId,
      companyRef,
      topic,
      productCatalog,
    });
    tx.set(reviewRef, reviewData);
    return {
      duplicate: false,
      alreadyApproved: false,
      reviewRef,
      reviewId: reviewRef.id,
      shopifyOrderId,
      shopifyOrderName: reviewData.shopifyOrderName,
      reviewStatus: reviewData.reviewStatus,
      officialOrderId: null,
      officialOrderPath: null,
      noticesCreated: 0,
      created: true,
      reviewData,
    };
  });

  if (
    result.reviewStatus === REVIEW_STATUS.PENDING_REVIEW &&
    (result.created || result.shouldNotify)
  ) {
    result.noticesCreated = await writeReviewReceivedNotices(db, {
      companyRef,
      companyId,
      reviewRef,
      reviewData: result.reviewData,
    });
  }
  delete result.reviewData;

  return result;
}

module.exports = {
  REVIEW_NOTICE_TYPE,
  REVIEW_NOTICE_NAV_TARGET,
  REVIEW_AUDIT_ACTION,
  buildShopifyReviewData,
  ingestShopifyPaidOrder,
};
