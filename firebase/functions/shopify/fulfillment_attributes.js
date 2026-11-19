/**
 * Extract florist fulfillment fields from a Shopify order payload:
 * gift/card message, delivery date, delivery time slot.
 *
 * Sources (first non-empty wins per field):
 * 1. note_attributes / attributes
 * 2. line_items[].properties
 * 3. labeled lines inside order.note
 * 4. fulfillment_orders[].fulfill_at (date only)
 */

const { Timestamp } = require("firebase-admin/firestore");

const DEFAULT_SHOPIFY_DELIVERY_TIME_SLOT = "09:00-20:00";
const SINGAPORE_TZ = "+08:00";

const MONTHS = {
  jan: 1,
  feb: 2,
  mar: 3,
  apr: 4,
  may: 5,
  jun: 6,
  jul: 7,
  aug: 8,
  sep: 9,
  sept: 9,
  oct: 10,
  nov: 11,
  dec: 12,
};

function pad2(value) {
  return String(value).padStart(2, "0");
}

function normalizeAttrKey(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase()
    .replace(/[_./-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function addAttribute(map, name, value) {
  const key = normalizeAttrKey(name);
  const text = value == null ? "" : String(value).trim();
  if (!key || !text) {
    return;
  }
  if (isInternalPropertyKey(key)) {
    return;
  }
  if (!map.has(key)) {
    map.set(key, text);
  }
}

function collectAttributeMap(order) {
  const map = new Map();
  const noteAttributes = order?.note_attributes || order?.noteAttributes || [];
  if (Array.isArray(noteAttributes)) {
    for (const row of noteAttributes) {
      addAttribute(map, row?.name || row?.key, row?.value);
    }
  } else if (noteAttributes && typeof noteAttributes === "object") {
    for (const [name, value] of Object.entries(noteAttributes)) {
      addAttribute(map, name, value);
    }
  }

  const attributes = order?.attributes;
  if (Array.isArray(attributes)) {
    for (const row of attributes) {
      addAttribute(map, row?.name || row?.key, row?.value);
    }
  } else if (attributes && typeof attributes === "object") {
    for (const [name, value] of Object.entries(attributes)) {
      addAttribute(map, name, value);
    }
  }

  for (const item of order?.line_items || []) {
    const properties = item?.properties;
    if (Array.isArray(properties)) {
      for (const row of properties) {
        addAttribute(map, row?.name || row?.key, row?.value);
      }
    } else if (properties && typeof properties === "object") {
      for (const [name, value] of Object.entries(properties)) {
        addAttribute(map, name, value);
      }
    }
  }

  return map;
}

function firstMatchingValue(map, matcher) {
  for (const [key, value] of map.entries()) {
    if (matcher(key)) {
      return value;
    }
  }
  return "";
}

function isGiftMessageKey(key) {
  if (
    key === "gift message" ||
    key === "giftmessage" ||
    key === "gift note" ||
    key === "giftnote" ||
    key === "card message" ||
    key === "cardmessage" ||
    key === "message card" ||
    key === "message on card" ||
    key === "greeting card" ||
    key === "greeting" ||
    key === "card text" ||
    key === "card content" ||
    key === "gift wrap message"
  ) {
    return true;
  }
  if (key.includes("gift") && key.includes("message")) {
    return true;
  }
  if (key.includes("card") && key.includes("message")) {
    return true;
  }
  return key === "message";
}

function isDeliveryDateKey(key) {
  if (
    key === "delivery date" ||
    key === "deliverydate" ||
    key === "deliver date" ||
    key === "preferred delivery date" ||
    key === "preferred date" ||
    key === "delivery day"
  ) {
    return true;
  }
  return key.includes("delivery") && key.includes("date");
}

function isDeliveryTimeKey(key) {
  if (
    key === "delivery time" ||
    key === "delivery time slot" ||
    key === "delivery timeslot" ||
    key === "delivery timing" ||
    key === "time slot" ||
    key === "timeslot" ||
    key === "delivery window" ||
    key === "preferred time" ||
    key === "preferred delivery time"
  ) {
    return true;
  }
  if (key.includes("time") && key.includes("slot")) {
    return true;
  }
  return key.includes("delivery") && key.includes("time");
}

function isAddonKey(key) {
  return key === "addon" || key === "add on" || key === "add ons" || key === "add-on";
}

function isPropertyAddressKey(key) {
  return (
    key === "address" ||
    key === "delivery address" ||
    key === "recipient address"
  );
}

function isRecipientNameKey(key) {
  return (
    key === "recipient name" ||
    key === "receiver name" ||
    key === "recipient" ||
    key === "receiver"
  );
}

function isRecipientPhoneKey(key) {
  return (
    key === "recipient hp no" ||
    key === "recipient hp" ||
    key === "recipient phone" ||
    key === "receiver hp no" ||
    key === "receiver phone"
  );
}

function isSenderPhoneKey(key) {
  return (
    key === "sender hp no" ||
    key === "sender hp" ||
    key === "sender phone" ||
    key === "customer phone"
  );
}

function isRemarksKey(key) {
  return (
    key === "remarks" ||
    key === "remark" ||
    key === "special instructions"
  );
}

function isDeliveryMethodKey(key) {
  if (key === "delivery method" || key === "delivery services") {
    return true;
  }
  return key.includes("type of delivery") && key.includes("service");
}

function isInternalPropertyKey(key) {
  return key === "tpo add by" || key.startsWith("tpo ");
}

function isCardPartyKey(key) {
  return (
    key === "from" ||
    key === "from name" ||
    key === "sender" ||
    key === "to" ||
    key === "to name" ||
    key === "for" ||
    key === "gift to"
  );
}

/// Properties that already have dedicated ERP fields — do not copy into Remark.
function isDedicatedCheckoutPropertyKey(key) {
  return (
    isInternalPropertyKey(key) ||
    isGiftMessageKey(key) ||
    isCardPartyKey(key) ||
    isDeliveryDateKey(key) ||
    isDeliveryTimeKey(key) ||
    isDeliveryMethodKey(key) ||
    isPickupPropertyKey(key) ||
    isPropertyAddressKey(key) ||
    isRecipientNameKey(key) ||
    isRecipientPhoneKey(key) ||
    isSenderPhoneKey(key) ||
    key === "delivery"
  );
}

function looksLikePickupMethod(raw) {
  const text = String(raw || "").toLowerCase();
  return (
    text.includes("pick up") ||
    text.includes("pickup") ||
    text.includes("self collect")
  );
}

function looksLikeDeliveryMethod(raw) {
  const text = String(raw || "").toLowerCase();
  if (!text) {
    return false;
  }
  if (looksLikePickupMethod(text)) {
    return false;
  }
  return text.includes("delivery");
}

function normalizeDeliveryMethod(raw) {
  const text = String(raw || "").trim();
  if (!text) {
    return "";
  }
  if (looksLikePickupMethod(text)) {
    return "Pick Up";
  }
  if (looksLikeDeliveryMethod(text)) {
    return "Delivery";
  }
  return "";
}

function isPickupPropertyKey(key) {
  return (
    key === "pick up" ||
    key === "pickup" ||
    key === "self collect" ||
    key === "collection"
  );
}

function looksLikeNormalizedSlot(raw) {
  return /^\d{2}:\d{2}-\d{2}:\d{2}$/.test(String(raw || "").trim());
}

function extractSingaporePostal(raw) {
  const match = String(raw || "").match(/\b(\d{6})\b/);
  return match ? match[1] : "";
}

function collectMatchingValues(map, matcher) {
  const values = [];
  for (const [key, value] of map.entries()) {
    if (matcher(key) && value) {
      values.push(value);
    }
  }
  return values;
}

function singaporeMidnight(year, month, day) {
  const iso = `${year}-${pad2(month)}-${pad2(day)}T00:00:00${SINGAPORE_TZ}`;
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return Timestamp.fromDate(date);
}

function parseFlexibleDeliveryDate(raw) {
  if (raw == null || raw === "") {
    return null;
  }
  const text = String(raw).trim();
  if (!text) {
    return null;
  }

  const iso = text.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/);
  if (iso) {
    return singaporeMidnight(
      Number(iso[1]),
      Number(iso[2]),
      Number(iso[3]),
    );
  }

  const slash = text.match(/^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})/);
  if (slash) {
    const first = Number(slash[1]);
    const second = Number(slash[2]);
    let year = Number(slash[3]);
    if (year < 100) {
      year += 2000;
    }
    let day;
    let month;
    if (first > 12) {
      day = first;
      month = second;
    } else if (second > 12) {
      month = first;
      day = second;
    } else {
      day = first;
      month = second;
    }
    if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      return singaporeMidnight(year, month, day);
    }
  }

  const named = text.match(
    /^(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})|^([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{2,4})/,
  );
  if (named) {
    let day;
    let monthName;
    let year;
    if (named[1]) {
      day = Number(named[1]);
      monthName = named[2];
      year = Number(named[3]);
    } else {
      monthName = named[4];
      day = Number(named[5]);
      year = Number(named[6]);
    }
    if (year < 100) {
      year += 2000;
    }
    const month = MONTHS[monthName.slice(0, 3).toLowerCase()];
    if (month) {
      return singaporeMidnight(year, month, day);
    }
  }

  const parsed = new Date(text);
  if (!Number.isNaN(parsed.getTime())) {
    const sg = new Date(parsed.toLocaleString("en-US", { timeZone: "Asia/Singapore" }));
    return singaporeMidnight(sg.getFullYear(), sg.getMonth() + 1, sg.getDate());
  }
  return null;
}

