const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { staffNoticeRecipientRef } = require("./shopify/map_order");
const {
  resolveOperationNoticeTemplate,
  formatOperationNoticeTemplate,
  loadOperationNoticeTemplates,
} = require("./operation_notice_templates");
const {
  buildTomorrowPrepNoticeContent,
  applyTomorrowPrepTemplate,
} = require("./tomorrow_prep_notice_copy");

const BUSINESS_TIMEZONE = "Asia/Singapore";

const NOTICE_TYPE = {
  tomorrowPrep: "tomorrow_prep_reminder",
  todayOps: "today_ops_reminder",
};

const REMINDER_KIND = {
  tomorrowPrep: "tomorrow_prep",
  todayOps: "today_ops",
};

function calendarDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(day, count) {
  const next = new Date(day);
  next.setDate(next.getDate() + count);
  return calendarDay(next);
}

function startOfDay(day) {
  return new Date(day.getFullYear(), day.getMonth(), day.getDate(), 0, 0, 0, 0);
}

function endOfDay(day) {
  return new Date(
    day.getFullYear(),
    day.getMonth(),
    day.getDate(),
    23,
    59,
    59,
    999,
  );
}

function formatShortDate(day) {
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  return `${day.getDate()} ${months[day.getMonth()]} ${day.getFullYear()}`;
}

function isCancelled(order) {
  return (
    order.status === "cancelled" ||
    (order.orderstatus || "").toLowerCase() === "cancelled"
  );
}

function isCompleted(order) {
  return (
    order.status === "completed" ||
    (order.orderstatus || "").toLowerCase() === "completed"
  );
}

function isRetailOrder(order) {
  const orderType = (order.orderType || "").toLowerCase();
  const pickupDelivery = (order.pickup_delivery || "").toLowerCase();
  if (orderType.includes("retail") || pickupDelivery.includes("retail")) {
    return true;
  }
  const orderId = order.Order_Id || order.orderId || "";
  return /-WI\d/i.test(orderId);
}

function isDeliveryOrder(order) {
  if (isRetailOrder(order)) {
    return false;
  }
  const raw = (order.pickup_delivery || order.orderType || "").toLowerCase();
  if (raw.includes("pick")) {
    return false;
  }
  return raw.includes("deliver") || order.orderType === "Delivery";
}

function needsProduction(order) {
  if (isCancelled(order) || isCompleted(order)) {
    return false;
  }
  const status = (order.status || order.orderstatus || "").toLowerCase();
  return status === "pending" || status === "processing";
}

function orderEffectiveDate(order) {
  if (isRetailOrder(order)) {
    return order.created_time?.toDate?.() || order.delivery_date?.toDate?.() || null;
  }
  return order.delivery_date?.toDate?.() || order.created_time?.toDate?.() || null;
}

function orderMatchesCalendarDay(order, day) {
  const effective = orderEffectiveDate(order);
  if (!effective) {
    return false;
  }
  const effectiveDay = calendarDay(effective);
  return effectiveDay.getTime() === day.getTime();
}

function isOperationReminderRecipient(userData) {
  if (userData.is_active === false) {
    return false;
  }
  const uid = typeof userData.uid === "string" ? userData.uid.trim() : "";
  if (!uid) {
    return false;
  }
  if (userData.role === "driver") {
    return false;
  }
  return Boolean(userData.role);
}

async function loadOperationReminderRecipients(db, companyRef) {
  const companyId = companyRef.id;
  const snap = await db.collection("users").get();
  return snap.docs.filter((doc) => {
    const data = doc.data();
    if (!isOperationReminderRecipient(data)) {
      return false;
    }
    return data.companyRef?.id === companyId;
  });
}

async function loadOrdersForCompanyOnDates(db, companyRef, targetDays) {
  if (targetDays.length === 0) {
    return [];
  }

  const sortedDays = [...targetDays].sort((a, b) => a.getTime() - b.getTime());
  const rangeStart = startOfDay(sortedDays[0]);
  const rangeEnd = endOfDay(sortedDays[sortedDays.length - 1]);

  const snap = await db
    .collection("orders")
    .where("companyRef", "==", companyRef)
    .where("delivery_date", ">=", Timestamp.fromDate(rangeStart))
    .where("delivery_date", "<=", Timestamp.fromDate(rangeEnd))
    .get();

  const dayKeys = new Set(targetDays.map((day) => day.getTime()));
  return snap.docs
    .map((doc) => ({ ref: doc.ref, data: doc.data() }))
    .filter(({ data }) => {
      const effective = orderEffectiveDate(data);
      if (!effective) {
        return false;
      }
      return dayKeys.has(calendarDay(effective).getTime());
    });
}

