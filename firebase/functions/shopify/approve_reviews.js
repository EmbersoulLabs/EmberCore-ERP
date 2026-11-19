const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { nextDeliveryOrderIdInTransaction } = require("./order_id_helpers");
const { buildMaterialCostSnapshotPatch } = require("./material_cost_snapshot");
const {
  mapReviewLineItemsToOrderItems,
  applySharedCardMessageToEmptyMappedItems,
  syncedOrderCardMessage,
  buildShopifyNoticeMessage,
  isActiveStaffRecipient,
  recipientMatchesNoticeCompany,
  staffNoticeRecipientRef,
} = require("./map_order");
const {
  SOURCE_SHOPIFY,
  REVIEWS_COLLECTION,
  shopifyOfficialOrderQuery,
} = require("./review_identity");
const { REVIEW_STATUS, isActionableReviewStatus } = require("./review_status");
const { assertReviewBelongsToStaff } = require("./staff_auth");
const { assertCompanyModule } = require("../plan_entitlements");

const APPROVE_AUDIT_ACTION = "shopify_review_approved";
const IMPORTED_NOTICE_TYPE = "shopify_order_imported";
const IMPORTED_AUDIT_ACTION = "shopify_order_imported";

function uniqueIds(ids) {
  const seen = new Set();
  const out = [];
  for (const raw of ids || []) {
    const id = String(raw || "").trim();
    if (!id || seen.has(id)) {
      continue;
    }
    seen.add(id);
    out.push(id);
  }
  return out;
}

