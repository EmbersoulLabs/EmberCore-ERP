const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { TRIAL_LIMITS } = require("../functions/saas_pricing_v1");
const {
  TrialLimitError,
  nextSlot,
  placeTrialOrder,
} = require("../functions/trial_quota");
const { counterDocId } = require("../functions/shopify/order_id_helpers");

function createFakeDb() {
  const docs = new Map();
  let chain = Promise.resolve();

  function refFrom(path) {
    return {
      path,
      id: path.split("/").pop(),
      collection(name) {
        return {
          doc(id) {
            return refFrom(`${path}/${name}/${id}`);
          },
        };
      },
    };
  }

  function snap(path) {
    const data = docs.get(path);
    return {
      exists: data !== undefined,
      data() {
        return data;
      },
    };
  }

  return {
    docs,
    collection(name) {
      return {
        doc(id) {
          return refFrom(`${name}/${id}`);
        },
      };
    },
    runTransaction(fn) {
      const run = chain.then(async () => {
        const writes = [];
        const tx = {
          async get(ref) {
            return snap(ref.path);
          },
          set(ref, data, opts) {
            writes.push({
              path: ref.path,
              data,
              merge: Boolean(opts && opts.merge),
            });
          },
        };
        const result = await fn(tx);
        for (const write of writes) {
          if (write.merge && docs.has(write.path)) {
            docs.set(write.path, { ...docs.get(write.path), ...write.data });
          } else {
            docs.set(write.path, { ...write.data });
          }
        }
        return result;
      });
      chain = run.then(
        () => {},
        () => {},
      );
      return run;
    },
  };
}

describe("trial quota contract", () => {
  it("keeps the published trial caps", () => {
    assert.equal(TRIAL_LIMITS.max_staff, 3);
    assert.equal(TRIAL_LIMITS.max_orders, 100);
    assert.equal(TRIAL_LIMITS.max_companies, 1);
    assert.equal(nextSlot(2, TRIAL_LIMITS.max_staff), 3);
    assert.equal(nextSlot(3, TRIAL_LIMITS.max_staff), null);
    assert.equal(nextSlot(99, TRIAL_LIMITS.max_orders), 100);
    assert.equal(nextSlot(100, TRIAL_LIMITS.max_orders), null);
  });

  it("accepts 100 orders, rejects 101, and ignores a deleted order", async () => {
    const db = createFakeDb();
    const company = { max_orders_per_month: TRIAL_LIMITS.max_orders };
    const companyId = "trialCo";

    for (let n = 1; n <= TRIAL_LIMITS.max_orders; n += 1) {
      const placed = await placeTrialOrder(db, {
        companyId,
        company,
        orderRef: db.collection("orders").doc(`order-${n}`),
        orderData: { status: "pending" },
        externalOrderId: `shop-${n}`,
      });
      assert.equal(placed.duplicate, false);
      assert.equal(placed.slot, n);
    }

    const counterPath = `counter/${counterDocId("delivery")}`;
    assert.equal(db.docs.get(counterPath).current, 100);
    assert.equal(db.docs.get(`trial_quota/${companyId}`).orders_consumed, 100);

    db.docs.delete("orders/order-1");
    assert.equal(db.docs.get(`trial_quota/${companyId}`).orders_consumed, 100);

    await assert.rejects(
      () =>
        placeTrialOrder(db, {
          companyId,
          company,
          orderRef: db.collection("orders").doc("order-101"),
          orderData: { status: "pending" },
          externalOrderId: "shop-101",
        }),
      (error) => error instanceof TrialLimitError && error.kind === "orders",
    );
    assert.equal(db.docs.get(counterPath).current, 100);
    assert.equal(db.docs.has("orders/order-101"), false);
    assert.equal(db.docs.get(`trial_quota/${companyId}`).orders_consumed, 100);
  });

  it("does not consume a second slot for the same Shopify order", async () => {
    const db = createFakeDb();
    const company = { max_orders_per_month: TRIAL_LIMITS.max_orders };
    const first = await placeTrialOrder(db, {
      companyId: "trialCo",
      company,
      orderRef: db.collection("orders").doc("order-a"),
      orderData: { status: "pending" },
      externalOrderId: "1001",
    });
    const second = await placeTrialOrder(db, {
      companyId: "trialCo",
      company,
      orderRef: db.collection("orders").doc("order-b"),
      orderData: { status: "pending" },
      externalOrderId: "1001",
    });
    assert.equal(first.duplicate, false);
    assert.equal(second.duplicate, true);
    assert.equal(second.orderId, first.orderId);
    assert.equal(db.docs.get("trial_quota/trialCo").orders_consumed, 1);
    assert.equal(db.docs.has("orders/order-b"), false);
    assert.equal(db.docs.get(`counter/${counterDocId("delivery")}`).current, 1);
  });

  it("lets only one of two concurrent creates take the last slot", async () => {
    const db = createFakeDb();
    const company = { max_orders_per_month: 100 };
    db.docs.set("trial_quota/trialCo", {
      orders_consumed: 99,
      staff_consumed: 1,
    });
    db.docs.set(`counter/${counterDocId("delivery")}`, { current: 99 });

    const results = await Promise.allSettled([
      placeTrialOrder(db, {
        companyId: "trialCo",
        company,
        orderRef: db.collection("orders").doc("last-a"),
        orderData: { status: "pending" },
        externalOrderId: "race-a",
      }),
      placeTrialOrder(db, {
        companyId: "trialCo",
        company,
        orderRef: db.collection("orders").doc("last-b"),
        orderData: { status: "pending" },
        externalOrderId: "race-b",
      }),
    ]);

    const fulfilled = results.filter((result) => result.status === "fulfilled");
    const rejected = results.filter((result) => result.status === "rejected");
    assert.equal(fulfilled.length, 1);
    assert.equal(rejected.length, 1);
    assert.ok(rejected[0].reason instanceof TrialLimitError);
    assert.equal(db.docs.get("trial_quota/trialCo").orders_consumed, 100);
    assert.equal(db.docs.get(`counter/${counterDocId("delivery")}`).current, 100);
  });
});
