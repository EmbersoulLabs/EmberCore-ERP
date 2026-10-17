const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { counterDocId } = require("../functions/shopify/order_id_helpers");
const {
  PlanQuotaError,
  usagePeriodId,
  usageAfterReserve,
  placePaidOrder,
  reserveBroadcast,
  releaseBroadcast,
  markBroadcastOpened,
} = require("../functions/monthly_usage");

const NOW = new Date("2026-10-17T04:00:00.000Z");
const PERIOD_END = new Date("2026-11-17T00:00:00.000Z");

function company(maxOrders, maxBroadcast) {
  return {
    subscription_status: "active",
    pricing_version: "v1",
    usage_period_id: "bill-1",
    current_period_end: PERIOD_END,
    max_orders_per_month: maxOrders,
    broadcast_quota_monthly: maxBroadcast,
  };
}

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

describe("monthly usage", () => {
  it("uses the billing period until it ends, then the UTC month", () => {
    const row = company(500, 0);
    assert.equal(usagePeriodId(row, NOW), "bill-1");
    assert.equal(
      usagePeriodId(row, new Date("2026-11-17T00:00:00.000Z")),
      "2026-11",
    );
    assert.equal(usagePeriodId({ subscription_status: "active" }, NOW), "2026-10");
  });

  it("rolls a new period back to one order and keeps trial data untouched", () => {
    const next = usageAfterReserve(
      { period_id: "old", orders_consumed: 500, broadcast_consumed: 9 },
      "bill-2",
      "orders",
      1,
    );
    assert.equal(next.orders_consumed, 1);
    assert.equal(next.broadcast_consumed, 0);
    assert.equal(next.rolled, true);
  });

  for (const [label, max] of [
    ["starter", 500],
    ["pro", 3000],
    ["business", 10000],
  ]) {
    it(`accepts ${label} order ${max} and rejects ${max + 1}`, async () => {
      const db = createFakeDb();
      const id = label;
      db.docs.set(`plan_usage/${id}`, {
        period_id: "bill-1",
        orders_consumed: max - 1,
        broadcast_consumed: 0,
      });
      db.docs.set("trial_quota/trialCo", { orders_consumed: 100 });
      db.docs.set(`counter/${counterDocId("delivery")}`, { current: 4 });
      const accepted = await placePaidOrder(db, {
        companyId: id,
        company: company(max, 0),
        orderRef: db.collection("orders").doc("last"),
        orderData: { status: "pending" },
        externalOrderId: `${label}-last`,
        now: NOW,
      });
      assert.equal(accepted.slot, max);
      assert.equal(db.docs.get(`plan_usage/${id}`).orders_consumed, max);
      assert.equal(db.docs.get("trial_quota/trialCo").orders_consumed, 100);
      await assert.rejects(
        () =>
          placePaidOrder(db, {
            companyId: id,
            company: company(max, 0),
            orderRef: db.collection("orders").doc("over"),
            orderData: { status: "pending" },
            externalOrderId: `${label}-over`,
            now: NOW,
          }),
        (error) => error instanceof PlanQuotaError,
      );
      assert.equal(db.docs.has("orders/over"), false);
      assert.equal(db.docs.get(`counter/${counterDocId("delivery")}`).current, 5);
    });
  }

  it("does not consume a second order for the same Shopify id", async () => {
    const db = createFakeDb();
    const first = await placePaidOrder(db, {
      companyId: "pro",
      company: company(3000, 2000),
      orderRef: db.collection("orders").doc("a"),
      orderData: { status: "pending" },
      externalOrderId: "shop-1",
      now: NOW,
    });
    const second = await placePaidOrder(db, {
      companyId: "pro",
      company: company(3000, 2000),
      orderRef: db.collection("orders").doc("b"),
      orderData: { status: "pending" },
      externalOrderId: "shop-1",
      now: NOW,
    });
    assert.equal(second.duplicate, true);
    assert.equal(second.orderId, first.orderId);
    assert.equal(db.docs.get("plan_usage/pro").orders_consumed, 1);
    assert.equal(db.docs.has("orders/b"), false);
  });

  it("lets only one concurrent order take the last slot", async () => {
    const db = createFakeDb();
    db.docs.set("plan_usage/pro", {
      period_id: "bill-1",
      orders_consumed: 2999,
      broadcast_consumed: 0,
    });
    const results = await Promise.allSettled([
      placePaidOrder(db, {
        companyId: "pro",
        company: company(3000, 2000),
        orderRef: db.collection("orders").doc("race-a"),
        orderData: { status: "pending" },
        externalOrderId: "race-a",
        now: NOW,
      }),
      placePaidOrder(db, {
        companyId: "pro",
        company: company(3000, 2000),
        orderRef: db.collection("orders").doc("race-b"),
        orderData: { status: "pending" },
        externalOrderId: "race-b",
        now: NOW,
      }),
    ]);
    assert.equal(results.filter((item) => item.status === "fulfilled").length, 1);
    assert.equal(results.filter((item) => item.status === "rejected").length, 1);
    assert.equal(db.docs.get("plan_usage/pro").orders_consumed, 3000);
  });

  for (const [label, max] of [
    ["pro", 2000],
    ["business", 10000],
  ]) {
    it(`accepts ${label} broadcast ${max} and rejects ${max + 1}`, async () => {
      const db = createFakeDb();
      db.docs.set(`plan_usage/${label}`, {
        period_id: "bill-1",
        orders_consumed: 3,
        broadcast_consumed: max - 1,
      });
      const accepted = await reserveBroadcast(db, {
        companyId: label,
        company: company(3000, max),
        attemptId: `${label}_ok`,
        count: 1,
        now: NOW,
      });
      assert.equal(accepted.consumed, max);
      const again = await reserveBroadcast(db, {
        companyId: label,
        company: company(3000, max),
        attemptId: `${label}_ok`,
        count: 1,
        now: NOW,
      });
      assert.equal(again.duplicate, true);
      assert.equal(db.docs.get(`plan_usage/${label}`).broadcast_consumed, max);
      await assert.rejects(
        () =>
          reserveBroadcast(db, {
            companyId: label,
            company: company(3000, max),
            attemptId: `${label}_over`,
            count: 1,
            now: NOW,
          }),
        (error) => error instanceof PlanQuotaError,
      );
      assert.equal(db.docs.get(`plan_usage/${label}`).orders_consumed, 3);
    });
  }

  it("releases a failed launcher reservation and ignores a second release", async () => {
    const db = createFakeDb();
    await reserveBroadcast(db, {
      companyId: "pro",
      company: company(3000, 2000),
      attemptId: "pro_one",
      count: 2,
      now: NOW,
    });
    const released = await releaseBroadcast(db, {
      companyId: "pro",
      attemptId: "pro_one",
    });
    assert.equal(released.released, true);
    assert.equal(released.consumed, 0);
    const second = await releaseBroadcast(db, {
      companyId: "pro",
      attemptId: "pro_one",
    });
    assert.equal(second.released, false);
    assert.equal(db.docs.get("plan_usage/pro").broadcast_consumed, 0);
  });

  it("marks an opened handoff once and does not call it delivered", async () => {
    const db = createFakeDb();
    await reserveBroadcast(db, {
      companyId: "pro",
      company: company(3000, 2000),
      attemptId: "pro_open",
      count: 1,
      now: NOW,
    });
    const opened = await markBroadcastOpened(db, {
      companyId: "pro",
      attemptId: "pro_open",
    });
    const again = await markBroadcastOpened(db, {
      companyId: "pro",
      attemptId: "pro_open",
    });
    assert.equal(opened.opened, true);
    assert.equal(again.duplicate, true);
    assert.equal(db.docs.get("broadcast_reservations/pro_open").status, "opened");
    assert.notEqual(
      db.docs.get("broadcast_reservations/pro_open").status,
      "delivered",
    );
  });

  it("lets only one concurrent broadcast take the last recipient", async () => {
    const db = createFakeDb();
    db.docs.set("plan_usage/pro", {
      period_id: "bill-1",
      orders_consumed: 0,
      broadcast_consumed: 1999,
    });
    const results = await Promise.allSettled([
      reserveBroadcast(db, {
        companyId: "pro",
        company: company(3000, 2000),
        attemptId: "pro_a",
        count: 1,
        now: NOW,
      }),
      reserveBroadcast(db, {
        companyId: "pro",
        company: company(3000, 2000),
        attemptId: "pro_b",
        count: 1,
        now: NOW,
      }),
    ]);
    assert.equal(results.filter((item) => item.status === "fulfilled").length, 1);
    assert.equal(results.filter((item) => item.status === "rejected").length, 1);
    assert.equal(db.docs.get("plan_usage/pro").broadcast_consumed, 2000);
  });
});
