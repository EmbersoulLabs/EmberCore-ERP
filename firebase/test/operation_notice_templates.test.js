const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DEFAULT_OPERATION_NOTICE_TEMPLATES,
  parseOperationNoticeTemplates,
  resolveOperationNoticeTemplate,
  formatOperationNoticeTemplate,
} = require("../functions/operation_notice_templates");
const {
  calendarDay,
  buildTomorrowPrepNotice,
  buildTodayOpsMessage,
} = require("../functions/operation_reminders");

test("formatOperationNoticeTemplate replaces placeholders", () => {
  const message = formatOperationNoticeTemplate(
    "明日 ({target_date})：{total_delivery} 单，{not_started} 单未开始",
    {
      target_date: "15 Jun 2026",
      total_delivery: 4,
      not_started: 3,
    },
  );
  assert.equal(message, "明日 (15 Jun 2026)：4 单，3 单未开始");
});

test("resolveOperationNoticeTemplate falls back to defaults", () => {
  assert.equal(
    resolveOperationNoticeTemplate(null, "today_ops"),
    DEFAULT_OPERATION_NOTICE_TEMPLATES.today_ops,
  );
  assert.equal(
    resolveOperationNoticeTemplate({ today_ops: "Custom {target_date}" }, "today_ops"),
    "Custom {target_date}",
  );
});

test("parseOperationNoticeTemplates returns null when empty", () => {
  assert.equal(parseOperationNoticeTemplates(null), null);
  assert.equal(parseOperationNoticeTemplates({}), null);
});

test("buildTomorrowPrepNotice uses custom tenant template", () => {
  const tomorrow = calendarDay(new Date(2026, 5, 15));
  const notice = buildTomorrowPrepNotice({
    targetDays: [tomorrow],
    summary: {
      totalDelivery: 4,
      notStartedCount: 3,
      incompleteCount: 4,
    },
    templates: {
      tomorrow_prep: "{line1} · {line2}",
    },
  });

  assert.equal(notice.body, "4 deliveries scheduled · 3 orders pending preparation");
});

test("buildTodayOpsMessage uses default when template key missing", () => {
  const today = calendarDay(new Date(2026, 5, 15));
  const message = buildTodayOpsMessage({
    targetDay: today,
    summary: {
      totalDelivery: 2,
      notStartedCount: 1,
      incompleteCount: 2,
    },
    templates: {
      tomorrow_prep: "ignored",
    },
  });

  assert.equal(
    message,
    "Today (15 Jun 2026): 2 delivery order(s) (1 not started)",
  );
});
