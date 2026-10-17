/**
 * Firestore security rules — tenant isolation regression tests.
 * Run: npm run test:rules (from firebase/)
 */
const fs = require("fs");
const path = require("path");
const assert = require("node:assert/strict");
const { describe, it, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "tfg-vday-rules-test";
const RULES = fs.readFileSync(
  path.resolve(__dirname, "../firestore.rules"),
  "utf8",
);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc("Companies/companyA").set({ Company_name: "A", is_active: true });
    await db.doc("Companies/companyB").set({ Company_name: "B", is_active: true });

    await db.doc("users/driverA").set({
      role: "driver",
      email: "driverA@test.com",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("users/staffB").set({
      role: "senior_florist",
      email: "staffB@test.com",
      companyRef: db.doc("Companies/companyB"),
    });
    await db.doc("users/superA").set({
      role: "superadmin",
      email: "superA@test.com",
    });
    await db.doc("users/admin").set({
      role: "admin",
      email: "admin@test.com",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("users/floristA").set({
      role: "florist",
      email: "floristA@test.com",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("users/managerB").set({
      role: "manager",
      email: "managerB@test.com",
      companyRef: db.doc("Companies/companyB"),
    });
    await db.doc("users/floristB").set({
      role: "florist",
      email: "floristB@test.com",
      companyRef: db.doc("Companies/companyB"),
    });

    await db.doc("orders/orderA").set({
      Order_Id: "TFG-2026-0001",
      status: "pending",
      orderstatus: "pending",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("orders/orderB").set({
      Order_Id: "TFG-2026-0002",
      status: "pending",
      orderstatus: "pending",
      companyRef: db.doc("Companies/companyB"),
    });

    await db.doc("Order_item/itemA").set({
      name: "Rose",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("Order_item/itemB").set({
      name: "Lily",
      companyRef: db.doc("Companies/companyB"),
    });

    await db.doc("counter/companyA_delivery").set({ current: 1 });
    await db.doc("counter/companyB_delivery").set({ current: 1 });

    await db.doc("product/prodA").set({
      name: "Rose",
      price: 10,
      image: "",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("product/prodB").set({
      name: "Lily",
      price: 12,
      image: "",
      companyRef: db.doc("Companies/companyB"),
    });

    await db.doc("materials/matA").set({
      name: "Ribbon",
      unit: "roll",
      price: 2,
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("materials/matB").set({
      name: "Wrap",
      unit: "sheet",
      price: 3,
      companyRef: db.doc("Companies/companyB"),
    });
  });
});

function authed(uid) {
  return testEnv.authenticatedContext(uid, { email: `${uid}@test.com` });
}

function authedWithEmail(uid, email) {
  return testEnv.authenticatedContext(uid, { email });
}

describe("orders tenant isolation", () => {
  it("driver reads own-company order", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(db.doc("orders/orderA").get());
  });

  it("driver cannot read other-company order", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("orders/orderB").get());
  });

  it("driver updates status on own-company order", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.doc("orders/orderA").update({
        status: "out_of_delivery",
        orderstatus: "outOfDelivery",
      }),
    );
  });

  it("driver uploads delivery proof fields on own-company order", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.doc("orders/orderA").update({
        delivery_proof_url: "https://example.com/proof.jpg",
        delivery_proof_at: new Date(),
      }),
    );
  });

  it("driver records partial delivery on assigned order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderA").update({
        assigned_driver: db.doc("users/driverA"),
        status: "out_of_delivery",
        orderstatus: "outOfDelivery",
      });
      await db.doc("Order_item/itemA").update({
        orderRef: db.doc("orders/orderA"),
        qty: 10,
        delivered_qty: 0,
      });
    });
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemA").update({
        delivered_qty: 5,
        status: "partial",
      }),
    );
    await assertSucceeds(
      db.doc("orders/orderA").update({
        partial_delivery_run_count: 1,
        partial_delivery_runs: [
          {
            run_number: 1,
            delivery_id: "TFG-2026-0001-D1",
            items: [{ item_id: "itemA", qty: 5 }],
          },
        ],
      }),
    );
  });

  it("driver cannot update other-company order", async () => {
    const db = authed("driverA").firestore();
    await assertFails(
      db.doc("orders/orderB").update({
        status: "completed",
        orderstatus: "completed",
      }),
    );
  });

  it("senior_florist reads own-company order only", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(db.doc("orders/orderB").get());
    await assertFails(db.doc("orders/orderA").get());
  });

  it("superadmin reads cross-company orders", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(db.doc("orders/orderA").get());
    await assertSucceeds(db.doc("orders/orderB").get());
  });

  it("senior_florist creates order for own company", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.collection("orders").add({
        Order_Id: "TFG-2026-0099",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("senior_florist cannot create order for other company", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.collection("orders").add({
        Order_Id: "TFG-2026-0100",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("senior_florist updates status only on own-company order", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderB").update({
        status: "processing",
        orderstatus: "processing",
      }),
    );
  });

  it("senior_florist cannot assign driver on order", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.doc("orders/orderB").update({
        assigned_driver: db.doc("users/driverA"),
      }),
    );
  });

  it("admin updates order fields on own company", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/admin").set({
        role: "admin",
        email: "admin@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("orders/orderB").set({
        Order_Id: "TFG-2026-0002",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderB").update({
        client_name: "Updated Client",
        assigned_driver: db.doc("users/driverA"),
      }),
    );
  });

  it("senior_florist completes draft order without Order_Id", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderDraft").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderDraft").update({
        client_name: "Imported customer",
        Order_Id: "TFG-JUN26-0002",
        paymentType: "Cash",
      }),
    );
  });

  it("senior_florist updates customer details on pending order with Order_Id", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPending").set({
        Order_Id: "TFG-JUN26-0003",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPending").update({
        client_name: "Updated client",
        recipient_name: "Jane",
        address: "123 Road",
        delivery_date: new Date("2026-06-15"),
        orderType: "Delivery",
        pickup_delivery: "Delivery",
      }),
    );
  });

  it("senior_florist records cash payment on unpaid order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPay").set({
        Order_Id: "TFG-JUN26-0099",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 100,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPay").update({
        paymentType: "Cash",
        amount_paid: 100,
        balance_due: 0,
        cash_received: 100,
        cash_change: 0,
        totalAmount: 100,
        total: 100,
      }),
    );
  });

  it("staff marks stock_deducted after payment inventory", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderStockDeduct").set({
        Order_Id: "TFG-JUN26-0101",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 48,
        amount_paid: 48,
        balance_due: 0,
        paymentType: "PayNow",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderStockDeduct").update({ stock_deducted: true }),
    );
  });

  it("senior_florist cannot change payment on fully paid order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPaid").set({
        Order_Id: "TFG-JUN26-0100",
        status: "completed",
        orderstatus: "completed",
        totalAmount: 100,
        amount_paid: 100,
        balance_due: 0,
        paymentType: "Cash",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertFails(
      db.doc("orders/orderPaid").update({
        amount_paid: 80,
        balance_due: 20,
      }),
    );
  });

  it("florist finalizes draft order with payment after exact amount", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderDraftPay").set({
        status: "pending",
        orderstatus: "pending",
        totalAmount: 88,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderDraftPay").update({
        Order_Id: "TFG-JUN26-0200",
        client_name: "Alice",
        recipient_name: "Bob",
        recipient_phone_number: "91234567",
        address: "1 Test St",
        PostalCode: "123456",
        region: "North",
        delivery_date: new Date("2026-06-16"),
        delivery_time_slot: "AM",
        card_message: "Hi",
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        paymentType: "Cash",
        status: "pending",
        orderstatus: "pending",
        amount_paid: 88,
        balance_due: 0,
        cash_received: 88,
        cash_change: 0,
        totalAmount: 88,
        total: 88,
      }),
    );
  });

  it("florist recalculates order totals while building cart", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderTotals").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("Order_item/itemTotals").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderTotals").update({
        totalAmount: 120,
        total: 120,
        totalQty: 3,
        ProductSelection: db.doc("Order_item/itemTotals"),
      }),
    );
  });

  it("admin submits delivery detail form after payment on pending order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/admin").set({
        role: "admin",
        email: "admin@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("customers/custB").set({
        name: "Walk-in",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("orders/orderPaidPending").set({
        Order_Id: "TFG-JUN26-0400",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 80,
        total: 80,
        amount_paid: 80,
        balance_due: 0,
        paymentType: "Cash",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderPaidPending").update({
        client_name: "Alice",
        recipient_name: "Bob",
        recipient_phone_number: "91234567",
        address: "1 Test St",
        PostalCode: "123456",
        region: "Central",
        delivery_date: new Date("2026-06-20"),
        delivery_time_slot: "10:00-12:00",
        card_message: "Hi",
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        customer_phone_number: "",
        customerRef: db.doc("customers/custB"),
        created_time: new Date(),
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("account submits delivery detail after payment when createOrders override is false", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/accountB").set({
        role: "account",
        email: "accountB@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("role_permissions/companyB").set({
        companyRef: db.doc("Companies/companyB"),
        roles: {
          account: { createOrders: false },
        },
      });
      await db.doc("orders/orderAccountPaid").set({
        Order_Id: "TFG-JUN26-0502",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 50,
        total: 50,
        amount_paid: 50,
        balance_due: 0,
        paymentType: "Cash",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("accountB").firestore();
    await assertSucceeds(
      db.doc("orders/orderAccountPaid").update({
        client_name: "Alice",
        recipient_name: "Bob",
        recipient_phone_number: "91234567",
        address: "1 Test St",
        PostalCode: "123456",
        region: "Central",
        delivery_date: new Date("2026-06-20"),
        delivery_time_slot: "10:00-12:00",
        card_message: "Hi",
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        customer_phone_number: "",
        created_time: new Date(),
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("florist progresses delivery order from product selection", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderDeliveryProgress").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("Order_item/itemDelivery").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderDeliveryProgress").update({
        Order_Id: "TFG-JUN26-0300",
        client_name: "",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        ProductSelection: db.doc("Order_item/itemDelivery"),
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
      }),
    );
  });

  it("florist records payment when balance_due remains on order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPartial").set({
        Order_Id: "TFG-JUN26-0201",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 100,
        amount_paid: 40,
        balance_due: 60,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPartial").update({
        paymentType: "Paynow",
        amount_paid: 100,
        balance_due: 0,
        totalAmount: 100,
        total: 100,
      }),
    );
  });

  it("florist locks material cost snapshot after order is fully paid", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPaidSnapshot").set({
        Order_Id: "TFG-JUN26-0202",
        status: "pending",
        orderstatus: "pending",
        paymentType: "Cash",
        totalAmount: 88,
        amount_paid: 88,
        balance_due: 0,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPaidSnapshot").update({
        material_usage_cost: 12.5,
        material_cost_snapshot: { "materials/rose": 2.5 },
        material_cost_snapshotted_at: new Date(),
      }),
    );
  });
});

