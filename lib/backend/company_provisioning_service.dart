import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/registration_approval_service.dart';
import '/backend/schema/companies_record.dart';
import '/backend/subscription_helpers.dart';
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
    ...defaultSubscriptionRecordData(),
  });

  await initializeNewTenantFirestore(companyRef);
  return companyRef;
}
