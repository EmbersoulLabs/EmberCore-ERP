/**
 * Minimal in-memory Firestore for Shopify ingest/approval unit tests.
 * Supports doc get/set/update, where+limit queries, transactions, and batches.
 */

function isServerTimestamp(value) {
  if (value == null || typeof value !== "object") {
    return false;
  }
  return (
    value._methodName === "FieldValue.serverTimestamp" ||
    value.constructor?.name === "ServerTimestampTransform" ||
    String(value.constructor?.name || "").includes("FieldTransform")
  );
}

function unwrapWriteValue(value) {
  if (isServerTimestamp(value)) {
    return new Date();
  }
  if (Array.isArray(value)) {
    return value.map(unwrapWriteValue);
  }
  if (value && typeof value === "object" && !(value instanceof Date) && !value.path) {
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = unwrapWriteValue(nested);
    }
    return out;
  }
  return value;
}

function fieldValue(data, field) {
  if (field.includes(".")) {
    return field.split(".").reduce((acc, part) => acc?.[part], data);
  }
  return data?.[field];
}

function valuesEqual(left, right) {
  if (left === right) {
    return true;
  }
  if (left?.path && right?.path) {
    return left.path === right.path;
  }
  if (left?.id && right?.id && left.path && right.path) {
    return left.path === right.path;
  }
  return false;
}

class FakeSnapshot {
  constructor(ref, data) {
    this.ref = ref;
    this._data = data;
    this.id = ref.id;
    this.exists = data != null;
  }
  data() {
    return this._data ? { ...this._data } : undefined;
  }
}

class FakeQuerySnapshot {
  constructor(docs) {
    this.docs = docs;
    this.empty = docs.length === 0;
    this.size = docs.length;
  }
}

class FakeDocRef {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    const parts = path.split("/");
    this.id = parts[parts.length - 1];
  }

  async get() {
    return this._db._snap(this.path);
  }

  async set(data, options = {}) {
    this._db._set(this.path, data, options);
  }

  async update(data) {
    this._db._update(this.path, data);
  }

  async delete() {
    this._db._delete(this.path);
  }
}

class FakeQuery {
  constructor(db, collectionName, filters = [], limitCount = null) {
    this._db = db;
    this._collectionName = collectionName;
    this._filters = filters;
    this._limitCount = limitCount;
    this._isQuery = true;
  }

  where(field, op, value) {
    return new FakeQuery(
      this._db,
      this._collectionName,
      [...this._filters, { field, op, value }],
      this._limitCount,
    );
  }

  limit(count) {
    return new FakeQuery(this._db, this._collectionName, this._filters, count);
  }

  async get() {
    return this._db._query(this);
  }
}

class FakeCollection {
  constructor(db, name) {
    this._db = db;
    this._name = name;
  }

  doc(id) {
    const docId = id == null || id === "" ? this._db._autoId() : String(id);
    return this._db._ref(`${this._name}/${docId}`);
  }

  where(field, op, value) {
    return new FakeQuery(this._db, this._name, [{ field, op, value }]);
  }

  async get() {
    return new FakeQuery(this._db, this._name).get();
  }
}

class FakeBatch {
  constructor(db) {
    this._db = db;
    this._ops = [];
  }

  set(ref, data, options = {}) {
    this._ops.push(() => this._db._set(ref.path, data, options));
    return this;
  }

  update(ref, data) {
    this._ops.push(() => this._db._update(ref.path, data));
    return this;
  }

  delete(ref) {
    this._ops.push(() => this._db._delete(ref.path));
    return this;
  }

  async commit() {
    for (const op of this._ops) {
      op();
    }
  }
}

class FakeFirestore {
  constructor() {
    this._docs = new Map();
    this._versions = new Map();
    this._seq = 0;
  }

  _autoId() {
    this._seq += 1;
    return `auto_${this._seq}`;
  }

  _ref(path) {
    return new FakeDocRef(this, path);
  }

  _version(path) {
    return this._versions.get(path) || 0;
  }

  _bump(path) {
    this._versions.set(path, this._version(path) + 1);
  }

  _cloneDocs() {
    const clone = new Map();
    for (const [path, data] of this._docs.entries()) {
      clone.set(path, { ...data });
    }
    return clone;
  }

  _writeTo(store, path, data, options = {}) {
    const next = unwrapWriteValue(data);
    if (options.merge && store.has(path)) {
      store.set(path, { ...store.get(path), ...next });
      return;
    }
    store.set(path, { ...next });
  }

  _set(path, data, options = {}) {
    this._writeTo(this._docs, path, data, options);
    this._bump(path);
  }