describe("Order_item tenant isolation", () => {
  it("driver reads own-company line item", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(db.doc("Order_item/itemA").get());
  });

  it("driver cannot read other-company line item", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("Order_item/itemB").get());
  });

  it("florist saves Remark on own-company line item", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemA").update({ Remark: "Extra ribbon" }),
    );
  });

  it("admin saves Remark on line item without companyRef via parent order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Order_item/itemNoCo").set({
        name: "NoCo",
        orderRef: db.doc("orders/orderA"),
        qty: 1,
        price: 5,
        subtotal: 5,
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemNoCo").update({ Remark: "via order" }),
    );
  });

  it("florist cannot save Remark on other-company line item", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("Order_item/itemB").update({ Remark: "hack" }),
    );
  });
});

describe("counter tenant isolation", () => {
  it("driver reads own-company counter", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(db.doc("counter/companyA_delivery").get());
  });

  it("driver cannot read other-company counter", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("counter/companyB_delivery").get());
  });
});

describe("audit_logs", () => {
  it("driver cannot read audit log", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.collection("audit_logs").doc("log1").get());
  });

  it("senior florist cannot read audit log", async () => {
    const db = authed("staffB").firestore();
    await assertFails(db.collection("audit_logs").doc("log1").get());
  });

  it("admin reads audit log", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("audit_logs").doc("log1").set({
        action: "create_order",
        companyId: "companyA",
        userId: "admin",
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(db.collection("audit_logs").doc("log1").get());
  });

  it("authenticated user creates audit log", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.collection("audit_logs").add({
        action: "print_receipt",
        entityType: "receipt",
        entityId: "orderA",
        userId: "driverA",
      }),
    );
  });

  it("audit log cannot be updated", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("audit_logs").doc("log1").set({
        action: "create_order",
        userId: "admin",
      });
    });
    const db = authed("admin").firestore();
    await assertFails(
      db.collection("audit_logs").doc("log1").update({ action: "hack" }),
    );
  });
});

