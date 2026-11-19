import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_context.dart';

/// Sort companies alphabetically by display name (client-side; avoids composite index).
List<CompaniesRecord> sortCompaniesByName(List<CompaniesRecord> companies) {
  final sorted = List<CompaniesRecord>.from(companies);
  sorted.sort(
    (a, b) => a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
  );
  return sorted;
}

/// Filters [companies] by name, phone, UEN, ID, or address (case-insensitive).
List<CompaniesRecord> filterCompaniesBySearchQuery(
  List<CompaniesRecord> companies,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return companies;
  }
  return companies.where((c) {
    return c.companyName.toLowerCase().contains(q) ||
        c.companyPhone.toLowerCase().contains(q) ||
        c.companyUen.toLowerCase().contains(q) ||
        c.companyId.toLowerCase().contains(q) ||
        c.companyAddress.toLowerCase().contains(q);
  }).toList();
}

/// Deterministic default company (alphabetical first). Superadmin must not
/// use this for receipts — use [queryLetterheadCompanyRecordForOrder].
Stream<List<CompaniesRecord>> queryDefaultCompanyRecord() =>
    queryCompaniesRecord(
      queryBuilder: (q) => q.orderBy('Company_name').limit(1),
    );

Future<CompaniesRecord?> getDefaultCompanyOnce() async {
  final records = await queryCompaniesRecordOnce(
    queryBuilder: (q) => q.orderBy('Company_name').limit(1),
  );
  return records.isNotEmpty ? records.first : null;
}

/// Letterhead for the selected tenant / order, never "first company by name".
Stream<List<CompaniesRecord>> queryLetterheadCompanyRecord([
  DocumentReference? companyRef,
]) {
  final ref = companyRef ??
      TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (ref != null) {
    return CompaniesRecord.getDocument(ref).map((company) => [company]);
  }
  return queryDefaultCompanyRecord();
}

Stream<List<CompaniesRecord>> queryLetterheadCompanyRecordForOrder(
  DocumentReference? orderRef,
) {
  if (orderRef == null) {
    return queryLetterheadCompanyRecord();
  }
  return OrdersRecord.getDocument(orderRef).asyncExpand(
    (order) => queryLetterheadCompanyRecord(order.companyRef),
  );
}

Future<CompaniesRecord?> getLetterheadCompany({
  DocumentReference? companyRef,
}) async {
  final refs = <DocumentReference>[];
  if (companyRef != null) {
    refs.add(companyRef);
  }
  final tenantRef = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (tenantRef != null &&
      (companyRef == null || tenantRef.path != companyRef.path)) {
    refs.add(tenantRef);
  }
  for (final ref in refs) {
    try {
      return await CompaniesRecord.getDocumentOnce(ref);
    } catch (_) {}
  }
  return getDefaultCompanyOnce();
}

/// Company letterhead for customer invoices (tenant / customer companyRef).
Future<CompaniesRecord?> resolveCustomerInvoiceCompany(
  CustomersRecord customer,
) async {
  final customerCompanyRef = customer.companyRef;
  if (customerCompanyRef != null) {
    try {
      return await CompaniesRecord.getDocumentOnce(customerCompanyRef);
    } catch (_) {
      // Fall through to active tenant company.
    }
  }
  final active = TenantContext.instance.activeCompany;
  if (active != null) {
    return active;
  }
  final activeRef = TenantContext.instance.activeCompanyRef;
  if (activeRef != null) {
    try {
      return await CompaniesRecord.getDocumentOnce(activeRef);
    } catch (_) {
      // Fall through to default company.
    }
  }
  return getLetterheadCompany();
}
