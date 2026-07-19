const test = require("node:test");
const assert = require("node:assert/strict");
const {
  maskRecipientName,
  phoneLast4,
  phonesMatchLast4,
  isPickupOrder,
  isRetailOrder,
  isTrackableOrder,
  buildSafeTrackingPayload,
  shouldAutoSendTrackingLink,
} = require("../functions/order_tracking");

test("maskRecipientName keeps first three of first word", () => {
  assert.equal(maskRecipientName("Ali Hassan"), "Ali***");
  assert.equal(maskRecipientName("Jo"), "Jo***");
  assert.equal(maskRecipientName(""), "");
});

test("phonesMatchLast4 compares last four digits", () => {
  assert.equal(phoneLast4("+65 9123 4567"), "4567");
  assert.equal(phonesMatchLast4("+65 9123 4567", "4567"), true);
  assert.equal(phonesMatchLast4("91234567", "1234"), false);
  assert.equal(phonesMatchLast4("91234567", "567"), false);
});

test("order type classification", () => {
  assert.equal(isRetailOrder({ orderType: "Retail" }), true);
  assert.equal(isPickupOrder({ pickup_delivery: "Pick Up" }), true);
  assert.equal(isTrackableOrder({ orderType: "Delivery" }), true);
  assert.equal(isTrackableOrder({ orderType: "Retail" }), false);
});

test("buildSafeTrackingPayload hides amounts and masks recipient", () => {
  const payload = buildSafeTrackingPayload({
    order: {
      order_id: "ORD-1",
      Order_Id: "ORD-1",
      status: "out_of_delivery",
      pickup_delivery: "Delivery",
      delivery_date: new Date("2026-07-20T00:00:00Z"),
      delivery_time_slot: "09:00-12:00",
      recipient_name: "Ali Hassan",
      delivery_proof_url: "https://example.com/p.jpg",
      totalAmount: 99.5,
      discount: 5,
    },
    orderDocId: "abc",
    company: { Company_name: "Ember Florist", logo: "https://example.com/logo.png" },
  });

  assert.equal(payload.orderId, "ORD-1");
  assert.equal(payload.recipientNameMasked, "Ali***");
  assert.equal(payload.companyName, "Ember Florist");
  assert.deepEqual(payload.proofUrls, ["https://example.com/p.jpg"]);
  assert.equal(payload.totalAmount, undefined);
  assert.equal(payload.discount, undefined);
  assert.ok(!("amountPaid" in payload));
});

test("shouldAutoSendTrackingLink gates by type and status", () => {
  assert.equal(
    shouldAutoSendTrackingLink(
      { pickup_delivery: "Delivery" },
      "out_of_delivery",
    ),
    true,
  );
  assert.equal(
    shouldAutoSendTrackingLink(
      { pickup_delivery: "Pick Up" },
      "ready_to_delivery",
    ),
    true,
  );
  assert.equal(
    shouldAutoSendTrackingLink(
      { pickup_delivery: "Delivery" },
      "ready_to_delivery",
    ),
    false,
  );
  assert.equal(
    shouldAutoSendTrackingLink({ orderType: "Retail" }, "out_of_delivery"),
    false,
  );
});