describe("legacy counters collection", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("counters/legacy1").set({ current: 1 });
    });
  });

  it("driver cannot read legacy counters collection", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("counters/legacy1").get());
  });

  it("senior_florist updates own-company counter", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("counter/companyB_delivery").update({ current: 2 }),
    );
  });
});

describe("product catalog", () => {
  it("florist creates product in own company", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("product/newProd").set({
        name: "Tulip",
        price: 8,
        companyRef: db.doc("Companies/companyA"),
        is_active: true,
      }),
    );
  });

  it("florist creates material in own company", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("materials/newMat").set({
        name: "Stem",
        unit: "stem",
        companyRef: db.doc("Companies/companyA"),
        is_active: true,
      }),
    );
  });

  it("florist cannot create product for other company", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("product/badProd").set({
        name: "Stolen",
        price: 1,
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("driver cannot create product", async () => {
    const db = authed("driverA").firestore();
    await assertFails(
      db.doc("product/driverProd").set({
        name: "No",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("florist updates own product price", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("product/prodA").update({
        price: 15,
        name: "Rose Premium",
      }),
    );
  });

  it("florist updates own material", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("materials/matA").update({
        price: 2.5,
        name: "Ribbon Gold",
      }),
    );
  });

  it("florist cannot update other-company material", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("materials/matB").update({
        price: 99,
      }),
    );
  });

  it("superadmin creates product for another company", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("product/superProd").set({
        name: "Orchid",
        price: 20,
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("senior_florist updates image on own-company product", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("product/prodB").update({
        image: "https://example.com/rose.jpg",
      }),
    );
  });

  it("senior_florist cannot update other-company product", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.doc("product/prodA").update({
        image: "https://example.com/rose.jpg",
      }),
    );
  });

  it("senior_florist deletes own-company product", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(db.doc("product/prodB").delete());
  });

  it("senior_florist cannot delete other-company product", async () => {
    const db = authed("staffB").firestore();
    await assertFails(db.doc("product/prodA").delete());
  });
});

describe("users staff profiles", () => {
  it("admin deletes florist in own company", async () => {
    const db = authed("admin").firestore();
    await assertSucceeds(db.doc("users/floristA").delete());
  });

  it("admin cannot delete other-company staff", async () => {
    const db = authed("admin").firestore();
    await assertFails(db.doc("users/staffB").delete());
  });

  it("admin cannot delete another admin", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/adminB").set({
        role: "admin",
        email: "adminB@test.com",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("admin").firestore();
    await assertFails(db.doc("users/adminB").delete());
  });

  it("manager deletes florist in own company", async () => {
    const db = authed("managerB").firestore();
    await assertSucceeds(db.doc("users/floristB").delete());
  });

  it("manager cannot delete another manager", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/managerB2").set({
        role: "manager",
        email: "managerB2@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("managerB").firestore();
    await assertFails(db.doc("users/managerB2").delete());
  });
});

describe("customers tenant writes", () => {
  it("staff creates customer for own company", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.collection("customers").add({
        name: "Jane Tan",
        phone: "91234567",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("staff cannot create customer for other company", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.collection("customers").add({
        name: "Jane Tan",
        phone: "91234567",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("admin reads and updates product_categories for own company", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("product_categories/companyA").set({
        companyRef: db.doc("Companies/companyA"),
        categories: ["Hand Bouquet"],
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(db.doc("product_categories/companyA").get());
    await assertSucceeds(
      db.doc("product_categories/companyA").set(
        {
          companyRef: db.doc("Companies/companyA"),
          categories: ["Hand Bouquet", "Funeral"],
        },
        { merge: true },
      ),
    );
  });

  it("admin with typo companyRef can read and update canonical product_categories doc", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "The Flower Guy",
        is_active: true,
      });
      await db.doc("product_categories/lc3Dhfby8f35Md0E1vZC").set({
        companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
        categories: ["Funeral", "Hand Bouquet"],
      });
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo",
        is_active: true,
      });
      await db.doc("users/typoAdmin").set({
        role: "admin",
        email: "typoAdmin@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
    });
    const db = authed("typoAdmin").firestore();
    await assertSucceeds(
      db.doc("product_categories/lc3Dhfby8f35Md0E1vZC").get(),
    );
    await assertSucceeds(
      db.doc("product_categories/lc3Dhfby8f35Md0E1vZC").set(
        {
          companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
          categories: ["Funeral", "Hand Bouquet", "Others"],
        },
        { merge: true },
      ),
    );
  });

  it("staff with typo companyRef can create customer for canonical company", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "Canonical",
        is_active: true,
      });
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo",
        is_active: true,
      });
      await db.doc("users/typoStaff").set({
        role: "senior_florist",
        email: "typoStaff@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
    });
    const db = authed("typoStaff").firestore();
    await assertSucceeds(
      db.collection("customers").add({
        name: "Typo Co Customer",
        phone: "87571239",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      }),
    );
  });
});

