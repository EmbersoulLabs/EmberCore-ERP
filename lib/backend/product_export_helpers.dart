import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/backend/product_edit_helpers.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/uploaded_file.dart';

/// Columns compatible with [parseProductImportFile] in product_import_helpers.dart.
const kProductExportCsvHeaders = [
  'Name',
  'SKU',
  'Price',
  'Category',
  'Active',
  'Image',
];

String _escapeCsvCell(String cell) => '"${cell.replaceAll('"', '""')}"';

String productsToCsvString(List<List<String>> rows) {
  return rows.map((row) => row.map(_escapeCsvCell).join(',')).join('\n');
}

Uint8List encodeProductCsvUtf8Bytes(String csv) {
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
}

List<String> buildProductExportRow(ProductRecord product) {
  final image = product.image.isNotEmpty
      ? product.image
      : productImageFromRecord(product);
  return [
    product.name,
    product.sku,
    product.price.toStringAsFixed(2),
    product.category,
    product.isActive ? 'Yes' : 'No',
    image,
  ];
}

FFUploadedFile buildProductsCsvFile(List<ProductRecord> products) {
  final rows = <List<String>>[kProductExportCsvHeaders];
  for (final product in products) {
    rows.add(buildProductExportRow(product));
  }
  final csv = productsToCsvString(rows);
  return FFUploadedFile(
    name: 'products_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: encodeProductCsvUtf8Bytes(csv),
  );
}

Future<void> downloadProductsCsv({
  required BuildContext context,
  required List<ProductRecord> products,
  String? filenameBase,
}) async {
  if (products.isEmpty) {
    throw Exception('No products to export');
  }

  final file = buildProductsCsvFile(products);
  final base =
      filenameBase ?? 'products_${DateTime.now().millisecondsSinceEpoch}';
  final filename = base.endsWith('.csv') ? base : '$base.csv';

  await downloadFile(
    filename: filename,
    uploadedFile: file,
  );
}
