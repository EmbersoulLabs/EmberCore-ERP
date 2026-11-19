/**
 * Maps a Shopify orders/paid payload into review + official order fields.
 * Official orders are created only after human approval.
 */

const {
  isTrustworthyImageUrl,
  normalizeShopifyResourceId,
} = require("./line_item_image");
const {
  isInternalPropertyKey,
  isDedicatedCheckoutPropertyKey,
  normalizeAttrKey,
  normalizeDeliveryMethod,
  cardMessageFromPropertyRows,
} = require("./fulfillment_attributes");
const { canonicalCompanyDocId } = require("./staff_auth");

const DELIVERY_FEE_LINE_NAME = "Delivery fee";

const ORDER_CREATED_NOTICE_ROLES = new Set([
  "superadmin",
  "admin",
  "director",
  "manager",
  "senior_florist",
  "florist",
]);

function personName(first, last) {
  return [first, last].filter(Boolean).join(" ").trim();
}

/// Sender is the Shopify customer. Billing name is only a fallback.
function pickSenderName(order) {
  const customer = order.customer || {};
  const billing = order.billing_address || {};
  return (
    personName(customer.first_name, customer.last_name) ||
    personName(billing.first_name, billing.last_name)
  );
}

function pickCustomerName(order) {
  return pickSenderName(order) || order.email || "Shopify Customer";
}

function formatShopifyBillingBlock({ senderName, senderPhone, address }) {
  return [senderName, senderPhone, address]
    .map((value) => (value == null ? "" : String(value).trim()))
    .filter(Boolean)
    .join("\n");
}

function pickRecipientName(order, propertyName = "") {
  const fromProperty = String(propertyName || "").trim();
  if (fromProperty) {
    return fromProperty;
  }
  const shipping = order.shipping_address || {};
  const shippingName = [shipping.first_name, shipping.last_name]
    .filter(Boolean)
    .join(" ")
    .trim();
  return shippingName;
}

function formatShippingAddress(address) {
  if (!address) {
    return "";
  }
  return [
    address.address1,
    address.address2,
    address.city,
    address.province,
    address.zip,
    address.country,
  ]
    .filter(Boolean)
    .join(", ");
}

function addressHasLocation(address) {
  if (!address || typeof address !== "object") {
    return false;
  }
  return Boolean(address.address1 || address.city || address.zip);
}

function resolveOrderType(order, extras = {}) {
  const method = normalizeDeliveryMethod(extras.deliveryMethod);
  if (method === "Pick Up") {
    return "Pick Up";
  }
  if (method === "Delivery" || extras.isDeliveryService) {
    return "Delivery";
  }
  if (addressHasLocation(order?.shipping_address)) {
    return "Delivery";
  }
  if (String(extras.propertyAddress || "").trim()) {
    return "Delivery";
  }
  return "Pick Up";
}

function mapLineItemProperties(properties) {
  const rows = [];
  if (Array.isArray(properties)) {
    for (const row of properties) {
      const name = String(row?.name || row?.key || "").trim();
      const value = row?.value == null ? "" : String(row.value).trim();
      if (!name || !value) {
        continue;
      }
      if (isInternalPropertyKey(normalizeAttrKey(name))) {
        continue;
      }
      rows.push({ name, value });
    }
    return rows;
  }
  if (properties && typeof properties === "object") {
    for (const [name, raw] of Object.entries(properties)) {
      const value = raw == null ? "" : String(raw).trim();
      if (!name || !value) {
        continue;
      }
      if (isInternalPropertyKey(normalizeAttrKey(name))) {
        continue;
      }
      rows.push({ name, value });
    }
  }
  return rows;
}

function lineItemRemark(properties) {
  const addons = [];
  const extras = [];
  const remarks = [];
  for (const row of properties || []) {
    const key = normalizeAttrKey(row.name);
    const value = String(row.value || "").trim();
    if (!key || !value) {
      continue;
    }
    if (key === "addon" || key === "add on" || key === "add ons") {
      addons.push(`Add-on: ${value}`);
      continue;
    }
    if (key === "remarks" || key === "remark") {
      remarks.push(value);
      continue;
    }
    if (isDedicatedCheckoutPropertyKey(key)) {
      continue;
    }
    extras.push(`${row.name}: ${value}`);
  }
  return [...addons, ...extras, ...remarks].join("\n");
}

