/**
 * Paid monthly usage for active SaaS subscriptions.
 *
 * The period id is the Stripe billing period when request time is still
 * inside current_period_end. Otherwise it is the UTC calendar month.
 * Clients cannot choose either value. Trial lifetime counters are never
 * reset or reused here.
 *
 * A rejected create writes nothing: no order, no order number, no counter
 * change. Shopify retries of the same external id return the first order.
 * Broadcast quota is consumed when a reservation is committed. It returns
 * only while that reservation is still `reserved` (abandoned before handoff),
 * and only once. The handoff is recorded before the external app opens.
 * After `handed_off`, a launcher failure becomes `unknown` and stays counted.
 * None of these states is a delivery receipt.
 *
 * Deploy Functions first. Deploy Firestore rules and the Flutter client
 * together: the client writes the plan-slot fields the rules require, and
 * production Functions are not on that client path.
 */
const { orderPeriodSuffix, counterDocId } = require("./shopify/order_id_helpers");

class PlanQuotaError extends Error {
  constructor(kind, max) {
    super(
      kind === "broadcast"
        ? `Plan limit reached: this plan allows ${max} broadcast recipients this period.`
        : `Plan limit reached: this plan allows ${max} orders this period. Existing orders can still be updated.`,
    );
    this.name = "PlanQuotaError";
    this.code = "plan-quota";
    this.kind = kind;
  }
}

function timestampMillis(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (typeof value === "number") {
    return value < 100000000000 ? value * 1000 : value;
  }
  if (typeof value._seconds === "number") {
    return value._seconds * 1000;
  }
  return null;
}

function utcMonthPeriod(now) {
  const date = now instanceof Date ? now : new Date(now);
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  return `${date.getUTCFullYear()}-${month}`;
}

/** Server period. Ignores any client-supplied date or counter. */
function usagePeriodId(company, now) {
  const end = timestampMillis(company && company.current_period_end);
  const id =
    company && typeof company.usage_period_id === "string"
      ? company.usage_period_id.trim()
      : "";
  const at = now instanceof Date ? now.getTime() : new Date(now).getTime();
  if (end != null && at < end && id) {
    return id;
  }
  return utcMonthPeriod(now);
}

function isPaidMeteredCompany(company) {
  return Boolean(
    company &&
      company.subscription_status === "active" &&
      company.pricing_version === "v1",
  );
}

function usageAfterReserve(existing, period, kind, count) {
  const same = existing && existing.period_id === period;
  const orders = same ? Number(existing.orders_consumed || 0) : 0;
  const broadcast = same ? Number(existing.broadcast_consumed || 0) : 0;
  if (kind === "orders") {
    return {
      period_id: period,
      orders_consumed: orders + 1,
      broadcast_consumed: broadcast,
      rolled: !same,
    };
  }
  return {
    period_id: period,
    orders_consumed: orders,
    broadcast_consumed: broadcast + count,
    rolled: !same,
  };
}

async function placePaidOrder(db, {
  companyId,
  company,
  orderRef,
  orderData,
  externalOrderId,
  extraWrites,
  now,
}) {
  const max = Number(company.max_orders_per_month || 0);
  const at = now instanceof Date ? now : new Date();
  const period = usagePeriodId(company, at);
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

    const usageRef = db.collection("plan_usage").doc(companyId);
    const usageSnap = await tx.get(usageRef);
    const existing = usageSnap.exists ? usageSnap.data() : null;
    const next = usageAfterReserve(existing, period, "orders", 1);
    if (next.orders_consumed > max) {
      throw new PlanQuotaError("orders", max);
    }

    const counterRef = db.collection("counter").doc(counterDocId("delivery"));
    const counterSnap = await tx.get(counterRef);
    const current = counterSnap.exists ? Number(counterSnap.data().current || 0) : 0;
    const seq = current + 1;
    const orderIdLabel = `TFG-${orderPeriodSuffix(at)}-000${seq}`;
    const slotRef = db
      .collection("plan_order_slots")
      .doc(companyId)
      .collection("periods")
      .doc(period)
      .collection("slots")
      .doc(String(next.orders_consumed));
    const companion =
      typeof extraWrites === "function" ? extraWrites(orderIdLabel) : [];

    tx.set(counterRef, { current: seq }, { merge: true });
    tx.set(usageRef, {
      period_id: next.period_id,
      orders_consumed: next.orders_consumed,
      broadcast_consumed: next.broadcast_consumed,
    });
    tx.set(slotRef, { order_id: orderRef.id });
    tx.set(orderRef, {
      ...orderData,
      Order_Id: orderIdLabel,
      plan_period: period,
      plan_slot: String(next.orders_consumed),
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
    return {
      duplicate: false,
      orderId: orderIdLabel,
      slot: next.orders_consumed,
      period,
    };
  });
}