function normalizeTimeSlot(raw) {
  const text = String(raw || "").trim().replace(/\s+/g, " ");
  if (!text) {
    return "";
  }
  const ampm = text.match(
    /(\d{1,2})(?::(\d{2}))?\s*(am|pm)\s*(?:-|–|to)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i,
  );
  if (ampm) {
    const to24 = (hourRaw, minuteRaw, mer) => {
      let hour = Number(hourRaw);
      const minute = minuteRaw ? Number(minuteRaw) : 0;
      const isPm = mer.toLowerCase() === "pm";
      if (hour === 12) {
        hour = isPm ? 12 : 0;
      } else if (isPm) {
        hour += 12;
      }
      return `${pad2(hour)}:${pad2(minute)}`;
    };
    return `${to24(ampm[1], ampm[2], ampm[3])}-${to24(ampm[4], ampm[5], ampm[6])}`;
  }
  return text.replace(/\s*[-–]\s*/g, "-");
}

function extractLabeledNoteFields(note) {
  const result = { cardMessage: "", deliveryDateText: "", deliveryTimeSlot: "" };
  if (!note) {
    return result;
  }
  for (const rawLine of String(note).split(/\r?\n/)) {
    const match = rawLine.match(/^\s*(.+?)\s*[:：]\s*(.+?)\s*$/);
    if (!match) {
      continue;
    }
    const key = normalizeAttrKey(match[1]);
    const value = match[2].trim();
    if (!value) {
      continue;
    }
    if (!result.cardMessage && isGiftMessageKey(key)) {
      result.cardMessage = value;
    } else if (!result.deliveryDateText && isDeliveryDateKey(key)) {
      result.deliveryDateText = value;
    } else if (!result.deliveryTimeSlot && isDeliveryTimeKey(key)) {
      result.deliveryTimeSlot = value;
    }
  }
  return result;
}

