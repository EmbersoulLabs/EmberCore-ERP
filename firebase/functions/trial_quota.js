/**
 * Trial quota for SaaS tenants (pricing v1).
 *
 * A successful order or staff profile consumes one slot. The slot is written
 * in the same transaction as the record, so a failed request consumes nothing.
 * Deleting the record does not return the slot. Legacy companies with no
 * subscription status are ignored.
 *
 * Shopify imports use this same transaction. A repeated Shopify order id
 * returns the existing order and does not consume another slot. When the
 * trial is full, the webhook answers 200 with limited=true so Shopify does
 * not retry a create that can never succeed.
 *
 * POS, WhatsApp, and the order screen all create the order through the
 * Flutter draft writer, which claims a slot in the same transaction. Direct
 * client writes still have to satisfy the Firestore rules.
 */
const { orderPeriodSuffix, counterDocId } = require("./shopify/order_id_helpers");

const TRIAL_STATUS = "trialing";
const PRICING_VERSION = "v1";

class TrialLimitError extends Error {
  constructor(kind, max) {
    super(
      kind === "staff"
        ? `Trial limit reached: this trial allows ${max} staff accounts.`
        : `Trial limit reached: this trial allows ${max} orders. Existing orders can still be updated.`,
    );
    this.name = "TrialLimitError";
    this.code = "trial-limit";
    this.kind = kind;
  }
}

function isTrialTenant(company) {
  if (!company) {
    return false;
  }
  return (
    company.subscription_status === TRIAL_STATUS &&
    company.pricing_version === PRICING_VERSION
  );
}

function nextSlot(consumed, max) {
  const next = Number(consumed || 0) + 1;
  if (next > Number(max)) {
    return null;
  }
  return next;
}

/**
 * Reserves the next order slot and writes the order.
 * When externalOrderId is set, a second call returns the first order.
 */
async function placeTrialOrder(db, {
  companyId,
  company,
  orderRef,
  orderData,
  externalOrderId,
  extraWrites,
}) {
  const max = Number(company.max_orders_per_month || 100);
  const lockRef = externalOrderId
    ? db.collection("shopify_import_keys").doc(`${companyId}_${externalOrderId}`)
    : null;

  return db.runTransaction(async (tx) => {
    if (lockRef) {
      const lock = await tx.get(lockRef);
      if (lock.exists) {
        return {
          duplicate: true,
          orderId: lock.data().order_id_label || "",
          orderPath: lock.data().order_path || "",
        };
      }
    }

    const quotaRef = db.collection("trial_quota").doc(companyId);
    const quotaSnap = await tx.get(quotaRef);
    const consumed = quotaSnap.exists
      ? Number(quotaSnap.data().orders_consumed || 0)
      : 0;
    const slot = nextSlot(consumed, max);
    if (slot == null) {
      throw new TrialLimitError("orders", max);
    }

    const counterRef = db.collection("counter").doc(counterDocId("delivery"));
    const counterSnap = await tx.get(counterRef);
    const current = counterSnap.exists ? Number(counterSnap.data().current || 0) : 0;
    const seq = current + 1;
    const orderIdLabel = `TFG-${orderPeriodSuffix()}-000${seq}`;
    const slotRef = db
      .collection("trial_order_slots")
      .doc(companyId)
      .collection("slots")
      .doc(String(slot));
    const companion =
      typeof extraWrites === "function" ? extraWrites(orderIdLabel) : [];

    tx.set(counterRef, { current: seq }, { merge: true });
    tx.set(
      quotaRef,
      {
        orders_consumed: slot,
        staff_consumed: quotaSnap.exists
          ? Number(quotaSnap.data().staff_consumed || 0)
          : 1,
      },
      { merge: true },
    );
    tx.set(slotRef, { order_id: orderRef.id });
    tx.set(orderRef, {
      ...orderData,
      Order_Id: orderIdLabel,
      trial_slot: String(slot),
    });
    for (const write of companion) {
      tx.set(write.ref, write.data);
    }
    if (lockRef) {
      tx.set(lockRef, {
        order_path: orderRef.path,
        order_id_label: orderIdLabel,
      });
    }
    return { duplicate: false, orderId: orderIdLabel, slot };
  });
}

module.exports = {
  TrialLimitError,
  isTrialTenant,
  nextSlot,
  placeTrialOrder,
};
