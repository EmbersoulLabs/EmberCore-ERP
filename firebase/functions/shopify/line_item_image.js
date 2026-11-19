/**
 * Resolve Ember Core product images for Shopify paid line items.
 * Lookup is company-catalog only. Image failure never fails ingestion.
 */

const IMAGE_SOURCE = {
  variant: "variant",
  product: "product",
  webhook: "webhook",
  sku: "sku",
  none: "none",
};

function normalizeShopifyResourceId(raw) {
  const value = String(raw ?? "").trim();
  if (!value) {
    return "";
  }
  const gid = value.match(
    /gid:\/\/shopify\/(?:ProductVariant|Product|Variant)\/(\d+)/i,
  );
  if (gid) {
    return gid[1];
  }
  return value;
}

function isTrustworthyImageUrl(raw) {
  if (typeof raw !== "string") {
    return false;
  }
  const url = raw.trim();
  if (!url) {
    return false;
  }
  const lower = url.toLowerCase();
  if (
    lower.startsWith("data:") ||
    lower.startsWith("blob:") ||
    lower.startsWith("file:") ||
    lower.startsWith("javascript:")
  ) {
    return false;
  }
  return lower.startsWith("https://") || lower.startsWith("gs://");
}

function canonicalProductImage(product) {
  if (!product || typeof product !== "object") {
    return "";
  }
  const candidates = [product.image, product.Image];
  for (const candidate of candidates) {
    if (isTrustworthyImageUrl(candidate)) {
      return String(candidate).trim();
    }
  }
  return "";
}

function addToIndex(map, key, product) {
  if (!key) {
    return;
  }
  const list = map.get(key) || [];
  list.push(product);
  map.set(key, list);
}

function indexProductImageCatalog(products) {
  const byVariantId = new Map();
  const byProductId = new Map();
  const bySku = new Map();
  for (const product of products || []) {
    addToIndex(
      byVariantId,
      normalizeShopifyResourceId(product.shopifyVariantId),
      product,
    );
    addToIndex(
      byProductId,
      normalizeShopifyResourceId(product.shopifyProductId),
      product,
    );
    const sku = String(product.sku || "").trim().toLowerCase();
    addToIndex(bySku, sku, product);
  }
  return { byVariantId, byProductId, bySku };
}

function uniqueProduct(list) {
  if (!Array.isArray(list) || list.length !== 1) {
    return null;
  }
  return list[0];
}

function sharedCatalogImage(list) {
  if (!Array.isArray(list) || list.length === 0) {
    return null;
  }
  const urls = [
    ...new Set(list.map(canonicalProductImage).filter(Boolean)),
  ];
  if (urls.length !== 1) {
    return null;
  }
  const product = list.find((item) => canonicalProductImage(item) === urls[0]);
  return { product, imageUrl: urls[0] };
}

function resolveShopifyLineItemImage(lineItem, catalog) {
  const item = lineItem && typeof lineItem === "object" ? lineItem : {};
  const variantId = normalizeShopifyResourceId(
    item.variantId || item.variant_id,
  );
  const productId = normalizeShopifyResourceId(
    item.productId || item.product_id,
  );
  const sku = String(item.sku || "").trim().toLowerCase();
  const webhookRaw = item.imageUrl || item.image;
  const webhookImage = isTrustworthyImageUrl(webhookRaw)
    ? String(webhookRaw).trim()
    : "";

  if (variantId && catalog?.byVariantId) {
    const matches = catalog.byVariantId.get(variantId) || [];
    const unique = uniqueProduct(matches);
    if (unique) {
      const variantImage = canonicalProductImage(unique);
      if (variantImage) {
        return {
          imageUrl: variantImage,
          imageSource: IMAGE_SOURCE.variant,
          product: unique,
        };
      }
    } else {
      const sharedVariant = sharedCatalogImage(matches);
      if (sharedVariant) {
        return {
          imageUrl: sharedVariant.imageUrl,
          imageSource: IMAGE_SOURCE.variant,
          product: sharedVariant.product,
        };
      }
    }
  }

  if (productId && catalog?.byProductId) {
    const matches = catalog.byProductId.get(productId) || [];
    const unique = uniqueProduct(matches);
    if (unique) {
      const productImage = canonicalProductImage(unique);
      if (productImage) {
        return {
          imageUrl: productImage,
          imageSource: IMAGE_SOURCE.product,
          product: unique,
        };
      }
    } else {
      const sharedProduct = sharedCatalogImage(matches);
      if (sharedProduct) {
        return {
          imageUrl: sharedProduct.imageUrl,
          imageSource: IMAGE_SOURCE.product,
          product: sharedProduct.product,
        };
      }
    }
  }

  if (webhookImage) {
    return {
      imageUrl: webhookImage,
      imageSource: IMAGE_SOURCE.webhook,
      product: null,
    };
  }

  if (sku && catalog?.bySku) {
    const matches = catalog.bySku.get(sku) || [];
    const unique = uniqueProduct(matches);
    if (unique) {
      const skuImage = canonicalProductImage(unique);
      if (skuImage) {
        return {
          imageUrl: skuImage,
          imageSource: IMAGE_SOURCE.sku,
          product: unique,
        };
      }
    }
  }

  return {
    imageUrl: null,
    imageSource: IMAGE_SOURCE.none,
    product: null,
  };
}

function enrichReviewLineItemsWithImages(lineItems, catalog) {
  if (!Array.isArray(lineItems)) {
    return [];
  }
  return lineItems.map((item) => {
    try {
      const resolved = resolveShopifyLineItemImage(item, catalog);
      return {
        ...item,
        imageUrl: resolved.imageUrl || null,
        imageSource: resolved.imageSource,
      };
    } catch (_) {
      return {
        ...item,
        imageUrl: isTrustworthyImageUrl(item?.imageUrl) ? item.imageUrl : null,
        imageSource: item?.imageSource || IMAGE_SOURCE.none,
      };
    }
  });
}

async function loadProductImageCatalog(db, companyRef) {
  if (!db || !companyRef) {
    return indexProductImageCatalog([]);
  }
  const snap = await db
    .collection("product")
    .where("companyRef", "==", companyRef)
    .get();
  const products = snap.docs.map((doc) => {
    const data = doc.data() || {};
    return {
      id: doc.id,
      sku: data.sku || "",
      image: data.image || "",
      Image: data.Image || "",
      shopifyProductId: data.shopifyProductId || "",
      shopifyVariantId: data.shopifyVariantId || "",
    };
  });
  return indexProductImageCatalog(products);
}

module.exports = {
  IMAGE_SOURCE,
  normalizeShopifyResourceId,
  isTrustworthyImageUrl,
  canonicalProductImage,
  indexProductImageCatalog,
  resolveShopifyLineItemImage,
  enrichReviewLineItemsWithImages,
  loadProductImageCatalog,
};
