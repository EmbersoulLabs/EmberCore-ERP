const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

const {
  defaultSubscriptionFields,
  isSubscriptionWriteAllowed,
  mapStripeSubscriptionStatus,
  priceIdForPlan,
} = require("../functions/stripe_billing");

describe("stripe_billing helpers", () => {
  it("defaultSubscriptionFields sets trialing starter", () => {
    const fields = defaultSubscriptionFields("starter");
    assert.equal(fields.plan_tier, "starter");
    assert.equal(fields.subscription_status, "trialing");
    assert.equal(fields.max_staff_seats, 5);
    assert.equal(fields.max_orders_per_month, 500);
    assert.ok(fields.trial_ends_at);
  });

  it("legacy company without status allows writes", () => {
    assert.equal(isSubscriptionWriteAllowed({ is_active: true }), true);
  });

  it("past_due blocks writes", () => {
    assert.equal(
      isSubscriptionWriteAllowed({
        is_active: true,
        subscription_status: "past_due",
      }),
      false,
    );
  });

  it("active trialing before trial end allows writes", () => {
    const future = new Date(Date.now() + 86400000);
    assert.equal(
      isSubscriptionWriteAllowed({
        is_active: true,
        subscription_status: "trialing",
        trial_ends_at: { toDate: () => future },
      }),
      true,
    );
  });

  it("maps stripe statuses", () => {
    assert.equal(mapStripeSubscriptionStatus("active"), "active");
    assert.equal(mapStripeSubscriptionStatus("past_due"), "past_due");
    assert.equal(mapStripeSubscriptionStatus("canceled"), "cancelled");
  });

  it("priceIdForPlan returns empty without env", () => {
    assert.equal(priceIdForPlan("starter", "month"), "");
  });
});
