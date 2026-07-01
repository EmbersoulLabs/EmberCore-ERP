const TOMORROW_PREP_TITLE = "Tomorrow's Preparation";

function deliveryScheduledLine(deliveryCount) {
  if (deliveryCount === 1) {
    return "1 delivery scheduled";
  }
  return `${deliveryCount} deliveries scheduled`;
}

function pendingPreparationLine(pendingCount) {
  if (pendingCount === 1) {
    return "1 order pending preparation";
  }
  return `${pendingCount} orders pending preparation`;
}

/**
 * Professional SaaS copy for tomorrow prep staff notices.
 * @returns {{ title: string, body: string, status: 'none'|'pending'|'ready', deliveryCount: number, pendingCount: number }}
 */
function buildTomorrowPrepNoticeContent(summary) {
  const deliveryCount = summary.totalDelivery ?? 0;
  const pendingCount = summary.notStartedCount ?? 0;

  if (deliveryCount === 0) {
    return {
      title: TOMORROW_PREP_TITLE,
      body: "No deliveries scheduled for tomorrow.",
      status: "none",
      deliveryCount: 0,
      pendingCount: 0,
    };
  }

  const line1 = deliveryScheduledLine(deliveryCount);
  if (pendingCount === 0) {
    return {
      title: TOMORROW_PREP_TITLE,
      body: `${line1}\nAll orders are ready.`,
      status: "ready",
      deliveryCount,
      pendingCount: 0,
    };
  }

  const line2 = pendingPreparationLine(pendingCount);
  return {
    title: TOMORROW_PREP_TITLE,
    body: `${line1}\n${line2}`,
    status: "pending",
    deliveryCount,
    pendingCount,
  };
}

/**
 * Optional tenant override: {line1}, {line2}, {body}, {delivery_count}, {pending_count}
 */
function applyTomorrowPrepTemplate(template, content) {
  if (!template || typeof template !== "string" || !template.trim()) {
    return content.body;
  }
  const line1 =
    content.deliveryCount === 0
      ? ""
      : deliveryScheduledLine(content.deliveryCount);
  const line2 =
    content.deliveryCount === 0
      ? "No deliveries scheduled for tomorrow."
      : content.pendingCount === 0
        ? "All orders are ready."
        : pendingPreparationLine(content.pendingCount);

  return template.replace(/\{(\w+)\}/g, (_, name) => {
    switch (name) {
      case "line1":
        return line1;
      case "line2":
        return line2;
      case "body":
        return content.body;
      case "delivery_count":
        return String(content.deliveryCount);
      case "pending_count":
        return String(content.pendingCount);
      default:
        return "";
    }
  });
}

module.exports = {
  TOMORROW_PREP_TITLE,
  deliveryScheduledLine,
  pendingPreparationLine,
  buildTomorrowPrepNoticeContent,
  applyTomorrowPrepTemplate,
};