function isDeliveryFeeLineName(name) {
  return String(name || "").trim().toLowerCase() === DELIVERY_FEE_LINE_NAME.toLowerCase();
}

function mapShopifyShippingLines(order, existingItems = []) {
  if ((existingItems || []).some((item) => isDeliveryFeeLineName(item?.name || item?.title))) {
    return [];
  }
  const rows = order?.shipping_lines;
  if (!Array.isArray(rows) || rows.length === 0) {
    return [];
  }
  const items = [];
  for (const row of rows) {
    const price = Number(row?.price ?? row?.discounted_price ?? 0);
    if (!(price > 0)) {
      continue;
    }
    items.push({
      name: DELIVERY_FEE_LINE_NAME,
      title: DELIVERY_FEE_LINE_NAME,
      variantTitle: "",
      qty: 1,
      price,
      subtotal: price,
      sku: "",
      productId: "",
      variantId: "",
      imageUrl: null,
      imageSource: "none",
      properties: [],
    });
  }
  return items;
}

function lineItemSummary(lineItems) {
  if (!Array.isArray(lineItems) || lineItems.length === 0) {
    return "Shopify order";
  }
  return lineItems
    .slice(0, 3)
    .map((item) => {
      const qty = Number(item.quantity || 1);
      const name = item.name || item.title || "Item";
      return `${qty}x ${name}`;
    })
    .join(", ");
}

function mapShopifyReviewLineItems(lineItems) {
  if (!Array.isArray(lineItems)) {
    return [];
  }
  return lineItems.map((item) => {
    const qty = Number(item.quantity || 1);
    const price = Number(item.price || 0);
    const variantTitle = item.variant_title ? String(item.variant_title) : "";
    const title = item.name || item.title || "Shopify item";
    const webhookImage = isTrustworthyImageUrl(item.image)
      ? String(item.image).trim()
      : isTrustworthyImageUrl(item.imageUrl)
        ? String(item.imageUrl).trim()
        : "";
    const properties = mapLineItemProperties(item.properties);
    const cardMessage = cardMessageFromPropertyRows(properties);
    return {
      name: variantTitle ? `${title} (${variantTitle})` : String(title),
      title: String(title),
      variantTitle,
      qty,
      price,
      subtotal: price * qty,
      sku: item.sku ? String(item.sku) : "",
      productId: normalizeShopifyResourceId(item.product_id || item.productId),
      variantId: normalizeShopifyResourceId(item.variant_id || item.variantId),
      imageUrl: webhookImage || null,
      imageSource: webhookImage ? "webhook" : "none",
      properties,
      ...(cardMessage ? { cardMessage } : {}),
    };
  });
}

function mapShopifyLineItems(
  lineItems,
  orderRef,
  companyRef,
  erpOrderId,
  { status = "processing" } = {},
) {
  const mapped = mapShopifyReviewLineItems(lineItems);
  return mapped.map((item) => ({
    orderRef,
    companyRef,
    name: item.name,
    qty: item.qty,
    price: item.price,
    subtotal: item.subtotal,
    sku: item.sku,
    orderId: erpOrderId,
    status,
    image: isTrustworthyImageUrl(item.imageUrl) ? item.imageUrl : "",
  }));
}