describe("canonical companyRef catalog reads (production menu path)", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const canonicalCompany = db.doc("Companies/lc3Dhfby8f35Md0E1vZC");
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "The Flower Guy",
        is_active: true,
      });
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo legacy id",
        is_active: true,
      });
      await db.doc("users/typoFlorist").set({
        role: "florist",
        email: "typoFlorist@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
      await db.doc("orders/canonicalOrder").set({
        Order_Id: "TFG-TEST-PROD-MENU",
        status: "pending",
        orderstatus: "pending",
        companyRef: canonicalCompany,
      });
      await db.doc("Order_item/canonicalItem").set({
        name: "Rose Bouquet",
        qty: 1,
        orderRef: db.doc("orders/canonicalOrder"),
        companyRef: canonicalCompany,
      });
      await db.doc("product/canonicalProd").set({
        name: "Rose Bouquet",
        price: 50,
        isActive: true,
        companyRef: canonicalCompany,
        recipeLines: [{ materialName: "Rose", qty: 12, unit: "stem" }],
      });
      await db.doc("materials/matRose").set({
        name: "Rose",
        cost: 1.5,
        unit: "stem",
        companyRef: canonicalCompany,
      });
    });
  });

  it("florist with typo companyRef reads canonical product", async () => {
    const db = authed("typoFlorist").firestore();
    await assertSucceeds(db.doc("product/canonicalProd").get());
  });

  it("florist with typo companyRef reads canonical materials", async () => {
    const db = authed("typoFlorist").firestore();
    await assertSucceeds(db.doc("materials/matRose").get());
  });

  it("florist with typo companyRef reads canonical order line items", async () => {
    const db = authed("typoFlorist").firestore();
    await assertSucceeds(db.doc("orders/canonicalOrder").get());
    await assertSucceeds(db.doc("Order_item/canonicalItem").get());
  });

  it("driver with typo companyRef uploads delivery proof on assigned canonical order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/typoDriver").set({
        role: "driver",
        email: "typoDriver@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
      await db.doc("orders/canonicalOrder").update({
        assigned_driver: db.doc("users/typoDriver"),
        status: "out_of_delivery",
        orderstatus: "out_of_delivery",
      });
    });
    const db = authed("typoDriver").firestore();
    await assertSucceeds(
      db.doc("orders/canonicalOrder").update({
        delivery_proof_url: "https://example.com/proof.jpg",
        delivery_proof_at: new Date(),
      }),
    );
  });
});

