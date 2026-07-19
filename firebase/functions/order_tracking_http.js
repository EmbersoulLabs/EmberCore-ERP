/**
 * HTTPS handlers for public customer order tracking.
 */
const {
  TRACKING_TOKEN_COLLECTION,
  phonesMatchLast4,
  isTrackableOrder,
  recipientPhone,
  buildSafeTrackingPayload,
  newTrackingToken,
} = require("./order_tracking");

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

function readRequestBody(req) {
  if (req.method === "GET") {
    return {
      token: String(req.query.token || req.query.t || "").trim(),
      orderId: String(req.query.orderId || req.query.order_id || "").trim(),
      phoneLast4: String(
        req.query.phoneLast4 || req.query.phone_last4 || "",
      ).trim(),
    };
  }
  const body = req.body && typeof req.body === "object" ? req.body : {};
  return {
    token: String(body.token || body.t || "").trim(),
    orderId: String(body.orderId || body.order_id || "").trim(),
    phoneLast4: String(body.phoneLast4 || body.phone_last4 || "").trim(),
  };
}

async function loadCompany(db, companyRef) {
  if (!companyRef) {
    return null;
  }
  const snap = await companyRef.get();
  return snap.exists ? snap.data() : null;
}

async function resolveOrderByToken(db, token) {
  const tokenSnap = await db
    .collection(TRACKING_TOKEN_COLLECTION)
    .doc(token)
    .get();
  if (!tokenSnap.exists) {
    return null;
  }
  const data = tokenSnap.data() || {};
  const orderRef = data.order_ref;
  if (!orderRef) {
    return null;
  }
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    return null;
  }
  return { orderSnap, companyRef: data.company_ref || orderSnap.data()?.companyRef };
}

async function resolveOrderByIdAndPhone(db, orderId, phoneLast4) {
  const snap = await db
    .collection("orders")
    .where("Order_Id", "==", orderId)
    .limit(5)
    .get();
  if (snap.empty) {
    return null;
  }
  for (const doc of snap.docs) {
    const order = doc.data() || {};
    if (!isTrackableOrder(order)) {
      continue;
    }
    if (phonesMatchLast4(recipientPhone(order), phoneLast4)) {
      return { orderSnap: doc, companyRef: order.companyRef || null };
    }
  }
  return null;
}

/**
 * Ensures an order has a tracking token document + field.
 * @returns {Promise<string>} token
 */
async function ensureTrackingTokenForOrder(db, orderRef, orderData) {
  const existing = String(orderData.tracking_token || "").trim();
  if (existing) {
    const tokenRef = db.collection(TRACKING_TOKEN_COLLECTION).doc(existing);
    const tokenSnap = await tokenRef.get();
    if (tokenSnap.exists) {
      return existing;
    }
  }

  const token = newTrackingToken();
  const companyRef = orderData.companyRef || null;
  await db.collection(TRACKING_TOKEN_COLLECTION).doc(token).set({
    order_ref: orderRef,
    company_ref: companyRef,
    created_at: new Date(),
  });
  await orderRef.update({ tracking_token: token });
  return token;
}

async function handleGetOrderTracking(db, req, res) {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "GET" && req.method !== "POST") {
    res.set("Allow", "GET, POST, OPTIONS");
    res.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const { token, orderId, phoneLast4 } = readRequestBody(req);
  let resolved = null;

  try {
    if (token) {
      resolved = await resolveOrderByToken(db, token);
    } else if (orderId && phoneLast4) {
      resolved = await resolveOrderByIdAndPhone(db, orderId, phoneLast4);
    } else {
      res.status(400).json({
        error: "invalid_request",
        message: "Provide token, or orderId + phoneLast4.",
      });
      return;
    }

    if (!resolved) {
      res.status(404).json({ error: "not_found" });
      return;
    }

    const order = resolved.orderSnap.data() || {};
    if (!isTrackableOrder(order)) {
      res.status(404).json({ error: "not_found" });
      return;
    }

    const company = await loadCompany(db, resolved.companyRef);
    const payload = buildSafeTrackingPayload({
      order,
      orderDocId: resolved.orderSnap.id,
      company,
    });
    res.status(200).json({ ok: true, tracking: payload });
  } catch (error) {
    console.error("getOrderTracking failed", error);
    res.status(500).json({ error: "internal" });
  }
}

module.exports = {
  handleGetOrderTracking,
  ensureTrackingTokenForOrder,
  setCors,
};
