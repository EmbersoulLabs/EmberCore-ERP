/**
 * Mirrors lib/backend/order_id_service.dart.
 * Prefix matches EmberCore OrderIdService.fallbackPrefix (EC).
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

const ORDER_ID_PREFIX = process.env.ORDER_ID_PREFIX || "EC";
const MAX_ORDER_ID_SEQUENCE = 9999;

function orderPeriodSuffix(date = new Date()) {
  const month = MONTHS[date.getMonth()];
  const year = String(date.getFullYear()).slice(-2);
  return `${month}${year}`;
}

function counterDocId(channel, period = orderPeriodSuffix()) {
  const base =
    channel === "delivery"
      ? "default_delivery"
      : channel === "retail"
        ? "default_retail"
        : `default_${channel}`;
  return `${base}_${period}`;
}

function formatOrderSequence(seq) {
  if (seq < 1 || seq > MAX_ORDER_ID_SEQUENCE) {
    throw new Error(
      `Order ID sequence must be between 1 and ${MAX_ORDER_ID_SEQUENCE}`,
    );
  }
  return String(seq).padStart(4, "0");
}

function formatDeliveryOrderId(seq, date = new Date()) {
  return `${ORDER_ID_PREFIX}-${orderPeriodSuffix(date)}-${formatOrderSequence(seq)}`;
}

async function incrementCounterInTransaction(tx, counterRef) {
  const snap = await tx.get(counterRef);
  const current = snap.exists ? Number(snap.data().current ?? 0) : 0;
  const next = current + 1;
  if (next > MAX_ORDER_ID_SEQUENCE) {
    throw new Error(
      `Maximum order IDs reached for this period (${MAX_ORDER_ID_SEQUENCE}).`,
    );
  }
  tx.set(counterRef, { current: next }, { merge: true });
  return next;
}

async function incrementCounter(db, channel = "delivery") {
  const counterRef = db.collection("counter").doc(counterDocId(channel));
  return db.runTransaction(async (tx) =>
    incrementCounterInTransaction(tx, counterRef),
  );
}

async function nextDeliveryOrderIdInTransaction(tx, db, date = new Date()) {
  const period = orderPeriodSuffix(date);
  const counterRef = db.collection("counter").doc(counterDocId("delivery", period));
  const seq = await incrementCounterInTransaction(tx, counterRef);
  return formatDeliveryOrderId(seq, date);
}

async function nextDeliveryOrderId(db) {
  const period = orderPeriodSuffix();
  const seq = await incrementCounter(db, "delivery");
  return formatDeliveryOrderId(seq);
}

module.exports = {
  ORDER_ID_PREFIX,
  orderPeriodSuffix,
  counterDocId,
  formatOrderSequence,
  formatDeliveryOrderId,
  MAX_ORDER_ID_SEQUENCE,
  incrementCounter,
  incrementCounterInTransaction,
  nextDeliveryOrderId,
  nextDeliveryOrderIdInTransaction,
};
