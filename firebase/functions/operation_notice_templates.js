const DEFAULT_OPERATION_NOTICE_TEMPLATES = {
  tomorrow_prep: "{line1}\n{line2}",
  tomorrow_prep_weekend: "{line1}\n{line2}",
  today_ops:
    "Today ({target_date}): {total_delivery} delivery order(s) ({not_started} not started)",
};

function parseOperationNoticeTemplates(raw) {
  if (!raw || typeof raw !== "object") {
    return null;
  }
  const parsed = {
    tomorrow_prep:
      typeof raw.tomorrow_prep === "string" ? raw.tomorrow_prep.trim() : "",
    tomorrow_prep_weekend:
      typeof raw.tomorrow_prep_weekend === "string"
        ? raw.tomorrow_prep_weekend.trim()
        : "",
    today_ops: typeof raw.today_ops === "string" ? raw.today_ops.trim() : "",
  };
  const hasCustom = Object.values(parsed).some((value) => value.length > 0);
  return hasCustom ? parsed : null;
}

function resolveOperationNoticeTemplate(templates, key) {
  const custom = templates?.[key];
  if (typeof custom === "string" && custom.trim().length > 0) {
    return custom.trim();
  }
  return DEFAULT_OPERATION_NOTICE_TEMPLATES[key];
}

function formatOperationNoticeTemplate(template, vars) {
  if (!template || typeof template !== "string") {
    return "";
  }
  return template.replace(/\{(\w+)\}/g, (_, name) => {
    const value = vars[name];
    return value == null ? "" : String(value);
  });
}

async function loadOperationNoticeTemplates(db, companyId) {
  if (!companyId) {
    return null;
  }
  const snap = await db.collection("tenant_platform_config").doc(companyId).get();
  if (!snap.exists) {
    return null;
  }
  return parseOperationNoticeTemplates(snap.data()?.operation_notice_templates);
}

module.exports = {
  DEFAULT_OPERATION_NOTICE_TEMPLATES,
  parseOperationNoticeTemplates,
  resolveOperationNoticeTemplate,
  formatOperationNoticeTemplate,
  loadOperationNoticeTemplates,
};
