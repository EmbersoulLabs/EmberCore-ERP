import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/backend/schema/customers_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/uploaded_file.dart';

/// Columns compatible with [parseCustomerImportFile] in customer_import_helpers.dart.
const kCustomerExportCsvHeaders = [
  'Name',
  'Phone',
  'Email',
  'Billing Address',
  'UEN',
  'Credit Customer',
  'Credit Term',
];

String _escapeCsvCell(String cell) => '"${cell.replaceAll('"', '""')}"';

String customersToCsvString(List<List<String>> rows) {
  return rows.map((row) => row.map(_escapeCsvCell).join(',')).join('\n');
}

Uint8List encodeCustomerCsvUtf8Bytes(String csv) {
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
}

List<String> buildCustomerExportRow(CustomersRecord customer) {
  return [
    customer.name,
    customer.phone,
    customer.email,
    customer.billingAddress,
    customer.uen,
    customer.isCreditCustomer ? 'Yes' : 'No',
    customer.creditTerm,
  ];
}

FFUploadedFile buildCustomersCsvFile(List<CustomersRecord> customers) {
  final rows = <List<String>>[kCustomerExportCsvHeaders];
  for (final customer in customers) {
    rows.add(buildCustomerExportRow(customer));
  }
  final csv = customersToCsvString(rows);
  return FFUploadedFile(
    name: 'customers_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: encodeCustomerCsvUtf8Bytes(csv),
  );
}

Future<void> downloadCustomersCsv({
  required BuildContext context,
  required List<CustomersRecord> customers,
  String? filenameBase,
}) async {
  if (customers.isEmpty) {
    throw Exception('No customers to export');
  }

  final file = buildCustomersCsvFile(customers);
  final base =
      filenameBase ?? 'customers_${DateTime.now().millisecondsSinceEpoch}';
  final filename = base.endsWith('.csv') ? base : '$base.csv';

  await downloadFile(
    filename: filename,
    uploadedFile: file,
  );
}