describe("staff registration intents", () => {
  it("blocks users profile create without registration intent", async () => {
    const db = authed("attacker").firestore();
    await assertFails(
      db.doc("users/attacker").set({
        uid: "attacker",
        email: "attacker@test.com",
        role: "admin",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("admin creates registration intent for new hire", async () => {
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("staff_registration_intents/newhire@test.com").set({
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("superadmin creates registration intent for any company", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("staff_registration_intents/tenanthire@test.com").set({
        email: "tenanthire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("superadmin can replace stale registration intent (update)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("staff_registration_intents/stale@test.com").set({
        email: "stale@test.com",
        role: "driver",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("staff_registration_intents/stale@test.com").set({
        email: "stale@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("new hire completes profile when intent matches", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("staff_registration_intents/newhire@test.com").set({
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authedWithEmail("newhire", "newhire@test.com").firestore();
    await assertSucceeds(
      db.doc("users/newhire").set({
        uid: "newhire",
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("new hire completes profile when intent companyRef uses legacy typo id", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo legacy id",
        is_active: true,
      });
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "Canonical company",
        is_active: true,
      });
      await db.doc("staff_registration_intents/typohire@test.com").set({
        email: "typohire@test.com",
        role: "driver",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
    });
    const db = authedWithEmail("typohire", "typohire@test.com").firestore();
    await assertSucceeds(
      db.doc("users/typohire").set({
        uid: "typohire",
        email: "typohire@test.com",
        role: "driver",
        companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
      }),
    );
  });

  it("rejects profile create when intent role mismatches", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("staff_registration_intents/newhire@test.com").set({
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authedWithEmail("newhire", "newhire@test.com").firestore();
    await assertFails(
      db.doc("users/newhire").set({
        uid: "newhire",
        email: "newhire@test.com",
        role: "admin",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });
});

describe("legacy companyRef isolation", () => {
  // Legacy path: staff may access orders missing companyRef until backfill completes
  // (see npm run verify:company-ref / npm run backfill:company-ref).
  it("staff can read legacy order without companyRef during migration", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/legacyOrder").set({
        Order_Id: "TFG-LEGACY-0001",
        status: "pending",
        orderstatus: "pending",
      });
    });
    const db = authed("floristA").firestore();
    await assertSucceeds(db.doc("orders/legacyOrder").get());
  });

  it("superadmin can read order without companyRef", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/legacyRead").set({
        Order_Id: "TFG-LEGACY-0002",
        status: "pending",
        orderstatus: "pending",
      });
    });
    const db = authed("superA").firestore();
    await assertSucceeds(db.doc("orders/legacyRead").get());
  });

  it("admin can progress delivery order when createOrders override is false", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("role_permissions/companyA").set({
        companyRef: db.doc("Companies/companyA"),
        roles: {
          admin: { createOrders: false },
        },
      });
      await db.doc("orders/orderAdminNoCreate").set({
        status: "pending",
        orderstatus: "pending",
      });
      await db.doc("Order_item/itemAdminNoCreate").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderAdminNoCreate").update({ companyRef: db.doc("Companies/companyA") }),
    );
    await assertSucceeds(
      db.doc("orders/orderAdminNoCreate").update({
        Order_Id: "TFG-JUN26-0501",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        ProductSelection: db.doc("Order_item/itemAdminNoCreate"),
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
      }),
    );
  });

  it("admin can progress delivery order from product selection", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderAdminDelivery").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      });
      await db.doc("Order_item/itemAdminDelivery").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderAdminDelivery").update({
        Order_Id: "TFG-JUN26-0500",
        client_name: "",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        ProductSelection: db.doc("Order_item/itemAdminDelivery"),
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("superadmin can save role_permissions without profile companyRef", async () => {
    const db = authed("superA").firestore();
    const companyRef = db.doc("Companies/companyA");
    await assertSucceeds(
      db.doc("role_permissions/companyA").set({
        companyRef,
        roles: {
          admin: { createOrders: true },
        },
        updated_time: new Date(),
      }),
    );
  });

  it("superadmin cannot save role_permissions with mismatched companyRef", async () => {
    const db = authed("superA").firestore();
    const companyRef = db.doc("Companies/companyB");
    await assertFails(
      db.doc("role_permissions/companyA").set({
        companyRef,
        roles: {
          admin: { createOrders: true },
        },
        updated_time: new Date(),
      }),
    );
  });

  it("staff can create legacy order without companyRef during migration", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.collection("orders").add({
        Order_Id: "TFG-2026-LEGACY",
        status: "pending",
        orderstatus: "pending",
      }),
    );
  });
});

describe("SaaS onboarding rules", () => {
  const signupPayload = (emailKey) => ({
    email: emailKey,
    name: "New Shop",
    phone: "+60123456789",
    account_type: "company",
    company_name: "Demo Florist",
    country: "MY",
    status: "pending",
  });

  it("anonymous user creates user_registration_requests", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(
      db.doc("user_registration_requests/shop@example.com").set(
        signupPayload("shop@example.com"),
      ),
    );
  });

  it("applicant reads own registration request when signed in", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("user_registration_requests/shop@example.com").set(
        signupPayload("shop@example.com"),
      );
    });
    const db = authedWithEmail("shop", "shop@example.com").firestore();
    await assertSucceeds(
      db.doc("user_registration_requests/shop@example.com").get(),
    );
  });

  it("a second create for the same applicant does not overwrite a pending request", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(
      db.doc("user_registration_requests/shop@example.com").set(
        signupPayload("shop@example.com"),
      ),
    );
    await assertFails(
      db.doc("user_registration_requests/shop@example.com").set({
        ...signupPayload("shop@example.com"),
        company_name: "Other Shop",
      }),
    );
  });

  it("staff cannot read another applicant registration request", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("user_registration_requests/other@example.com").set(
        signupPayload("other@example.com"),
      );
    });
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("user_registration_requests/other@example.com").get(),
    );
  });

  it("clients cannot approve a registration request", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("user_registration_requests/shop@example.com").set(
        signupPayload("shop@example.com"),
      );
    });
    const db = authed("superA").firestore();
    await assertFails(
      db.doc("user_registration_requests/shop@example.com").update({
        status: "approved",
        reviewed_at: new Date(),
      }),
    );
  });

  it("registration without a supported country is rejected", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.doc("user_registration_requests/nocountry@example.com").set({
        ...signupPayload("nocountry@example.com"),
        country: "US",
      }),
    );
  });

  it("platform admin cannot change subscription pricing fields", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("Companies/companyA").update({ Company_name: "A renamed" }),
    );
    await assertFails(
      db.doc("Companies/companyA").update({
        subscription_status: "active",
        plan_tier: "business",
        list_price_minor: 1,
      }),
    );
  });

  it("superadmin can create a company without subscription fields", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("Companies/manualShop").set({
        Company_name: "Manual",
        is_active: true,
      }),
    );
  });

  it("staff cannot create an active company", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("Companies/newShop").set({
        Company_name: "New",
        is_active: true,
      }),
    );
  });

  it("staff reads own tenant_platform_config only", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("tenant_platform_config/companyA").set({
        industry_key: "florist",
        order_id_prefix: "TFG",
      });
      await db.doc("tenant_platform_config/companyB").set({
        industry_key: "generic",
        order_id_prefix: "EC",
      });
    });
    const db = authed("floristA").firestore();
    await assertSucceeds(db.doc("tenant_platform_config/companyA").get());
    await assertFails(db.doc("tenant_platform_config/companyB").get());
  });

  it("superadmin reads and writes any tenant_platform_config", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("tenant_platform_config/companyB").set({
        industry_key: "generic",
        order_id_prefix: "EC",
      }),
    );
    await assertSucceeds(db.doc("tenant_platform_config/companyB").get());
  });

  it("director cannot write tenant_platform_config", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/directorA").set({
        role: "director",
        email: "directorA@test.com",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("directorA").firestore();
    await assertFails(
      db.doc("tenant_platform_config/companyA").set({
        industry_key: "florist",
      }),
    );
  });
});