function mapReviewLineItemsToOrderItems(
  lineItems,
  orderRef,
  companyRef,
  erpOrderId,
  { status = "processing" } = {},
) {
  if (!Array.isArray(lineItems)) {
    return [];
  }
  return lineItems.map((item) => {
    const qty = Number(item.qty || item.quantity || 1);
    const price = Number(item.price || 0);
    const image = isTrustworthyImageUrl(item.imageUrl)
      ? String(item.imageUrl).trim()
      : isTrustworthyImageUrl(item.image)
        ? String(item.image).trim()
        : "";
    const properties = Array.isArray(item.properties) ? item.properties : [];
    const remark = lineItemRemark(properties);
    const cardmessage =
      String(item.cardMessage || item.cardmessage || "").trim() ||
      cardMessageFromPropertyRows(properties);
    return {
      orderRef,
      companyRef,
      name: item.name || item.title || "Shopify item",
      qty,
      price,
      subtotal: price * qty,
      sku: item.sku || "",
      orderId: erpOrderId,
      status,
      image,
      ...(remark ? { Remark: remark } : {}),
      ...(cardmessage ? { cardmessage } : {}),
    };
  });
}

function isGreetingCardProductLine(item) {
  return !isDeliveryFeeLineName(item?.name);
}

/// Multi-product Shopify orders: copy the order-level gift message onto
/// merchandise lines that have no line-item Gift Message of their own.
function syncedOrderCardMessage(mappedItems, fallback) {
  const filled = (mappedItems || []).filter(
    (item) =>
      isGreetingCardProductLine(item) &&
      String(item.cardmessage || "").trim(),
  );
  if (filled.length === 0) {
    return String(fallback || "").trim();
  }
  const unique = new Set(filled.map((item) => String(item.cardmessage).trim()));
  if (unique.size === 1) {
    return filled[0].cardmessage.trim();
  }
  return filled
    .map((item) => {
      const name = String(item.name || item.title || "Item").trim() || "Item";
      return `${name}\n${String(item.cardmessage).trim()}`;
    })
    .join("\n\n");
}

function applySharedCardMessageToEmptyMappedItems(mappedItems, orderCardMessage) {
  if (!Array.isArray(mappedItems) || mappedItems.length < 2) {
    return mappedItems;
  }
  const products = mappedItems.filter(isGreetingCardProductLine);
  if (products.length < 2) {
    return mappedItems;
  }
  const fallback = String(orderCardMessage || "").trim();
  if (!fallback) {
    return mappedItems;
  }
  for (const item of mappedItems) {
    if (!isGreetingCardProductLine(item)) {
      continue;
    }
    if (String(item.cardmessage || "").trim()) {
      continue;
    }
    item.cardmessage = fallback;
  }
  return mappedItems;
}

function buildShopifyNoticeMessage({
  externalOrderName,
  customerName,
  totalAmount,
}) {
  return [
    `Order: ${externalOrderName}`,
    `Customer: ${customerName}`,
    `Total: ${totalAmount}`,
    "Source: Shopify",
  ].join("\n");
}

function isActiveStaffRecipient(userData) {
  if (userData.is_active === false) {
    return false;
  }
  return ORDER_CREATED_NOTICE_ROLES.has(userData.role);
}

function recipientMatchesNoticeCompany(userData, companyId) {
  const userCompanyId = canonicalCompanyDocId(userData?.companyRef?.id || "");
  const target = canonicalCompanyDocId(companyId || "");
  if (String(userData?.role || "") === "superadmin") {
    return !userCompanyId || userCompanyId === target;
  }
  return Boolean(userCompanyId) && userCompanyId === target;
}

function staffNoticeRecipientRef(db, userDoc) {
  const data = userDoc.data();
  const uid = data.uid || userDoc.id;
  return db.collection("users").doc(uid);
}

module.exports = {
  ORDER_CREATED_NOTICE_ROLES,
  pickCustomerName,
  pickSenderName,
  formatShopifyBillingBlock,
  pickRecipientName,
  formatShippingAddress,
  addressHasLocation,
  resolveOrderType,
  lineItemSummary,
  DELIVERY_FEE_LINE_NAME,
  lineItemRemark,
  mapShopifyReviewLineItems,
  mapShopifyShippingLines,
  mapShopifyLineItems,
  mapReviewLineItemsToOrderItems,
  buildShopifyNoticeMessage,
  isActiveStaffRecipient,
  recipientMatchesNoticeCompany,
  syncedOrderCardMessage,
  applySharedCardMessageToEmptyMappedItems,
  staffNoticeRecipientRef,
};
