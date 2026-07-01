const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

const {
  GENERIC_PLATFORM_CONFIG,
} = require("../functions/registration_provisioning");

describe("registration_provisioning", () => {
  it("generic platform config uses EC prefix and neutral order types", () => {
    assert.equal(GENERIC_PLATFORM_CONFIG.order_id_prefix, "EC");
    assert.deepEqual(GENERIC_PLATFORM_CONFIG.order_types, [
      "OnSite",
      "WalkIn",
      "Remote",
    ]);
    assert.equal(GENERIC_PLATFORM_CONFIG.industry_key, "generic");
  });

  it("generic platform config enables core SaaS modules", () => {
    const modules = GENERIC_PLATFORM_CONFIG.enabled_modules;
    assert.ok(modules.includes("orders"));
    assert.ok(modules.includes("whatsappImport"));
    assert.ok(modules.includes("customerBroadcast"));
  });

  it("field labels are neutral not florist-specific", () => {
    assert.equal(
      GENERIC_PLATFORM_CONFIG.field_labels_en.recipient_name,
      "Contact name",
    );
    assert.notEqual(
      GENERIC_PLATFORM_CONFIG.field_labels_en.service_notes,
      "Card message",
    );
  });
});
