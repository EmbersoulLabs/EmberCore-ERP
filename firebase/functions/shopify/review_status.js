const REVIEW_STATUS = {
  PENDING_REVIEW: "PENDING_REVIEW",
  APPROVED: "APPROVED",
  REJECTED: "REJECTED",
  QUARANTINED: "QUARANTINED",
};

const FULLY_PAID_STATUS = "paid";

function normalizeFinancialStatus(financialStatus) {
  if (financialStatus == null) {
    return "";
  }
  return String(financialStatus).trim().toLowerCase();
}

/**
 * All authenticated orders/paid payloads enter PENDING_REVIEW.
 * financial_status is stored for staff to see (paid / voided / …).
 * QUARANTINED remains only as a historical status for existing documents.
 *
 * @returns {{reviewStatus: string, quarantineReason: string|null, financialStatus: string}}
 */
function resolvePaidReviewStatus(financialStatus) {
  return {
    reviewStatus: REVIEW_STATUS.PENDING_REVIEW,
    quarantineReason: null,
    financialStatus: normalizeFinancialStatus(financialStatus),
  };
}

function isPendingReviewStatus(status) {
  return status === REVIEW_STATUS.PENDING_REVIEW;
}

function isApprovedReviewStatus(status) {
  return status === REVIEW_STATUS.APPROVED;
}

function isActionableReviewStatus(status) {
  return (
    status === REVIEW_STATUS.PENDING_REVIEW ||
    status === REVIEW_STATUS.QUARANTINED
  );
}

module.exports = {
  REVIEW_STATUS,
  FULLY_PAID_STATUS,
  normalizeFinancialStatus,
  resolvePaidReviewStatus,
  isPendingReviewStatus,
  isApprovedReviewStatus,
  isActionableReviewStatus,
};
