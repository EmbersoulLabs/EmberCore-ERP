import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '/backend/backend.dart';
import '/backend/custom_product_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/product_record.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';

enum AssetImageKind {
  product,
  customProduct,
}

/// One image file in Storage, optionally linked to catalog / order line data.
class AssetImageEntry {
  const AssetImageEntry({
    required this.storagePath,
    required this.downloadUrl,
    required this.kind,
    required this.label,
    this.parentId = '',
    this.productRef,
    this.orderItemRef,
  });

  final String storagePath;
  final String downloadUrl;
  final AssetImageKind kind;
  final String label;
  final String parentId;
  final DocumentReference? productRef;
  final DocumentReference? orderItemRef;

  String get id => storagePath;

  bool urlMatches(String url) {
    if (url.trim().isEmpty) {
      return false;
    }
    final a = firebaseObjectPathFromDownloadUrl(url.trim());
    final b = firebaseObjectPathFromDownloadUrl(downloadUrl.trim());
    if (a != null && b != null && a == b) {
      return true;
    }
    return url.trim() == downloadUrl.trim();
  }
}

/// Readable upload filename: `{label}_{timestamp}.{ext}`.
String catalogImageUploadFilename({
  required String label,
  required String originalFilename,
}) {
  final extMatch = RegExp(r'\.([a-zA-Z0-9]{2,5})$').firstMatch(originalFilename);
  final ext = extMatch?.group(1)?.toLowerCase() ?? 'jpg';
  final slug = label
      .trim()
      .replaceAll(RegExp(r'[^\w\-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = slug.isEmpty ? 'image' : slug;
  final trimmed = base.length > 48 ? base.substring(0, 48) : base;
  return '${trimmed}_${DateTime.now().millisecondsSinceEpoch}.$ext';
}

Future<AssetImageEntry?> _entryFromStorageItem({
  required Reference item,
  required AssetImageKind kind,
  required String label,
  required String parentId,
  DocumentReference? productRef,
  DocumentReference? orderItemRef,
}) async {
  try {
    final url = await item.getDownloadURL().timeout(const Duration(seconds: 8));
    return AssetImageEntry(
      storagePath: item.fullPath,
      downloadUrl: url,
      kind: kind,
      label: label,
      parentId: parentId,
      productRef: productRef,
      orderItemRef: orderItemRef,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _listFolderEntries({
  required String folderPath,
  required AssetImageKind kind,
  required String label,
  required String parentId,
  required void Function(AssetImageEntry entry) addEntry,
  DocumentReference? productRef,
  DocumentReference? orderItemRef,
}) async {
  try {
    final folder = FirebaseStorage.instance.ref(folderPath);
    final listing =
        await folder.listAll().timeout(const Duration(seconds: 12));
    final entries = await Future.wait(
      listing.items.map(
        (item) => _entryFromStorageItem(
          item: item,
          kind: kind,
          label: label,
          parentId: parentId,
          productRef: productRef,
          orderItemRef: orderItemRef,
        ),
      ),
    );
    for (final entry in entries) {
      if (entry != null) {
        addEntry(entry);
      }
    }
  } catch (_) {
    // Folder missing, list denied, or timed out — skip.
  }
}

/// Loads tenant catalog images without scanning every order item in the company.
///
/// Sources:
/// 1. Product docs with an image URL
/// 2. Storage folders `product_images/{productId}/`
/// 3. Order items that already have an image URL (custom products)
Future<List<AssetImageEntry>> loadTenantAssetImages() async {
  final products = await queryTenantProductRecordOnce();

  final byPath = <String, AssetImageEntry>{};

  void addEntry(AssetImageEntry entry) {
    if (entry.storagePath.isEmpty || entry.downloadUrl.isEmpty) {
      return;
    }
    byPath[entry.storagePath] = entry;
  }

  // Product docs + storage folders (parallel per product, hard timeout).
  try {
    await Future.wait(
      products.map((product) async {
        final label =
            product.name.isNotEmpty ? product.name : product.sku;
        final imageUrl = productImageFromRecord(product);
        if (imageUrl.isNotEmpty) {
          final path = firebaseObjectPathFromDownloadUrl(imageUrl) ??
              productImageStoragePath(
                TenantContext.instance.writeCompanyId.isNotEmpty
                    ? TenantContext.instance.writeCompanyId
                    : 'unknown',
                product.reference.id,
                'linked.jpg',
              );
          addEntry(
            AssetImageEntry(
              storagePath: path,
              downloadUrl: imageUrl,
              kind: AssetImageKind.product,
              label: label,
              parentId: product.reference.id,
              productRef: product.reference,
            ),
          );
        }

        await _listFolderEntries(
          folderPath: 'product_images/${product.reference.id}',
          kind: AssetImageKind.product,
          label: label,
          parentId: product.reference.id,
          productRef: product.reference,
          addEntry: addEntry,
        );
      }),
    ).timeout(const Duration(seconds: 45));
  } catch (_) {
    // Partial product list is still useful if storage listing times out.
  }

  // Custom / line-item images: only docs that already store an image URL.
  // Avoids loading the entire Order_item collection for the tenant.
  List<OrderItemRecord> customItems = const [];
  try {
    customItems = await queryTenantOrderItemRecordOnce(
      queryBuilder: (q) => q.where('image', isNotEqualTo: ''),
      limit: 300,
    ).timeout(const Duration(seconds: 20));
  } catch (_) {
    // Index missing or timeout — still show product images.
    customItems = const [];
  }
  customItems =
      customItems.where((item) => item.image.trim().isNotEmpty).toList();

  await Future.wait(
    customItems.map((item) async {
      final label = item.name.isNotEmpty ? item.name : 'Custom item';
      final imageUrl = item.image.trim();
      final path = firebaseObjectPathFromDownloadUrl(imageUrl) ??
          customProductImageStoragePath(
            TenantContext.instance.writeCompanyId.isNotEmpty
                ? TenantContext.instance.writeCompanyId
                : 'unknown',
            item.reference.id,
            'linked.jpg',
          );
      addEntry(
        AssetImageEntry(
          storagePath: path,
          downloadUrl: imageUrl,
          kind: AssetImageKind.customProduct,
          label: label,
          parentId: item.reference.id,
          orderItemRef: item.reference,
        ),
      );

      await _listFolderEntries(
        folderPath: 'custom_product_images/${item.reference.id}',
        kind: AssetImageKind.customProduct,
        label: label,
        parentId: item.reference.id,
        orderItemRef: item.reference,
        addEntry: addEntry,
      );
    }),
  );

  final sorted = byPath.values.toList()
    ..sort((a, b) {
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) {
        return kind;
      }
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
  return sorted;
}

Future<void> _clearProductImageIfLinked(
  DocumentReference productRef,
  AssetImageEntry entry,
) async {
  final product = await ProductRecord.getDocumentOnce(productRef);
  final current = productImageFromRecord(product);
  if (!entry.urlMatches(current)) {
    return;
  }
  await productRef.update({
    'image': '',
    'Image': '',
  });
}

Future<void> _clearOrderItemImageIfLinked(
  DocumentReference orderItemRef,
  AssetImageEntry entry,
) async {
  final item = await OrderItemRecord.getDocumentOnce(orderItemRef);
  if (!entry.urlMatches(item.image)) {
    return;
  }
  await orderItemRef.update(createOrderItemRecordData(image: ''));
}

/// Deletes Storage object and clears Firestore image fields when linked.
Future<void> deleteAssetImageEntry(AssetImageEntry entry) async {
  try {
    await FirebaseStorage.instance.ref(entry.storagePath).delete();
  } on FirebaseException catch (e) {
    if (e.code != 'object-not-found') {
      rethrow;
    }
  }

  if (entry.productRef != null) {
    await _clearProductImageIfLinked(entry.productRef!, entry);
  }
  if (entry.orderItemRef != null) {
    await _clearOrderItemImageIfLinked(entry.orderItemRef!, entry);
  }
}

Future<int> deleteAssetImageEntries(List<AssetImageEntry> entries) async {
  var deleted = 0;
  for (final entry in entries) {
    await deleteAssetImageEntry(entry);
    deleted++;
  }
  return deleted;
}
