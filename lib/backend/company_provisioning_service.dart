import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/registration_approval_service.dart';
import '/backend/schema/companies_record.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Creates a [Companies] document and initializes tenant defaults.
Future<DocumentReference> provisionNewCompanyDocument({
  required String companyName,
  String companyPhone = '',
  String companyAddress = '',
  String companyUen = '',
  String? logoUrl,
}) async {
  final companyRef = CompaniesRecord.collection.doc();
  final companyId = companyRef.id;

  await companyRef.set({
    ...createCompaniesRecordData(
      companyId: companyId,
      companyName: companyName.trim(),
      companyPhone: companyPhone.trim(),
      companyAddress: companyAddress.trim(),
      companyUen: companyUen.trim(),
      isActive: true,
      createdAt: getCurrentTimestamp,
      logo: (logoUrl ?? '').trim().isEmpty ? null : logoUrl!.trim(),
    ),
  });

  try {
    await initializeNewTenantFirestore(companyRef);
  } catch (error) {
    throw StateError(
      'Company "$companyName" was created, but tenant setup failed '
      '(staff roles / permissions). ${error.toString()} '
      'Fix Firestore rules, then open this company as superadmin and retry setup, '
      'or add the director from User List.',
    );
  }
  return companyRef;
}