function summarizeDeliveryOrders(orders) {
  const deliveryOrders = orders.filter(({ data }) => isDeliveryOrder(data));
  const incomplete = deliveryOrders.filter(({ data }) => !isCompleted(data) && !isCancelled(data));
  const notStarted = incomplete.filter(({ data }) => needsProduction(data));
  return {
    totalDelivery: deliveryOrders.length,
    incompleteCount: incomplete.length,
    notStartedCount: notStarted.length,
  };
}

function buildTomorrowPrepNotice({ targetDays, summary, templates = null }) {
  const content = buildTomorrowPrepNoticeContent(summary);
  const isWeekendBlock = targetDays.length > 1;
  const templateKey = isWeekendBlock ? "tomorrow_prep_weekend" : "tomorrow_prep";
  const custom = templates?.[templateKey]?.trim();

  let body = content.body;
  if (custom) {
    if (
      custom.includes("{line1}") ||
      custom.includes("{line2}") ||
      custom.includes("{body}")
    ) {
      body = applyTomorrowPrepTemplate(custom, content);
    } else {
      body = formatOperationNoticeTemplate(custom, {
        target_date: formatShortDate(targetDays[0]),
        target_dates: targetDays.map(formatShortDate).join(", "),
        total_delivery: content.deliveryCount,
        pending_count: content.pendingCount,
        not_started: content.pendingCount,
        incomplete: summary.incompleteCount,
      });
    }
  }

  return {
    title: content.title,
    body,
    status: content.status,
    deliveryCount: content.deliveryCount,
    pendingCount: content.pendingCount,
  };
}

/** @deprecated Use buildTomorrowPrepNotice */
function buildTomorrowPrepMessage(args) {
  return buildTomorrowPrepNotice(args).body;
}

function buildTodayOpsMessage({ targetDay, summary, templates = null }) {
  if (summary.totalDelivery === 0 || summary.notStartedCount === 0) {
    return null;
  }

  const template = resolveOperationNoticeTemplate(templates, "today_ops");
  return formatOperationNoticeTemplate(template, {
    target_date: formatShortDate(targetDay),
    target_dates: formatShortDate(targetDay),
    total_delivery: summary.totalDelivery,
    not_started: summary.notStartedCount,
    incomplete: summary.incompleteCount,
  });
}

function resolveTargetDaysForTomorrowPrep(localDay) {
  if (localDay.getDay() === 5) {
    return [addDays(localDay, 1), addDays(localDay, 2), addDays(localDay, 3)];
  }
  return [addDays(localDay, 1)];
}

function reminderRunKey({ companyId, kind, localDay }) {
  const dayKey = [
    localDay.getFullYear(),
    String(localDay.getMonth() + 1).padStart(2, "0"),
    String(localDay.getDate()).padStart(2, "0"),
  ].join("-");
  return `${companyId}_${kind}_${dayKey}`;
}

