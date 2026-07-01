const test = require("node:test");
const assert = require("node:assert/strict");
const {
  isBusinessPlanCompany,
  BUSINESS_PLAN,
} = require("../functions/branch_provisioning");

test("isBusinessPlanCompany detects business tier", () => {
  assert.equal(
    isBusinessPlanCompany({ plan_tier: BUSINESS_PLAN }),
    true,
  );
  assert.equal(isBusinessPlanCompany({ plan_tier: "starter" }), false);
});
