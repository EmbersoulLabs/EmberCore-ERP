/**
 * Customer order tracking — pure helpers (no Admin SDK).
 * Safe public payload: no amounts, payments, or staff PII.
 */

const TRACKING_TOKEN_COLLECTION = "order_tracking_tokens";

function digitsOnly(value) {
  return String(value || "").replace(/\D/g, "");
}

function phoneLast4(phone) {
  const digits = digitsOnly(phone);
  if (digits.length < 4) {
    return "";
  }
  return digits.slice(-4);
}

function phonesMatchLast4(orderPhone, inputLast4) {
  const expected = phoneLast4(orderPhone);
  const actual = digitsOnly(inputLast4);
  if (!expected || actual.length !== 4) {
    return false;
  }
  return expected === actual;
}

function maskRecipientName(name) {
  const trimmed = String(name || "").trim();
  if (!trimmed) {
    return "";
  }
  const first = trimmed.split(/\s+/)[0];
  const keep = first.slice(0, Math.min(3, first.length));
  return `${keep}***`;
}

function orderTypeRaw(order) {
  const pickupDelivery = String(order.pickup_delivery || "").trim();
  const orderType = String(order.orderType || "").trim();
  return (pickupDelivery || orderType).toLowerCase();
}

function isRetailOrder(order) {
  return orderTypeRaw(order).includes("retail");
}

function isPickupOrder(order) {
  return orderTypeRaw(order).includes("pick");
}

function isTrackableOrder(order) {
  if (!order || isRetailOrder(order)) {
    return false;
  }
  return true;
}

function recipientPhone(order) {
  const recipient = String(order.recipient_phone_number || "").trim();
  if (recipient) {
    return recipient;
  }
  return String(order.customer_phone_number || "").trim();
}

function orderDisplayId(order, orderDocId) {
  const id = String(order.Order_Id || order.order_id || "").trim();
  return id || String(orderDocId || "");
}

function proofUrls(order) {
  const urls = [];
  const list = order.delivery_proof_urls;
  if (Array.isArray(list)) {
    for (const url of list) {
      if (typeof url === "string" && url.trim()) {
        urls.push(url.trim());
      }
    }
  }
  const single = String(order.delivery_proof_url || "").trim();
  if (single && !urls.includes(single)) {
    urls.unshift(single);
  }
  return urls;
}

function toIsoDate(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === "string" || typeof value === "number") {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d.toISOString();
  }
  return null;
}

function buildSafeTrackingPayload({ order, orderDocId, company }) {
  const status = order.status || order.orderstatus || "";
  return {
    orderId: orderDisplayId(order, orderDocId),
    status: String(status),
    isPickup: isPickupOrder(order),
    deliveryDate: toIsoDate(order.delivery_date),
    deliveryTimeSlot: String(order.delivery_time_slot || "").trim(),
    recipientNameMasked: maskRecipientName(order.recipient_name),
    proofUrls: proofUrls(order),
    companyName: String(company?.Company_name || company?.company_name || "").trim(),
    companyLogoUrl: String(company?.logo || "").trim(),
  };
}

function shouldAutoSendTrackingLink(order, newStatus) {
  if (!isTrackableOrder(order)) {
    return false;
  }
  const status = String(newStatus || "");
  if (isPickupOrder(order)) {
    return status === "ready_to_delivery";
  }
  return status === "out_of_delivery";
}

function newTrackingToken() {
  const crypto = require("crypto");
  return crypto.randomBytes(16).toString("hex");
}

module.exports = {
  TRACKING_TOKEN_COLLECTION,
  digitsOnly,
  phoneLast4,
  phonesMatchLast4,
  maskRecipientName,
  isRetailOrder,
  isPickupOrder,
  isTrackableOrder,
  recipientPhone,
  orderDisplayId,
  proofUrls,
  buildSafeTrackingPayload,
  shouldAutoSendTrackingLink,
  newTrackingToken,
};
