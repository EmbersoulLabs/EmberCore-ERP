const { FieldValue } = require("firebase-admin/firestore");
const { uniqueIds } = require("./approve_reviews");
const { REVIEWS_COLLECTION } = require("./review_identity");
const { REVIEW_STATUS, isActionableReviewStatus } = require("./review_status");
const { assertReviewBelongsToStaff } = require("./staff_auth");

const DELETE_AUDIT_ACTION = "shopify_review_deleted";

async function writeDeleteAudit(db, { reviewRef, reviewData, staff }) {
  const now = FieldValue.serverTimestamp();
  await db.collection("audit_logs").doc().set({
    userId: staff.uid,
    userName: staff.name || staff.email || staff.uid,
    userRole: staff.role || "staff",
    action: DELETE_AUDIT_ACTION,
    entityType: "shopify_review",
    entityId: reviewRef.id,
    entityLabel: reviewData.shopifyOrderName || reviewData.shopifyOrderId || "",
    description: "Shopify review deleted",
    companyId: reviewData.companyId || reviewData.companyRef?.id || "",
    companyRef: reviewData.companyRef || null,
    oldValue: {
      shopifyOrderId: reviewData.shopifyOrderId || "",
      shopifyOrderName: reviewData.shopifyOrderName || "",
      financialStatus: reviewData.financialStatus || "",
      reviewStatus: reviewData.reviewStatus || "",
    },
    createdAt: now,
    created_at: now,
  });
}

/**
 * Permanently remove a staged Shopify review. Does not touch official orders.
 * Approved reviews cannot be deleted here.
 */
async function deleteShopifyReview(db, reviewId, staff) {
  const reviewRef = db.collection(REVIEWS_COLLECTION).doc(String(reviewId));
  const previewSnap = await reviewRef.get();
  if (!previewSnap.exists) {
    const error = new Error("Shopify review not found");
    error.code = "not-found";
    throw error;
  }
  const preview = previewSnap.data() || {};
  assertReviewBelongsToStaff(preview, { data: staff.profile });

  if (preview.reviewStatus === REVIEW_STATUS.APPROVED) {
    const error = new Error("Approved Shopify review cannot be deleted");
    error.code = "failed-precondition";
    throw error;
  }
  if (!isActionableReviewStatus(preview.reviewStatus) &&
      preview.reviewStatus !== REVIEW_STATUS.REJECTED) {
    const error = new Error("Shopify review cannot be deleted");
    error.code = "failed-precondition";
    throw error;
  }

  const deleted = await db.runTransaction(async (tx) => {
    const snap = await tx.get(reviewRef);
    if (!snap.exists) {
      const error = new Error("Shopify review not found");
      error.code = "not-found";
      throw error;
    }
    const reviewData = snap.data() || {};
    assertReviewBelongsToStaff(reviewData, { data: staff.profile });
    if (reviewData.reviewStatus === REVIEW_STATUS.APPROVED) {
      const error = new Error("Approved Shopify review cannot be deleted");
      error.code = "failed-precondition";
      throw error;
    }
    tx.delete(reviewRef);
    return reviewData;
  });

  await writeDeleteAudit(db, { reviewRef, reviewData: deleted, staff });
  return {
    reviewId: reviewRef.id,
    shopifyOrderId: deleted.shopifyOrderId || "",
    shopifyOrderName: deleted.shopifyOrderName || "",
    deleted: true,
  };
}

async function deleteShopifyReviews(db, reviewIds, staff) {
  const deleted = [];
  const failed = [];

  for (const reviewId of uniqueIds(reviewIds)) {
    try {
      deleted.push(await deleteShopifyReview(db, reviewId, staff));
    } catch (error) {
      failed.push({
        reviewId,
        code: error.code || "internal",
        error: error.message || "Delete failed",
      });
    }
  }

  return { deleted, failed };
}

module.exports = {
  DELETE_AUDIT_ACTION,
  deleteShopifyReview,
  deleteShopifyReviews,
};