function composeCardMessage(map, giftBody) {
  const from = firstMatchingValue(
    map,
    (key) => key === "from" || key === "from name" || key === "sender",
  );
  const to = firstMatchingValue(
    map,
    (key) =>
      key === "to" ||
      key === "to name" ||
      key === "for" ||
      key === "gift to",
  );
  const lines = [];
  if (to) {
    lines.push(`To: ${to}`);
  }
  if (from) {
    lines.push(`From: ${from}`);
  }
  if (giftBody) {
    if (lines.length) {
      lines.push("");
    }
    lines.push(giftBody);
  }
  return lines.join("\n");
}

function cardMessageFromPropertyRows(properties) {
  const map = new Map();
  if (Array.isArray(properties)) {
    for (const row of properties) {
      addAttribute(map, row?.name || row?.key, row?.value);
    }
  } else if (properties && typeof properties === "object") {
    for (const [name, value] of Object.entries(properties)) {
      addAttribute(map, name, value);
    }
  }
  const giftBody = firstMatchingValue(map, isGiftMessageKey);
  return composeCardMessage(map, giftBody);
}

function fulfillmentOrdersDate(order) {
  const rows = order?.fulfillment_orders;
  if (!Array.isArray(rows)) {
    return null;
  }
  for (const row of rows) {
    const parsed = parseFlexibleDeliveryDate(row?.fulfill_at || row?.fulfillAt);
    if (parsed) {
      return parsed;
    }
  }
  return null;
}

