/**
 * Mirrors lib/backend/order_id_service.dart — shared default_* counter transactions.
 * Used by emulator integration tests and optional scripts.
 */

const MONTHS = [
  "JAN",
  "FEB",
  "MAR",
  "APR",
  "MAY",
  "JUN",
  "JUL",
  "AUG",
  "SEP",
  "OCT",
  "NOV",
  "DEC",
];

function orderPeriodSuffix(date = new Date()) {
  const month = MONTHS[date.getMonth()];
  const year = String(date.getFullYear()).slice(-2);
  return `${month}${year}`;
}

function counterDocId(channel, period = orderPeriodSuffix()) {
  let base;
  if (channel === "delivery") {
    base = "default_delivery";
  } else if (channel === "retail") {
    base = "default_retail";
  } else {
    base = `default_${channel}`;
  }
  return `${base}_${period}`;
}

/**
 * @param {import('firebase-admin').firestore.Firestore} db
 * @param {string} channel
 * @param {import('firebase-admin').firestore.DocumentReference | null} comR
 * @param {string} [period]
 * @returns {Promise<number>} next sequence number
 */
async function incrementCounter(db, channel = "delivery", comR = null, period) {
  const counterRef = db.collection("counter").doc(counterDocId(channel, period));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const current = snap.exists ? Number(snap.data().current ?? 0) : 0;
    const next = current + 1;
    const payload = { current: next };
    if (comR) {
      payload.comR = comR;
    }
    tx.set(counterRef, payload, { merge: true });
    return next;
  });
}

/** @deprecated Use incrementCounter — kept for older tests/scripts. */
async function incrementSharedCounter(db, _companyId = "default", comR = null) {
  return incrementCounter(db, "delivery", comR);
}

/**
 * @param {import('firebase-admin').firestore.Firestore} db
 */
async function nextDeliveryOrderId(db) {
  const period = orderPeriodSuffix();
  const seq = await incrementCounter(db, "delivery");
  return `TFG-${period}-000${seq}`;
}

/**
 * @param {import('firebase-admin').firestore.Firestore} db
 */
async function nextRetailOrderId(db) {
  const period = orderPeriodSuffix();
  const seq = await incrementCounter(db, "retail");
  return `TFG-${period}-WI000${seq}`;
}

function isDeliveryOrderNumber(orderId) {
  return /^[A-Za-z0-9]+-[A-Z]{3}\d{2}-\d+$/.test(String(orderId || ""));
}

/**
 * One delivery number per order document. The counter only moves when the
 * order does not already have a delivery number.
 */
async function assignDeliveryOrderId(db, orderRef, prefix = "EC") {
  const period = orderPeriodSuffix();
  const counterRef = db.collection("counter").doc(counterDocId("delivery", period));
  return db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    const existing = orderSnap.exists ? orderSnap.data().Order_Id : "";
    if (isDeliveryOrderNumber(existing)) {
      return existing;
    }
    const counterSnap = await tx.get(counterRef);
    const current = counterSnap.exists ? Number(counterSnap.data().current ?? 0) : 0;
    const next = current + 1;
    tx.set(counterRef, { current: next }, { merge: true });
    const orderId = `${prefix}-${period}-000${next}`;
    tx.set(orderRef, { ...(orderSnap.exists ? orderSnap.data() : {}), Order_Id: orderId });
    return orderId;
  });
}

module.exports = {
  orderPeriodSuffix,
  counterDocId,
  incrementCounter,
  incrementSharedCounter,
  nextDeliveryOrderId,
  nextRetailOrderId,
  assignDeliveryOrderId,
};