async function reserveBroadcast(db, {
  companyId,
  company,
  attemptId,
  count,
  now,
}) {
  const max = Number(company.broadcast_quota_monthly || 0);
  const amount = Number(count);
  if (!Number.isInteger(amount) || amount < 1) {
    throw new PlanQuotaError("broadcast", max);
  }
  const at = now instanceof Date ? now : new Date();
  const period = usagePeriodId(company, at);
  const reservationRef = db.collection("broadcast_reservations").doc(attemptId);

  return db.runTransaction(async (tx) => {
    const existing = await tx.get(reservationRef);
    if (existing.exists) {
      const data = existing.data();
      if (data.company_id !== companyId) {
        throw new PlanQuotaError("broadcast", max);
      }
      return {
        duplicate: true,
        status: data.status,
        count: Number(data.count || 0),
        period: data.period_id,
      };
    }

    const usageRef = db.collection("plan_usage").doc(companyId);
    const usageSnap = await tx.get(usageRef);
    const current = usageSnap.exists ? usageSnap.data() : null;
    const next = usageAfterReserve(current, period, "broadcast", amount);
    if (next.broadcast_consumed > max) {
      throw new PlanQuotaError("broadcast", max);
    }

    tx.set(usageRef, {
      period_id: next.period_id,
      orders_consumed: next.orders_consumed,
      broadcast_consumed: next.broadcast_consumed,
      broadcast_attempt: attemptId,
    });
    tx.set(reservationRef, {
      company_id: companyId,
      period_id: period,
      count: amount,
      status: "reserved",
    });
    return {
      duplicate: false,
      status: "reserved",
      count: amount,
      period,
      consumed: next.broadcast_consumed,
    };
  });
}

async function releaseBroadcast(db, { companyId, attemptId }) {
  const reservationRef = db.collection("broadcast_reservations").doc(attemptId);
  return db.runTransaction(async (tx) => {
    const reservation = await tx.get(reservationRef);
    if (!reservation.exists || reservation.data().company_id !== companyId) {
      return { released: false, reason: "missing" };
    }
    if (reservation.data().status !== "reserved") {
      return { released: false, reason: reservation.data().status };
    }
    const count = Number(reservation.data().count || 0);
    const usageRef = db.collection("plan_usage").doc(companyId);
    const usageSnap = await tx.get(usageRef);
    const usage = usageSnap.exists ? usageSnap.data() : {};
    const next = Number(usage.broadcast_consumed || 0) - count;
    if (usage.period_id !== reservation.data().period_id || next < 0) {
      return { released: false, reason: "mismatch" };
    }
    tx.set(
      usageRef,
      {
        broadcast_consumed: next,
        broadcast_attempt: attemptId,
      },
      { merge: true },
    );
    tx.set(reservationRef, { status: "failed" }, { merge: true });
    return { released: true, consumed: next };
  });
}

async function markBroadcastHandedOff(db, { companyId, attemptId }) {
  const reservationRef = db.collection("broadcast_reservations").doc(attemptId);
  return db.runTransaction(async (tx) => {
    const reservation = await tx.get(reservationRef);
    if (!reservation.exists || reservation.data().company_id !== companyId) {
      return { handedOff: false, status: "missing" };
    }
    const status = reservation.data().status;
    if (status === "handed_off" || status === "opened") {
      return { handedOff: true, duplicate: true, status };
    }
    if (status !== "reserved") {
      return { handedOff: false, duplicate: false, status };
    }
    tx.set(reservationRef, { status: "handed_off" }, { merge: true });
    return { handedOff: true, duplicate: false, status: "handed_off" };
  });
}

async function markBroadcastUnknown(db, { companyId, attemptId }) {
  const reservationRef = db.collection("broadcast_reservations").doc(attemptId);
  return db.runTransaction(async (tx) => {
    const reservation = await tx.get(reservationRef);
    if (!reservation.exists || reservation.data().company_id !== companyId) {
      return { unknown: false, status: "missing" };
    }
    const status = reservation.data().status;
    if (status === "unknown") {
      return { unknown: true, duplicate: true, status };
    }
    if (status !== "handed_off" && status !== "opened") {
      return { unknown: false, duplicate: false, status };
    }
    tx.set(reservationRef, { status: "unknown" }, { merge: true });
    return { unknown: true, duplicate: false, status: "unknown" };
  });
}

module.exports = {
  PlanQuotaError,
  utcMonthPeriod,
  usagePeriodId,
  isPaidMeteredCompany,
  usageAfterReserve,
  placePaidOrder,
  reserveBroadcast,
  releaseBroadcast,
  markBroadcastHandedOff,
  markBroadcastUnknown,
};