function extractShopifyFulfillmentDetails(order) {
  const map = collectAttributeMap(order);
  const fromNote = extractLabeledNoteFields(order?.note);

  const giftBody =
    firstMatchingValue(map, isGiftMessageKey) || fromNote.cardMessage || "";
  const cardMessage = composeCardMessage(map, giftBody);

  const dateText =
    firstMatchingValue(map, isDeliveryDateKey) || fromNote.deliveryDateText || "";
  const deliveryDate =
    parseFlexibleDeliveryDate(dateText) || fulfillmentOrdersDate(order);

  const timeText =
    firstMatchingValue(map, isDeliveryTimeKey) || fromNote.deliveryTimeSlot || "";
  let deliveryTimeSlot = normalizeTimeSlot(timeText);
  if (!deliveryTimeSlot && deliveryDate) {
    deliveryTimeSlot = DEFAULT_SHOPIFY_DELIVERY_TIME_SLOT;
  }

  const pickupValue = firstMatchingValue(map, isPickupPropertyKey);
  const deliveryMethod =
    normalizeDeliveryMethod(firstMatchingValue(map, isDeliveryMethodKey)) ||
    (pickupValue ? "Pick Up" : "");

  let resolvedDate = deliveryDate;
  let resolvedSlot = deliveryTimeSlot;
  if (pickupValue) {
    if (!resolvedDate) {
      resolvedDate = parseFlexibleDeliveryDate(pickupValue);
    }
    const pickupSlot = normalizeTimeSlot(pickupValue);
    if (!resolvedSlot || resolvedSlot === DEFAULT_SHOPIFY_DELIVERY_TIME_SLOT) {
      if (looksLikeNormalizedSlot(pickupSlot)) {
        resolvedSlot = pickupSlot;
      }
    }
  }

  const propertyAddress = firstMatchingValue(map, isPropertyAddressKey);
  const recipientName = firstMatchingValue(map, isRecipientNameKey);
  const recipientPhone = firstMatchingValue(map, isRecipientPhoneKey);
  const senderPhone = firstMatchingValue(map, isSenderPhoneKey);
  const remarks = firstMatchingValue(map, isRemarksKey);
  const addons = collectMatchingValues(map, isAddonKey);

  return {
    cardMessage,
    deliveryDate: resolvedDate,
    deliveryTimeSlot: resolvedSlot,
    deliveryMethod,
    propertyAddress: propertyAddress || "",
    recipientName: recipientName || "",
    recipientPhone: recipientPhone || "",
    senderPhone: senderPhone || "",
    remarks: remarks || "",
    addons,
    isDeliveryService: deliveryMethod === "Delivery",
  };
}

module.exports = {
  DEFAULT_SHOPIFY_DELIVERY_TIME_SLOT,
  extractShopifyFulfillmentDetails,
  parseFlexibleDeliveryDate,
  normalizeTimeSlot,
  normalizeDeliveryMethod,
  extractSingaporePostal,
  isInternalPropertyKey,
  isDedicatedCheckoutPropertyKey,
  looksLikeDeliveryMethod,
  looksLikePickupMethod,
  normalizeAttrKey,
  cardMessageFromPropertyRows,
};