async function loadCatalogForCompany(db, companyRef) {
  const [materialSnap, productSnap] = await Promise.all([
    db.collection("materials").where("companyRef", "==", companyRef).get(),
    db.collection("product").where("companyRef", "==", companyRef).get(),
  ]);
  const materialsByPath = new Map();
  for (const doc of materialSnap.docs) {
    materialsByPath.set(doc.ref.path, {
      cost: Number(doc.data().cost || 0),
    });
  }
  const products = productSnap.docs.map((doc) => ({
    id: doc.id,
    name: doc.data().name || "",
    recipeLines: doc.data().recipeLines || [],
  }));
  return { materialsByPath, products };
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

async function writeApprovalSideEffects(db, {
  companyId,
  companyRef,
  reviewRef,
  reviewData,
  orderRef,
  erpOrderId,
  staff,
}) {
  const now = FieldValue.serverTimestamp();
  const recipients = await loadNoticeRecipients(db, companyRef);
  const noticeMessage = buildShopifyNoticeMessage({
    externalOrderName: reviewData.shopifyOrderName,
    customerName: reviewData.customerName,
    totalAmount: Number(reviewData.totalPrice || 0).toFixed(2),
  });
  const batch = db.batch();
  for (const recipient of recipients) {
    const noticeRef = db.collection("staff_notices").doc();
    batch.set(noticeRef, {
      type: IMPORTED_NOTICE_TYPE,
      recipient_user_ref: staffNoticeRecipientRef(db, recipient),
      order_ref: orderRef,
      order_id: erpOrderId,
      delivery_date: Timestamp.now(),
      item_summary: reviewData.itemSummary || "",
      message: noticeMessage,
      created_time: now,
      companyRef,
    });
  }
  const auditRef = db.collection("audit_logs").doc();
  batch.set(auditRef, {
    userId: staff.uid,
    userName: staff.name || staff.email || staff.uid,
    userRole: staff.role || "staff",
    action: APPROVE_AUDIT_ACTION,
    entityType: "shopify_review",
    entityId: reviewRef.id,
    entityLabel: reviewData.shopifyOrderName,
    description: "Shopify review approved",
    companyId,
    companyRef,
    newValue: {
      shopifyOrderId: reviewData.shopifyOrderId,
      shopifyOrderName: reviewData.shopifyOrderName,
      officialOrderId: erpOrderId,
      officialOrderPath: orderRef.path,
    },
    createdAt: now,
    created_at: now,
  });
  const importedAuditRef = db.collection("audit_logs").doc();
  batch.set(importedAuditRef, {
    userId: staff.uid,
    userName: staff.name || staff.email || staff.uid,
    userRole: staff.role || "staff",
    action: IMPORTED_AUDIT_ACTION,
    entityType: "order",
    entityId: orderRef.id,
    entityLabel: erpOrderId,
    description: "Shopify Order Imported",
    companyId,
    companyRef,
    newValue: {
      shopifyOrderId: reviewData.shopifyOrderId,
      shopifyOrderName: reviewData.shopifyOrderName,
      shopifyReviewId: reviewRef.id,
      customerName: reviewData.customerName,
      erpOrderId,
    },
    createdAt: now,
    created_at: now,
  });
  await batch.commit();
  return recipients.length;
}

function buildOfficialOrderData(reviewData, {
  erpOrderId,
  orderRef,
  companyRef,
  reviewRef,
  catalog,
  now = FieldValue.serverTimestamp(),
}) {
  const totalAmount = Number(reviewData.totalPrice || 0);
  const lineItems = Array.isArray(reviewData.lineItems) ? reviewData.lineItems : [];
  const totalQty = lineItems.reduce((sum, item) => sum + Number(item.qty || 0), 0);
  const orderType = reviewData.orderType || "Delivery";
  const mappedItems = applySharedCardMessageToEmptyMappedItems(
    mapReviewLineItemsToOrderItems(
      lineItems,
      orderRef,
      companyRef,
      erpOrderId,
    ),
    reviewData.cardMessage || reviewData.notes || "",
  );
  const extras = [];
  for (const addon of Array.isArray(reviewData.addons) ? reviewData.addons : []) {
    const text = String(addon || "").trim();
    if (text) {
      extras.push(`Add-on: ${text}`);
    }
  }
  const remarks = String(reviewData.remarks || "").trim();
  if (remarks) {
    extras.push(remarks);
  }
  if (mappedItems.length && extras.length && !mappedItems[0].Remark) {
    mappedItems[0].Remark = extras.join("\n");
  }
  const deliveryAddress = String(reviewData.shippingAddress || "").trim();
  const billingAddress = String(reviewData.billingAddress || "").trim();
  const senderPhone = String(
    reviewData.senderPhone || reviewData.phone || "",
  ).trim();
  const recipientPhone = String(reviewData.recipientPhone || "").trim();
  const orderData = {
    client_name: reviewData.customerName || "",
    recipient_name: reviewData.recipientName || "",
    address: deliveryAddress,
    billing_address: billingAddress,
    region: reviewData.region || "",
    PostalCode: reviewData.postalCode || "",
    customer_phone_number: senderPhone,
    recipient_phone_number: recipientPhone,
    card_message: syncedOrderCardMessage(
      mappedItems,
      reviewData.cardMessage || reviewData.notes || "",
    ),
    delivery_date: reviewData.deliveryDate || null,
    delivery_time_slot: reviewData.deliveryTimeSlot || "",
    Order_Id: erpOrderId,
    orderType,
    pickup_delivery: orderType,
    paymentType: "Shopify",
    amount_paid: totalAmount,
    total: totalAmount,
    totalAmount,
    totalQty,
    status: "processing",
    orderstatus: "processing",
    companyRef,
    created_time: now,
    source: SOURCE_SHOPIFY,
    externalOrderId: String(reviewData.shopifyOrderId || ""),
    externalOrderName: reviewData.shopifyOrderName || "",
    shopifyOrderId: String(reviewData.shopifyOrderId || ""),
    shopifyOrderName: reviewData.shopifyOrderName || "",
    shopifyReviewId: reviewRef.id,
  };
  if (catalog) {
    Object.assign(
      orderData,
      buildMaterialCostSnapshotPatch({
        orderItems: mappedItems.map((item) => ({
          ...item,
          productRef: item.productRef || null,
        })),
        products: catalog.products,
        materialsByPath: catalog.materialsByPath,
      }),
    );
  }
  return { orderData, mappedItems };
}

function alreadyApprovedResult(reviewRef, reviewData, extra = {}) {
  return {
    reviewId: reviewRef.id,
    shopifyOrderId: reviewData.shopifyOrderId || "",
    shopifyOrderName: reviewData.shopifyOrderName || "",
    officialOrderId: reviewData.officialOrderId || extra.officialOrderId || null,
    officialOrderPath: reviewData.officialOrderRef?.path || extra.officialOrderPath || null,
    alreadyApproved: true,
  };
}

/**
 * Atomically promote one pending Shopify review into an official Ember Core order.
 */
async function approveShopifyReview(db, reviewId, staff) {
  const reviewRef = db.collection(REVIEWS_COLLECTION).doc(String(reviewId));
  const reviewSnapForCompany = await reviewRef.get();
  if (!reviewSnapForCompany.exists) {
    const error = new Error("Shopify review not found");
    error.code = "not-found";
    throw error;
  }
  const preview = reviewSnapForCompany.data() || {};
  assertReviewBelongsToStaff(preview, { data: staff.profile });

  if (preview.reviewStatus === REVIEW_STATUS.APPROVED) {
    return alreadyApprovedResult(reviewRef, preview);
  }
  if (preview.reviewStatus === REVIEW_STATUS.REJECTED) {
    const error = new Error("Rejected Shopify review cannot be approved");
    error.code = "failed-precondition";
    throw error;
  }
  if (!isActionableReviewStatus(preview.reviewStatus)) {
    const error = new Error("Shopify review is not pending");
    error.code = "failed-precondition";
    throw error;
  }

  const companyRef = preview.companyRef;
  if (preview.companyId) {
    const companySnap = await db.collection("Companies").doc(preview.companyId).get();
    if (companySnap.exists) {
      assertCompanyModule(companySnap.data(), "shopifyImport");
    }
  }
  const catalog = companyRef ? await loadCatalogForCompany(db, companyRef) : null;

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(reviewRef);
    if (!snap.exists) {
      const error = new Error("Shopify review not found");
      error.code = "not-found";
      throw error;
    }
    const reviewData = snap.data() || {};
    assertReviewBelongsToStaff(reviewData, { data: staff.profile });

    if (reviewData.reviewStatus === REVIEW_STATUS.APPROVED) {
      return {
        ...alreadyApprovedResult(reviewRef, reviewData),
        skipSideEffects: true,
      };
    }
    if (!isActionableReviewStatus(reviewData.reviewStatus)) {
      const error = new Error("Shopify review is not pending");
      error.code = "failed-precondition";
      throw error;
    }

    const existingOrders = await tx.get(
      shopifyOfficialOrderQuery(
        db,
        reviewData.companyRef,
        reviewData.shopifyOrderId,
      ),
    );
    if (!existingOrders.empty) {
      const orderDoc = existingOrders.docs[0];
      const orderData = orderDoc.data() || {};
      tx.update(reviewRef, {
        reviewStatus: REVIEW_STATUS.APPROVED,
        approvedAt: FieldValue.serverTimestamp(),
        approvedBy: staff.uid,
        approvedByName: staff.name || staff.email || staff.uid,
        officialOrderId: orderData.Order_Id || null,
        officialOrderRef: orderDoc.ref,
      });
      return {
        ...alreadyApprovedResult(reviewRef, {
          ...reviewData,
          officialOrderId: orderData.Order_Id || null,
          officialOrderRef: orderDoc.ref,
        }),
        skipSideEffects: true,
      };
    }

    const erpOrderId = await nextDeliveryOrderIdInTransaction(tx, db);
    const orderRef = db.collection("orders").doc();
    const { orderData, mappedItems } = buildOfficialOrderData(reviewData, {
      erpOrderId,
      orderRef,
      companyRef: reviewData.companyRef,
      reviewRef,
      catalog,
    });
    tx.set(orderRef, orderData);
    for (const item of mappedItems) {
      tx.set(db.collection("Order_item").doc(), item);
    }
    tx.update(reviewRef, {
      reviewStatus: REVIEW_STATUS.APPROVED,
      approvedAt: FieldValue.serverTimestamp(),
      approvedBy: staff.uid,
      approvedByName: staff.name || staff.email || staff.uid,
      officialOrderId: erpOrderId,
      officialOrderRef: orderRef,
    });
    return {
      reviewId: reviewRef.id,
      shopifyOrderId: reviewData.shopifyOrderId,
      shopifyOrderName: reviewData.shopifyOrderName,
      officialOrderId: erpOrderId,
      officialOrderPath: orderRef.path,
      alreadyApproved: false,
      reviewData,
      orderRef,
      companyRef: reviewData.companyRef,
      companyId: reviewData.companyId,
    };
  });

  if (!result.alreadyApproved && !result.skipSideEffects) {
    await writeApprovalSideEffects(db, {
      companyId: result.companyId,
      companyRef: result.companyRef,
      reviewRef,
      reviewData: result.reviewData,
      orderRef: result.orderRef,
      erpOrderId: result.officialOrderId,
      staff,
    });
  }

  return {
    reviewId: result.reviewId,
    shopifyOrderId: result.shopifyOrderId,
    shopifyOrderName: result.shopifyOrderName,
    officialOrderId: result.officialOrderId,
    officialOrderPath: result.officialOrderPath,
    alreadyApproved: Boolean(result.alreadyApproved),
  };
}

async function approveShopifyReviews(db, reviewIds, staff) {
  const approved = [];
  const alreadyApproved = [];
  const failed = [];

  for (const reviewId of uniqueIds(reviewIds)) {
    try {
      const result = await approveShopifyReview(db, reviewId, staff);
      if (result.alreadyApproved) {
        alreadyApproved.push(result);
      } else {
        approved.push(result);
      }
    } catch (error) {
      failed.push({
        reviewId,
        code: error.code || "internal",
        error: error.message || "Approval failed",
      });
    }
  }

  return { approved, alreadyApproved, failed };
}

module.exports = {
  APPROVE_AUDIT_ACTION,
  uniqueIds,
  buildOfficialOrderData,
  approveShopifyReview,
  approveShopifyReviews,
};