describe("trial quota enforcement", () => {
  async function seedTrialCompany() {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/companyT").set({
        Company_name: "Trial",
        is_active: true,
        subscription_status: "trialing",
        pricing_version: "v1",
        max_orders_per_month: 2,
        max_staff_seats: 3,
        max_companies: 1,
      });
      await db.doc("trial_quota/companyT").set({
        orders_consumed: 0,
        staff_consumed: 1,
      });
      await db.doc("users/directorT").set({
        role: "director",
        email: "directorT@test.com",
        uid: "directorT",
        companyRef: db.doc("Companies/companyT"),
        trial_slot: "1",
        trial_enforced: true,
        is_active: true,
      });
      await db.doc("trial_staff_slots/companyT/slots/1").set({
        user_id: "directorT",
      });
      await db.doc("users/floristT").set({
        role: "senior_florist",
        email: "floristT@test.com",
        companyRef: db.doc("Companies/companyT"),
        is_active: true,
      });
      await db.doc("orders/trialExisting").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyT"),
      });
    });
  }

  async function claimOrder(slot, orderId) {
    const db = authed("directorT").firestore();
    await db.runTransaction(async (tx) => {
      tx.set(db.doc(`orders/${orderId}`), {
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyT"),
        trial_slot: String(slot),
      });
      tx.set(db.doc(`trial_order_slots/companyT/slots/${slot}`), {
        order_id: orderId,
      });
      tx.update(db.doc("trial_quota/companyT"), { orders_consumed: slot });
    });
  }

  async function claimStaff(slot, uid) {
    const email = `${uid}@test.com`;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`staff_registration_intents/${email}`).set({
        email,
        role: "florist",
        companyRef: db.doc("Companies/companyT"),
      });
    });
    const db = authedWithEmail(uid, email).firestore();
    await db.runTransaction(async (tx) => {
      tx.set(db.doc(`users/${uid}`), {
        uid,
        email,
        role: "florist",
        companyRef: db.doc("Companies/companyT"),
        trial_slot: String(slot),
        trial_enforced: true,
        is_active: true,
      });
      tx.set(db.doc(`trial_staff_slots/companyT/slots/${slot}`), {
        user_id: uid,
      });
      tx.update(db.doc("trial_quota/companyT"), { staff_consumed: slot });
    });
  }

  it("accepts two trial orders and rejects the third", async () => {
    await seedTrialCompany();
    await assertSucceeds(claimOrder(1, "trialOrder1"));
    await assertSucceeds(claimOrder(2, "trialOrder2"));
    await assertFails(claimOrder(3, "trialOrder3"));
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const quota = await context.firestore().doc("trial_quota/companyT").get();
      assert.equal(quota.data().orders_consumed, 2);
    });
  });

  it("rejects a trial order written without a slot", async () => {
    await seedTrialCompany();
    const db = authed("directorT").firestore();
    await assertFails(
      db.collection("orders").add({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyT"),
      }),
    );
  });

  it("rejects a trial order that omits companyRef", async () => {
    await seedTrialCompany();
    const db = authed("directorT").firestore();
    await assertFails(
      db.collection("orders").add({
        status: "pending",
        orderstatus: "pending",
        trial_slot: "1",
      }),
    );
  });

  it("rejects a jumped or decreased order counter", async () => {
    await seedTrialCompany();
    const db = authed("directorT").firestore();
    await assertFails(
      db.doc("trial_quota/companyT").update({ orders_consumed: 2 }),
    );
    await assertFails(
      db.doc("trial_quota/companyT").update({ orders_consumed: 0 }),
    );
  });

  it("rejects a cross-tenant quota write", async () => {
    await seedTrialCompany();
    const db = authed("floristB").firestore();
    await assertFails(
      db.doc("trial_quota/companyT").update({ orders_consumed: 1 }),
    );
    await assertFails(
      db.collection("orders").add({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyT"),
        trial_slot: "1",
      }),
    );
  });

  it("still lets a legacy company create an order", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.collection("orders").add({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("still lets a trial company update an existing order", async () => {
    await seedTrialCompany();
    const db = authed("floristT").firestore();
    await assertSucceeds(
      db.doc("orders/trialExisting").update({
        status: "processing",
        orderstatus: "processing",
      }),
    );
  });

  it("does not return a slot when an order is deleted", async () => {
    await seedTrialCompany();
    await claimOrder(1, "trialOrder1");
    const admin = authed("superA").firestore();
    await assertSucceeds(admin.doc("orders/trialOrder1").delete());
    await assertFails(
      authed("directorT").firestore().doc("trial_quota/companyT").update({
        orders_consumed: 0,
      }),
    );
    await assertFails(
      authed("directorT")
        .firestore()
        .doc("trial_order_slots/companyT/slots/1")
        .delete(),
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const quota = await context.firestore().doc("trial_quota/companyT").get();
      assert.equal(quota.data().orders_consumed, 1);
    });
  });

  it("accepts staff through seat 3 and rejects seat 4", async () => {
    await seedTrialCompany();
    await assertSucceeds(claimStaff(2, "staffT2"));
    await assertSucceeds(claimStaff(3, "staffT3"));
    await assertFails(claimStaff(4, "staffT4"));
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const quota = await context.firestore().doc("trial_quota/companyT").get();
      assert.equal(quota.data().staff_consumed, 3);
      const fourth = await context.firestore().doc("users/staffT4").get();
      assert.equal(fourth.exists, false);
    });
  });

  it("lets a paid company create an order without a trial slot", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/companyPaid").set({
        Company_name: "Paid",
        is_active: true,
        subscription_status: "active",
        pricing_version: "v1",
        plan_tier: "pro",
        max_orders_per_month: 10000,
      });
      await db.doc("users/directorPaid").set({
        role: "director",
        email: "directorPaid@test.com",
        companyRef: db.doc("Companies/companyPaid"),
        trial_enforced: true,
        is_active: true,
      });
    });
    const periodEnd = new Date("2099-01-01T00:00:00.000Z");
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc("Companies/companyPaid").set({
        Company_name: "Paid",
        is_active: true,
        subscription_status: "active",
        pricing_version: "v1",
        plan_tier: "pro",
        max_orders_per_month: 10000,
        usage_period_id: "period-paid",
        current_period_end: periodEnd,
      });
    });
    const db = authed("directorPaid").firestore();
    await assertSucceeds(
      db.runTransaction(async (tx) => {
        tx.set(db.collection("orders").doc("paidOrder1"), {
          status: "pending",
          orderstatus: "pending",
          companyRef: db.doc("Companies/companyPaid"),
          plan_period: "period-paid",
          plan_slot: "1",
        });
        tx.set(db.doc("plan_order_slots/companyPaid/periods/period-paid/slots/1"), {
          order_id: "paidOrder1",
        });
        tx.set(db.doc("plan_usage/companyPaid"), {
          period_id: "period-paid",
          orders_consumed: 1,
          broadcast_consumed: 0,
        });
      }),
    );
  });

  it("meters paid monthly orders, rollover, and broadcast recipients", async () => {
    const periodEnd = new Date("2099-01-01T00:00:00.000Z");
    async function seedMetered(id, ordersMax, broadcastMax, orders, broadcast) {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`Companies/${id}`).set({
          Company_name: id,
          is_active: true,
          subscription_status: "active",
          pricing_version: "v1",
          usage_period_id: "p1",
          current_period_end: periodEnd,
          max_orders_per_month: ordersMax,
          broadcast_quota_monthly: broadcastMax,
        });
        await db.doc(`plan_usage/${id}`).set({
          period_id: "p1",
          orders_consumed: orders,
          broadcast_consumed: broadcast,
        });
        await db.doc(`users/director_${id}`).set({
          role: "director",
          email: `director_${id}@test.com`,
          companyRef: db.doc(`Companies/${id}`),
          trial_enforced: true,
          is_active: true,
        });
      });
    }
    async function claimOrder(id, slot) {
      const db = authed(`director_${id}`).firestore();
      const orderId = `${id}-o-${slot}`;
      await db.runTransaction(async (tx) => {
        tx.set(db.doc(`orders/${orderId}`), {
          status: "pending",
          orderstatus: "pending",
          companyRef: db.doc(`Companies/${id}`),
          plan_period: "p1",
          plan_slot: String(slot),
        });
        tx.set(db.doc(`plan_order_slots/${id}/periods/p1/slots/${slot}`), {
          order_id: orderId,
        });
        tx.update(db.doc(`plan_usage/${id}`), { orders_consumed: slot });
      });
    }
    async function claimBroadcast(id, suffix, added, next) {
      const db = authed(`director_${id}`).firestore();
      const attempt = `${id}_${suffix}`;
      await db.runTransaction(async (tx) => {
        tx.set(db.doc(`broadcast_reservations/${attempt}`), {
          company_id: id,
          period_id: "p1",
          count: added,
          status: "reserved",
        });
        tx.update(db.doc(`plan_usage/${id}`), {
          broadcast_consumed: next,
          broadcast_attempt: attempt,
        });
      });
    }

    await seedMetered("cap500", 500, 0, 499, 0);
    await assertSucceeds(claimOrder("cap500", 500));
    await assertFails(claimOrder("cap500", 501));

    await seedMetered("cap3000", 3000, 2000, 2999, 1999);
    await assertSucceeds(claimOrder("cap3000", 3000));
    await assertFails(claimOrder("cap3000", 3001));
    await assertSucceeds(claimBroadcast("cap3000", "ok", 1, 2000));
    await assertFails(claimBroadcast("cap3000", "over", 1, 2001));
    await assertFails(claimBroadcast("cap3000", "ok", 1, 2001));

    await seedMetered("cap10000", 10000, 10000, 9999, 9999);
    await assertSucceeds(claimOrder("cap10000", 10000));
    await assertFails(claimOrder("cap10000", 10001));
    await assertSucceeds(claimBroadcast("cap10000", "ok", 1, 10000));
    await assertFails(claimBroadcast("cap10000", "over", 1, 10001));

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/roll").set({
        is_active: true,
        subscription_status: "active",
        pricing_version: "v1",
        usage_period_id: "p2",
        current_period_end: periodEnd,
        max_orders_per_month: 500,
        broadcast_quota_monthly: 0,
      });
      await db.doc("plan_usage/roll").set({
        period_id: "p1",
        orders_consumed: 500,
        broadcast_consumed: 4,
      });
      await db.doc("users/director_roll").set({
        role: "director",
        email: "director_roll@test.com",
        companyRef: db.doc("Companies/roll"),
        trial_enforced: true,
        is_active: true,
      });
      await db.doc("trial_quota/roll").set({ orders_consumed: 100 });
    });
    const roll = authed("director_roll").firestore();
    await assertSucceeds(
      roll.runTransaction(async (tx) => {
        tx.set(roll.doc("orders/roll-1"), {
          status: "pending",
          orderstatus: "pending",
          companyRef: roll.doc("Companies/roll"),
          plan_period: "p2",
          plan_slot: "1",
        });
        tx.set(roll.doc("plan_order_slots/roll/periods/p2/slots/1"), {
          order_id: "roll-1",
        });
        tx.update(roll.doc("plan_usage/roll"), {
          period_id: "p2",
          orders_consumed: 1,
          broadcast_consumed: 0,
        });
      }),
    );
    await assertFails(
      roll.runTransaction(async (tx) => {
        tx.set(roll.doc("orders/hack"), {
          status: "pending",
          orderstatus: "pending",
          companyRef: roll.doc("Companies/roll"),
          plan_period: "hacked-period",
          plan_slot: "1",
        });
        tx.set(roll.doc("plan_order_slots/roll/periods/hacked-period/slots/1"), {
          order_id: "hack",
        });
        tx.update(roll.doc("plan_usage/roll"), {
          period_id: "hacked-period",
          orders_consumed: 1,
          broadcast_consumed: 0,
        });
      }),
    );
    await assertFails(
      roll.doc("Companies/roll").update({ usage_period_id: "hacked-period" }),
    );

    const releaseDb = authed("director_cap3000").firestore();
    await assertSucceeds(
      releaseDb.runTransaction(async (tx) => {
        tx.update(releaseDb.doc("broadcast_reservations/cap3000_ok"), {
          status: "released",
        });
        tx.update(releaseDb.doc("plan_usage/cap3000"), {
          broadcast_consumed: 1999,
          broadcast_attempt: "cap3000_ok",
        });
      }),
    );

    await assertFails(
      authed("director_cap500").firestore().doc("plan_usage/cap3000").update({
        orders_consumed: 1,
      }),
    );
    const admin = authed("superA").firestore();
    await assertSucceeds(
      admin.collection("orders").add({
        status: "pending",
        orderstatus: "pending",
        companyRef: admin.doc("Companies/cap500"),
      }),
    );
  });

  it("denies a direct client Shopify write", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/companyStarter").set({
        Company_name: "Starter",
        is_active: true,
        subscription_status: "active",
        pricing_version: "v1",
        plan_tier: "starter",
      });
      await db.doc("Companies/companyBiz").set({
        Company_name: "Business",
        is_active: true,
        subscription_status: "active",
        pricing_version: "v1",
        plan_tier: "business",
      });
      await db.doc("Companies/companyLegacy").set({
        Company_name: "Legacy",
        is_active: true,
      });
      await db.doc("users/directorStarter").set({
        role: "director",
        email: "directorStarter@test.com",
        companyRef: db.doc("Companies/companyStarter"),
        trial_enforced: true,
        is_active: true,
      });
      await db.doc("users/directorBiz").set({
        role: "director",
        email: "directorBiz@test.com",
        companyRef: db.doc("Companies/companyBiz"),
        trial_enforced: true,
        is_active: true,
      });
      await db.doc("users/directorLegacy").set({
        role: "director",
        email: "directorLegacy@test.com",
        companyRef: db.doc("Companies/companyLegacy"),
        is_active: true,
      });
    });
    const order = {
      status: "pending",
      orderstatus: "pending",
      source: "shopify",
    };
    const starterDb = authed("directorStarter").firestore();
    await assertFails(
      starterDb.collection("orders").add({
        ...order,
        companyRef: starterDb.doc("Companies/companyStarter"),
      }),
    );
    const bizDb = authed("directorBiz").firestore();
    await assertFails(
      bizDb.collection("orders").add({
        ...order,
        companyRef: bizDb.doc("Companies/companyBiz"),
      }),
    );
    const adminDb = authed("superA").firestore();
    await assertSucceeds(
      adminDb.collection("orders").add({
        ...order,
        companyRef: adminDb.doc("Companies/companyLegacy"),
      }),
    );
  });

  it("enforces paid staff seats and blocks plan field edits", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/companySeats").set({
        Company_name: "Seats",
        is_active: true,
        subscription_status: "active",
        pricing_version: "v1",
        plan_tier: "starter",
        plan_modules: ["orders"],
        max_staff_seats: 2,
      });
      await db.doc("trial_quota/companySeats").set({
        orders_consumed: 0,
        staff_consumed: 1,
      });
      await db.doc("users/directorSeats").set({
        role: "director",
        email: "directorSeats@test.com",
        uid: "directorSeats",
        companyRef: db.doc("Companies/companySeats"),
        trial_slot: "1",
        trial_enforced: true,
        is_active: true,
      });
      await db.doc("trial_staff_slots/companySeats/slots/1").set({
        user_id: "directorSeats",
      });
      await db.doc("users/adminSeats").set({
        role: "admin",
        email: "adminSeats@test.com",
        companyRef: db.doc("Companies/companySeats"),
        is_active: true,
      });
    });
    async function claimSeat(slot, uid) {
      const email = `${uid}@test.com`;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc(`staff_registration_intents/${email}`).set({
          email,
          role: "florist",
          companyRef: context.firestore().doc("Companies/companySeats"),
        });
      });
      const db = authedWithEmail(uid, email).firestore();
      await db.runTransaction(async (tx) => {
        tx.set(db.doc(`users/${uid}`), {
          uid,
          email,
          role: "florist",
          companyRef: db.doc("Companies/companySeats"),
          trial_slot: String(slot),
          trial_enforced: true,
          is_active: true,
        });
        tx.set(db.doc(`trial_staff_slots/companySeats/slots/${slot}`), {
          user_id: uid,
        });
        tx.update(db.doc("trial_quota/companySeats"), { staff_consumed: slot });
      });
    }
    await assertSucceeds(claimSeat(2, "seat2"));
    await assertFails(claimSeat(3, "seat3"));
    await assertFails(
      authed("adminSeats").firestore().doc("Companies/companySeats").update({
        plan_modules: ["orders", "shopifyImport"],
      }),
    );
    await assertFails(
      authed("directorSeats").firestore().doc("users/directorSeats").update({
        role: "superadmin",
      }),
    );
  });
});
