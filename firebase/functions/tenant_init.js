/**
 * Shared Firestore bootstrap for a new tenant company document.
 */
const DEFAULT_STAFF_ROLES = ["admin", "senior_florist", "florist", "driver"];
const DEFAULT_CATEGORIES = ["AdHoc"];

const GENERIC_PLATFORM_CONFIG = {
  industry_key: "generic",
  enabled_modules: [
    "orders",
    "pos",
    "fieldService",
    "drivers",
    "customers",
    "invoices",
    "products",
    "reports",
    "customerBroadcast",
    "whatsappImport",
  ],
  order_types: ["OnSite", "WalkIn", "Remote"],
  order_id_prefix: "EC",
  field_labels_en: {
    recipient_name: "Contact name",
    recipient_phone: "Contact phone",
    service_notes: "Service notes",
    scheduled_date: "Scheduled date",
    time_window: "Time window",
    service_address: "Service address",
    customer_id: "Customer ID",
  },
  field_labels_zh: {
    recipient_name: "联系人",
    recipient_phone: "联系电话",
    service_notes: "服务备注",
    scheduled_date: "预约日期",
    time_window: "时间段",
    service_address: "服务地址",
    customer_id: "客户编号",
  },
  status_labels_en: {
    pending: "Pending",
    processing: "Processing",
    ready: "Ready",
    out_for_delivery: "Out for delivery",
    completed: "Completed",
    cancelled: "Cancelled",
  },
  driver_role_label_en: "Field staff",
  driver_role_label_zh: "外勤人员",
};

/**
 * Appends tenant init writes to an existing batch.
 *
 * @param {FirebaseFirestore.WriteBatch} batch
 * @param {FirebaseFirestore.Firestore} db
 * @param {FirebaseFirestore.DocumentReference} companyRef
 * @param {string} companyId
 * @param {FirebaseFirestore.FieldValue} serverTime
 */
function appendTenantInitBatch(batch, db, companyRef, companyId, serverTime) {
  batch.set(db.collection("tenant_platform_config").doc(companyId), {
    ...GENERIC_PLATFORM_CONFIG,
    updated_at: new Date().toISOString(),
  });
  batch.set(db.collection("staff_roles").doc(companyId), {
    companyRef,
    roles: DEFAULT_STAFF_ROLES,
    updated_time: serverTime,
  });
  batch.set(db.collection("role_permissions").doc(companyId), {
    companyRef,
    roles: {},
    updated_time: serverTime,
  });
  batch.set(db.collection("product_categories").doc(companyId), {
    companyRef,
    categories: DEFAULT_CATEGORIES,
    updated_time: serverTime,
  });
  for (const suffix of ["delivery", "retail", "invoice", "customer"]) {
    batch.set(db.collection("counter").doc(`${companyId}_${suffix}`), {
      current: 0,
      comR: companyRef,
    });
  }
}

module.exports = {
  GENERIC_PLATFORM_CONFIG,
  DEFAULT_STAFF_ROLES,
  DEFAULT_CATEGORIES,
  appendTenantInitBatch,
};