  _update(path, data) {
    if (!this._docs.has(path)) {
      throw new Error(`No document to update: ${path}`);
    }
    this._writeTo(this._docs, path, data, { merge: true });
    this._bump(path);
  }

  _delete(path) {
    this._docs.delete(path);
    this._bump(path);
  }

  _snapFrom(store, path) {
    return new FakeSnapshot(
      this._ref(path),
      store.has(path) ? { ...store.get(path) } : null,
    );
  }

  _snap(path) {
    return this._snapFrom(this._docs, path);
  }

  _matches(data, filters) {
    return filters.every((filter) => {
      const actual = fieldValue(data, filter.field);
      if (filter.op === "==") {
        return valuesEqual(actual, filter.value);
      }
      return false;
    });
  }

  _queryFrom(store, query) {
    const prefix = `${query._collectionName}/`;
    const docs = [];
    for (const [path, data] of store.entries()) {
      if (!path.startsWith(prefix) || path.slice(prefix.length).includes("/")) {
        continue;
      }
      if (!this._matches(data, query._filters)) {
        continue;
      }
      docs.push(new FakeSnapshot(this._ref(path), { ...data }));
    }
    const limited =
      query._limitCount == null ? docs : docs.slice(0, query._limitCount);
    return new FakeQuerySnapshot(limited);
  }

  _query(query) {
    return this._queryFrom(this._docs, query);
  }

  collection(name) {
    return new FakeCollection(this, name);
  }

  batch() {
    return new FakeBatch(this);
  }

  /**
   * Optimistic-concurrency transactions with automatic retry, matching
   * Firestore: reads see a snapshot, writes commit atomically, overlapping
   * writes to the same document retry instead of colliding.
   */
  async runTransaction(fn, { maxAttempts = 25 } = {}) {
    let lastError;
    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      await Promise.resolve();
      const snapshot = this._cloneDocs();
      const readVersions = new Map();
      const writes = new Map();

      const visible = (path) => {
        if (writes.has(path)) {
          const write = writes.get(path);
          if (write.op === "delete") {
            return null;
          }
          const base = snapshot.has(path) ? { ...snapshot.get(path) } : {};
          if (write.op === "update" || write.options?.merge) {
            return { ...base, ...unwrapWriteValue(write.data) };
          }
          return { ...unwrapWriteValue(write.data) };
        }
        return snapshot.has(path) ? { ...snapshot.get(path) } : null;
      };

      const tx = {
        get: async (refOrQuery) => {
          await Promise.resolve();
          if (refOrQuery?._isQuery) {
            const result = this._queryFrom(snapshot, refOrQuery);
            for (const doc of result.docs) {
              readVersions.set(doc.ref.path, this._version(doc.ref.path));
            }
            return result;
          }
          const path = refOrQuery.path;
          if (!readVersions.has(path) && !writes.has(path)) {
            readVersions.set(path, this._version(path));
          }
          const data = visible(path);
          return new FakeSnapshot(this._ref(path), data);
        },
        set: (ref, data, options = {}) => {
          writes.set(ref.path, { op: "set", data, options });
        },
        update: (ref, data) => {
          writes.set(ref.path, { op: "update", data, options: { merge: true } });
        },
        delete: (ref) => {
          writes.set(ref.path, { op: "delete" });
        },
      };

      try {
        const result = await fn(tx);
        for (const [path, version] of readVersions.entries()) {
          if (this._version(path) !== version) {
            const contention = new Error("transaction contention");
            contention.code = "aborted";
            throw contention;
          }
        }
        for (const [path, write] of writes.entries()) {
          if (write.op === "delete") {
            this._delete(path);
            continue;
          }
          if (write.op === "update" && !this._docs.has(path) && !visible(path)) {
            throw new Error(`No document to update: ${path}`);
          }
          if (write.op === "update") {
            this._update(path, write.data);
          } else {
            this._set(path, write.data, write.options);
          }
        }
        return result;
      } catch (error) {
        lastError = error;
        const retryable = error?.code === "aborted";
        if (!retryable || attempt === maxAttempts) {
          throw error;
        }
      }
    }
    throw lastError;
  }

  docData(path) {
    return this._docs.has(path) ? { ...this._docs.get(path) } : null;
  }

  docsIn(collectionName) {
    const prefix = `${collectionName}/`;
    const out = [];
    for (const [path, data] of this._docs.entries()) {
      if (path.startsWith(prefix) && !path.slice(prefix.length).includes("/")) {
        out.push({ path, data: { ...data } });
      }
    }
    return out;
  }
}

module.exports = { FakeFirestore };
