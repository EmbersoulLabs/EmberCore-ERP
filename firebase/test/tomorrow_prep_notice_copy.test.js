const test = require("node:test");
const assert = require("node:assert/strict");

const {
  TOMORROW_PREP_TITLE,
  buildTomorrowPrepNoticeContent,
  applyTomorrowPrepTemplate,
} = require("../functions/tomorrow_prep_notice_copy");

test("buildTomorrowPrepNoticeContent — no deliveries", () => {
  const content = buildTomorrowPrepNoticeContent({
    totalDelivery: 0,
    notStartedCount: 0,
  });
  assert.equal(content.title, TOMORROW_PREP_TITLE);
  assert.equal(content.body, "No deliveries scheduled for tomorrow.");
  assert.equal(content.status, "none");
});

test("buildTomorrowPrepNoticeContent — one delivery pending", () => {
  const content = buildTomorrowPrepNoticeContent({
    totalDelivery: 1,
    notStartedCount: 1,
  });
  assert.equal(
    content.body,
    "1 delivery scheduled\n1 order pending preparation",
  );
  assert.equal(content.status, "pending");
});

test("buildTomorrowPrepNoticeContent — multiple deliveries pending", () => {
  const content = buildTomorrowPrepNoticeContent({
    totalDelivery: 8,
    notStartedCount: 3,
  });
  assert.equal(
    content.body,
    "8 deliveries scheduled\n3 orders pending preparation",
  );
});

test("buildTomorrowPrepNoticeContent — all ready", () => {
  const content = buildTomorrowPrepNoticeContent({
    totalDelivery: 8,
    notStartedCount: 0,
  });
  assert.equal(content.body, "8 deliveries scheduled\nAll orders are ready.");
  assert.equal(content.status, "ready");
});

test("applyTomorrowPrepTemplate supports tenant override", () => {
  const content = buildTomorrowPrepNoticeContent({
    totalDelivery: 2,
    notStartedCount: 1,
  });
  const body = applyTomorrowPrepTemplate("{line1} · {line2}", content);
  assert.equal(body, "2 deliveries scheduled · 1 order pending preparation");
});
