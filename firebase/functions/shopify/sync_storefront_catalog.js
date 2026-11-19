const KNOWN_CATEGORIES = [
  "Funeral",
  "Hand Bouquet",
  "Wreath",
  "Opening Stand",
  "Wedding",
  "Ad-Hoc",
];

class StorefrontSyncError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "StorefrontSyncError";
    this.code = code;
  }
}

function nameKey(name) {
  return String(name || "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function skuKey(sku) {
  return String(sku || "").trim().toLowerCase();
}

function keepInternalProduct(data) {
  const name = nameKey(data?.name);
  const sku = skuKey(data?.sku);
  const category = String(data?.category || "").trim().toLowerCase();
  if (
    name === "delivery" ||
    name.includes("delivery fee") ||
    sku === "001" ||
    sku.includes("delivery")
  ) {
    return true;
  }
  if (name === "custom" || name.includes("custom product") || sku === "custom") {
    return true;
  }
  if (category === "funeral") {
    return true;
  }
  return false;
}

function parseStorefrontWebsite(raw) {
  const trimmed = String(raw || "").trim();
  if (!trimmed) {
    return null;
  }
  const withScheme = /:\/\//.test(trimmed) ? trimmed : `https://${trimmed}`;
  let url;
  try {
    url = new URL(withScheme);
  } catch (_) {
    return null;
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    return null;
  }
  const host = String(url.hostname || "").trim().toLowerCase();
  if (!host || !host.includes(".")) {
    return null;
  }
  const origin = `${url.protocol}//${host}${url.port ? `:${url.port}` : ""}`;
  return { host, origin, website: origin };
}

function slugSku(handle, productId, variantId) {
  let raw = String(handle || "")
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  if (!raw) {
    raw = `SHOPIFY-${productId}`;
  }
  if (raw.length > 40) {
    raw = raw.slice(0, 40).replace(/-+$/g, "");
  }
  const suffix = String(variantId || productId).slice(-6);
  return `${raw}-${suffix}`;
}

function pickImage(product) {
  const images = Array.isArray(product.images) ? product.images : [];
  const jpeg = images.find((image) => {
    const src = String(image?.src || "").toLowerCase();
    return src && !src.includes(".heic") && !src.includes(".heif");
  });
  const chosen = jpeg || images[0];
  const src = chosen?.src ? String(chosen.src).split("?")[0] : "";
  return src;
}

function mapCategory(product) {
  const raw = String(product.product_type || "").trim();
  const tags = Array.isArray(product.tags) ? product.tags : [];
  const handle = String(product.handle || "").toLowerCase();
  const haystack = [raw, ...tags, handle].join(" ").toLowerCase();
  if (haystack.includes("wedding") || haystack.includes("bridal") || haystack.includes("solemnisation")) {
    return "Wedding";
  }
  if (haystack.includes("funeral") || haystack.includes("condolence")) {
    return "Funeral";
  }
  if (haystack.includes("wreath")) {
    return "Wreath";
  }
  if (haystack.includes("opening") || haystack.includes("stand")) {
    return "Opening Stand";
  }
  if (
    haystack.includes("bouquet") ||
    haystack.includes("hand bouquet") ||
    haystack.includes("roses")
  ) {
    return "Hand Bouquet";
  }
  const known = KNOWN_CATEGORIES.find(
    (name) => name.toLowerCase() === raw.toLowerCase(),
  );
  return known || raw || "Ad-Hoc";
}

function expandRows(products, storeHost) {
  const rows = [];
  for (const product of products) {
    const title = String(product.title || "").trim();
    if (!title) {
      continue;
    }
    const handle = String(product.handle || "").trim();
    const productId = product.id != null ? String(product.id) : "";
    const category = mapCategory(product);
    const image = pickImage(product);
    const variants = Array.isArray(product.variants) && product.variants.length
      ? product.variants
      : [{}];
    for (const variant of variants) {
      const price = Number.parseFloat(variant.price);
      if (!(price > 0)) {
        continue;
      }
      const option1 = String(variant.option1 || "").trim();
      let name = title;
      if (
        option1 &&
        !["default title", "default", "title"].includes(option1.toLowerCase())
      ) {
        name = `${title} - ${option1}`;
      }
      const sku =
        String(variant.sku || "").trim() ||
        slugSku(handle, productId, variant.id);
      rows.push({
        name,
        title,
        sku,
        price,
        category,
        isActive: variant.available !== false,
        image,
        shopifyProductId: productId,
        shopifyVariantId: variant.id != null ? String(variant.id) : "",
        handle,
        url: handle
          ? `https://${storeHost}/products/${handle}`
          : `https://${storeHost}`,
      });
    }
  }
  return rows;
}

async function fetchStorefrontProducts(storeHost, fetchImpl = fetch) {
  const products = [];
  for (let page = 1; page <= 50; page += 1) {
    const url = `https://${storeHost}/products.json?limit=250&page=${page}`;
    const response = await fetchImpl(url, {
      headers: { "User-Agent": "EmberCore-StorefrontSync/1.0" },
    });
    if (!response.ok) {
      throw new StorefrontSyncError(
        "unavailable",
        `Storefront fetch failed ${response.status}`,
      );
    }
    const body = await response.json();
    const batch = Array.isArray(body.products) ? body.products : [];
    if (batch.length === 0) {
      break;
    }
    products.push(...batch);
    if (batch.length < 250) {
      break;
    }
  }
  return products;
}

function tfgPrice(data) {
  const value = data?.price;
  if (typeof value === "number") {
    return value;
  }
  if (value != null && value !== "") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return null;
}

function unusedList(list, usedIds) {
  return (list || []).filter((record) => !usedIds.has(record.id));
}

function coreName(name) {
  return nameKey(name)
    .replace(/\s*-\s*(small|medium|large|deluxe|luxury|premium|default title)\b.*$/, "")
    .trim();
}

function namesAlign(tfgName, row) {
  const a = coreName(tfgName);
  const b = coreName(row.name);
  const c = coreName(row.title);
  if (!a || (!b && !c)) {
    return false;
  }
  return a === b || a === c || b.includes(a) || a.includes(b) || a.includes(c) || c.includes(a);
}

function pushIndex(map, key, row) {
  if (!key) {
    return;
  }
  const list = map.get(key) || [];
  list.push(row);
  map.set(key, list);
}

function pickMatch(row, indexes, usedIds, variantCountByProduct) {
  if (row.shopifyVariantId && indexes.byVid.has(row.shopifyVariantId)) {
    const hit = indexes.byVid.get(row.shopifyVariantId);
    if (hit && !usedIds.has(hit.id)) {
      return hit;
    }
  }
  const skuHits = unusedList(indexes.bySku.get(skuKey(row.sku)), usedIds).filter((record) =>
    namesAlign(record.data.name, row),
  );
  if (skuHits.length === 1) {
    return skuHits[0];
  }
  const nameHits = unusedList(indexes.byName.get(nameKey(row.name)), usedIds);
  if (nameHits.length === 1) {
    return nameHits[0];
  }
  const variantCount = variantCountByProduct.get(row.shopifyProductId) || 0;
  if (variantCount === 1) {
    const pidHits = unusedList(indexes.byPid.get(row.shopifyProductId), usedIds).filter(
      (record) => namesAlign(record.data.name, row),
    );
    if (pidHits.length === 1) {
      return pidHits[0];
    }
    const titleHits = unusedList(indexes.byName.get(nameKey(row.title)), usedIds);
    if (titleHits.length === 1) {
      return titleHits[0];
    }
  }
  return null;
}

async function ensureCategories(db, companyRef, companyId, needed, dryRun) {
  const docRef = db.collection("product_categories").doc(companyId);
  const snap = await docRef.get();
  const existing = snap.exists
    ? (snap.data().categories || []).map((value) => String(value).trim())
    : [];
  const seen = new Set(existing.map((value) => value.toLowerCase()));
  const merged = [...existing];
  for (const name of needed) {
    if (!name || seen.has(name.toLowerCase())) {
      continue;
    }
    seen.add(name.toLowerCase());
    merged.push(name);
  }
  merged.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
  if (merged.length !== existing.length && !dryRun) {
    await docRef.set(
      {
        companyRef,
        categories: merged,
        updated_time: new Date(),
      },
      { merge: true },
    );
  }
  return merged;
}

function publicRow(row) {
  return {
    id: row.id || null,
    name: row.name,
    sku: row.sku,
    price: row.price ?? row.to ?? null,
    from: row.from,
    to: row.to,
    category: row.category || "",
  };
}

async function syncStorefrontCatalog(db, options = {}) {
  const companyId = String(options.companyId || "").trim();
  const parsed = parseStorefrontWebsite(options.website || options.storeHost);
  if (!companyId) {
    throw new StorefrontSyncError("invalid-argument", "companyId is required");
  }
  if (!parsed) {
    throw new StorefrontSyncError("invalid-argument", "Website URL is required");
  }
  const dryRun = options.dryRun === true;
  const deactivateExtra = options.deactivateExtra !== false;
  const storeHost = parsed.host;
  const companyRef = db.collection("Companies").doc(companyId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    throw new StorefrontSyncError("not-found", "Company not found");
  }

  const storefront = await fetchStorefrontProducts(
    storeHost,
    options.fetchImpl || fetch,
  );
  const rows = expandRows(storefront, storeHost);
  const existingSnap = await db
    .collection("product")
    .where("companyRef", "==", companyRef)
    .get();

  const indexes = {
    byVid: new Map(),
    byPid: new Map(),
    bySku: new Map(),
    byName: new Map(),
  };
  for (const doc of existingSnap.docs) {
    const data = doc.data() || {};
    const productId = String(data.shopifyProductId || "").trim();
    const variantId = String(data.shopifyVariantId || "").trim();
    const record = { id: doc.id, ref: doc.ref, data };
    if (productId) {
      pushIndex(indexes.byPid, productId, record);
    }
    if (variantId) {
      indexes.byVid.set(variantId, record);
    }
    const sku = skuKey(data.sku);
    if (sku) {
      pushIndex(indexes.bySku, sku, record);
    }
    const key = nameKey(data.name);
    if (key) {
      pushIndex(indexes.byName, key, record);
    }
  }

  const variantCountByProduct = new Map();
  for (const row of rows) {
    if (!row.shopifyProductId) {
      continue;
    }
    variantCountByProduct.set(
      row.shopifyProductId,
      (variantCountByProduct.get(row.shopifyProductId) || 0) + 1,
    );
  }

  const usedIds = new Set();
  const priceUpdates = [];

  function parentHitsFor(row) {
    const fromName = unusedList(indexes.byName.get(nameKey(row.title)), usedIds);
    const fromPid = unusedList(indexes.byPid.get(row.shopifyProductId), usedIds).filter(
      (record) => namesAlign(record.data.name, row),
    );
    const byId = new Map();
    for (const record of [...fromName, ...fromPid]) {
      byId.set(record.id, record);
    }
    return [...byId.values()];
  }

  function queuedUpdate(hit, row) {
    usedIds.add(hit.id);
    const current = tfgPrice(hit.data);
    const patch = {};
    if (current == null || Math.abs(current - row.price) >= 0.005) {
      patch.price = row.price;
    }
    if (
      row.name &&
      nameKey(hit.data.name) === nameKey(row.title) &&
      nameKey(row.name) !== nameKey(row.title)
    ) {
      patch.name = row.name;
    }
    if (!patch.price && !patch.name) {
      return;
    }
    priceUpdates.push({
      id: hit.id,
      ref: hit.ref,
      name: patch.name || hit.data.name || row.name,
      sku: hit.data.sku || row.sku,
      from: current,
      to: patch.price != null ? patch.price : current,
      patch,
      category: hit.data.category || row.category,
    });
  }

  const unmatched = [];
  for (const row of rows) {
    const hit = pickMatch(row, indexes, usedIds, variantCountByProduct);
    if (!hit) {
      unmatched.push(row);
      continue;
    }
    queuedUpdate(hit, row);
  }

  const leftover = [];
  const groupedMissing = new Map();
  for (const row of unmatched) {
    const key = row.shopifyProductId || nameKey(row.title);
    const list = groupedMissing.get(key) || [];
    list.push(row);
    groupedMissing.set(key, list);
  }
  for (const group of groupedMissing.values()) {
    const parents = parentHitsFor(group[0]);
    const chosen =
      parents.length === 1
        ? group.find((row) => {
            const current = tfgPrice(parents[0].data);
            return current != null && Math.abs(current - row.price) < 0.005;
          }) || group[0]
        : null;
    for (const row of group) {
      if (chosen && row === chosen) {
        queuedUpdate(parents[0], row);
        continue;
      }
      leftover.push(row);
    }
  }

  await ensureCategories(
    db,
    companyRef,
    companyId,
    leftover.map((row) => row.category),
    dryRun,
  );

  const created = [];
  for (const row of leftover) {
    if (!dryRun) {
      const docRef = db.collection("product").doc();
      await docRef.set({
        name: row.name,
        sku: row.sku,
        price: row.price,
        category: row.category,
        isActive: row.isActive,
        image: row.image,
        Image: row.image,
        shopifyProductId: row.shopifyProductId,
        shopifyVariantId: row.shopifyVariantId,
        companyRef,
      });
      created.push({ id: docRef.id, ...row });
    } else {
      created.push(row);
    }
  }

  for (const row of priceUpdates) {
    if (!dryRun) {
      await row.ref.update(row.patch || { price: row.to });
    }
  }

  const extras = [];
  const keptInternal = [];
  if (deactivateExtra) {
    for (const doc of existingSnap.docs) {
      const data = doc.data() || {};
      if (usedIds.has(doc.id) || data.isActive === false) {
        continue;
      }
      const row = {
        id: doc.id,
        ref: doc.ref,
        name: data.name || "",
        sku: data.sku || "",
        price: tfgPrice(data),
        category: data.category || "",
      };
      if (keepInternalProduct(data)) {
        keptInternal.push(row);
        continue;
      }
      extras.push(row);
    }
    if (!dryRun) {
      for (const row of extras) {
        await row.ref.update({ isActive: false });
      }
    }
  }

  if (!dryRun && options.persistWebsite !== false) {
    await companyRef.set({ website: parsed.website }, { merge: true });
  }

  return {
    website: parsed.website,
    storeHost,
    dryRun,
    storefrontProducts: storefront.length,
    pricedVariants: rows.length,
    firestoreProducts: existingSnap.size,
    created: created.map(publicRow),
    priceUpdates: priceUpdates.map(publicRow),
    deactivated: extras.map(publicRow),
    keptInternal: keptInternal.map((row) => ({
      id: row.id,
      name: row.name,
      sku: row.sku,
    })),
    createdCount: created.length,
    priceUpdateCount: priceUpdates.length,
    deactivatedCount: extras.length,
  };
}

module.exports = {
  StorefrontSyncError,
  parseStorefrontWebsite,
  expandRows,
  mapCategory,
  keepInternalProduct,
  namesAlign,
  pickMatch,
  fetchStorefrontProducts,
  syncStorefrontCatalog,
};