async function claimReminderRun(db, runKey, payload) {
  const runRef = db.collection("operation_reminder_runs").doc(runKey);
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(runRef);
    if (existing.exists) {
      return false;
    }
    tx.set(runRef, {
      ...payload,
      created_at: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function writeReminderNotices({
  db,
  companyRef,
  recipients,
  noticeType,
  message,
  deliveryDate,
  itemSummary,
  noticeTitle,
  prepDeliveryCount,
  prepPendingCount,
  prepStatus,
}) {
  if (recipients.length === 0) {
    return 0;
  }

  const batch = db.batch();
  let writes = 0;
  recipients.forEach((userDoc) => {
    const recipientRef = staffNoticeRecipientRef(db, userDoc);
    const noticeRef = db.collection("staff_notices").doc();
    batch.set(noticeRef, {
      type: noticeType,
      recipient_user_ref: recipientRef,
      message,
      item_summary: itemSummary,
      delivery_date: Timestamp.fromDate(deliveryDate),
      created_time: FieldValue.serverTimestamp(),
      companyRef,
      ...(noticeTitle ? { notice_title: noticeTitle } : {}),
      ...(prepDeliveryCount != null ? { prep_delivery_count: prepDeliveryCount } : {}),
      ...(prepPendingCount != null ? { prep_pending_count: prepPendingCount } : {}),
      ...(prepStatus ? { prep_status: prepStatus } : {}),
    });
    writes += 1;
  });

  if (writes === 0) {
    return 0;
  }
  await batch.commit();
  return writes;
}

async function sendTomorrowPrepReminders(db, localDay) {
  const targetDays = resolveTargetDaysForTomorrowPrep(localDay);
  const companiesSnap = await db.collection("Companies").get();
  const results = [];

  for (const companyDoc of companiesSnap.docs) {
    const companyRef = companyDoc.ref;
    const runKey = reminderRunKey({
      companyId: companyRef.id,
      kind: REMINDER_KIND.tomorrowPrep,
      localDay,
    });
    const claimed = await claimReminderRun(db, runKey, {
      kind: REMINDER_KIND.tomorrowPrep,
      company_id: companyRef.id,
      target_days: targetDays.map((day) => formatShortDate(day)),
    });
    if (!claimed) {
      results.push({ companyId: companyRef.id, skipped: true });
      continue;
    }

    const orders = await loadOrdersForCompanyOnDates(db, companyRef, targetDays);
    const summary = summarizeDeliveryOrders(orders);
    const templates = await loadOperationNoticeTemplates(db, companyRef.id);
    const notice = buildTomorrowPrepNotice({
      targetDays,
      summary,
      templates,
    });

    const recipients = await loadOperationReminderRecipients(db, companyRef);
    const noticesCreated = await writeReminderNotices({
      db,
      companyRef,
      recipients,
      noticeType: NOTICE_TYPE.tomorrowPrep,
      message: notice.body,
      deliveryDate: targetDays[0],
      itemSummary: "",
      noticeTitle: notice.title,
      prepDeliveryCount: notice.deliveryCount,
      prepPendingCount: notice.pendingCount,
      prepStatus: notice.status,
    });
    results.push({ companyId: companyRef.id, noticesCreated, message: notice.body });
  }

  return results;
}

async function sendTodayOpsReminders(db, localDay) {
  const targetDay = calendarDay(localDay);
  const companiesSnap = await db.collection("Companies").get();
  const results = [];

  for (const companyDoc of companiesSnap.docs) {
    const companyRef = companyDoc.ref;
    const runKey = reminderRunKey({
      companyId: companyRef.id,
      kind: REMINDER_KIND.todayOps,
      localDay,
    });
    const claimed = await claimReminderRun(db, runKey, {
      kind: REMINDER_KIND.todayOps,
      company_id: companyRef.id,
      target_day: formatShortDate(targetDay),
    });
    if (!claimed) {
      results.push({ companyId: companyRef.id, skipped: true });
      continue;
    }

    const orders = await loadOrdersForCompanyOnDates(db, companyRef, [targetDay]);
    const summary = summarizeDeliveryOrders(orders);
    const templates = await loadOperationNoticeTemplates(db, companyRef.id);
    const message = buildTodayOpsMessage({
      targetDay,
      summary,
      templates,
    });

    if (!message) {
      results.push({ companyId: companyRef.id, noticesCreated: 0, reason: "nothing_to_remind" });
      continue;
    }

    const recipients = await loadOperationReminderRecipients(db, companyRef);
    const noticesCreated = await writeReminderNotices({
      db,
      companyRef,
      recipients,
      noticeType: NOTICE_TYPE.todayOps,
      message,
      deliveryDate: targetDay,
      itemSummary: "",
    });
    results.push({ companyId: companyRef.id, noticesCreated, message });
  }

  return results;
}

module.exports = {
  BUSINESS_TIMEZONE,
  NOTICE_TYPE,
  REMINDER_KIND,
  calendarDay,
  addDays,
  isOperationReminderRecipient,
  isDeliveryOrder,
  needsProduction,
  resolveTargetDaysForTomorrowPrep,
  summarizeDeliveryOrders,
  buildTomorrowPrepMessage,
  buildTomorrowPrepNotice,
  buildTodayOpsMessage,
  sendTomorrowPrepReminders,
  sendTodayOpsReminders,
};
