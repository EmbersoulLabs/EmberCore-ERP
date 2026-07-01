import '/backend/backend.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/tenant_company_helpers.dart';

class TenantAdminSummary {
  const TenantAdminSummary({
    required this.company,
    required this.staffCount,
  });

  final CompaniesRecord company;
  final int staffCount;
}

class TenantAdminMutationResult {
  const TenantAdminMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

/// Loads all tenants with staff counts (superadmin only).
Future<List<TenantAdminSummary>> loadTenantAdminSummaries() async {
  if (!isSuperAdminRole(currentViewerRole())) {
    return const [];
  }

  final companies = await queryCompaniesRecordOnce(
    queryBuilder: (q) => q.orderBy('Company_name'),
  );
  final staffCounts = await _countStaffByCompanyId();

  return companies
      .map(
        (company) => TenantAdminSummary(
          company: company,
          staffCount:
              staffCounts[canonicalCompanyId(company.reference.id)] ?? 0,
        ),
      )
      .toList(growable: false);
}

Stream<List<TenantAdminSummary>> streamTenantAdminSummaries() async* {
  if (!isSuperAdminRole(currentViewerRole())) {
    yield const [];
    return;
  }

  await for (final companies in queryCompaniesRecord(
    queryBuilder: (q) => q.orderBy('Company_name'),
  )) {
    final staffCounts = await _countStaffByCompanyId();
    yield companies
        .map(
          (company) => TenantAdminSummary(
            company: company,
            staffCount:
                staffCounts[canonicalCompanyId(company.reference.id)] ?? 0,
          ),
        )
        .toList(growable: false);
  }
}

Future<Map<String, int>> _countStaffByCompanyId() async {
  final users = await queryUsersRecordOnce(limit: 5000);
  final counts = <String, int>{};
  for (final user in users) {
    final ref = user.companyRef;
    if (ref == null) {
      continue;
    }
    final companyId = canonicalCompanyId(ref.id);
    counts[companyId] = (counts[companyId] ?? 0) + 1;
  }
  return counts;
}

Future<TenantAdminMutationResult> setTenantCompanyActive({
  required DocumentReference companyRef,
  required bool isActive,
}) async {
  if (!isSuperAdminRole(currentViewerRole())) {
    return const TenantAdminMutationResult(
      success: false,
      errorMessage: 'Only super admins can change tenant status.',
    );
  }

  try {
    await companyRef.update({'is_active': isActive});
    return const TenantAdminMutationResult(success: true);
  } catch (error) {
    return TenantAdminMutationResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}

/// Blocks login when a staff user's company has been deactivated.
Future<String?> inactiveCompanyLoginBlockMessage(UsersRecord profile) async {
  if (isSuperAdminRole(profile.role)) {
    return null;
  }
  if (profile.companyRef == null) {
    return null;
  }
  final companyRef = canonicalCompanyRef(profile.companyRef);
  try {
    final company = await CompaniesRecord.getDocumentOnce(companyRef);
    if (!company.isActive) {
      return 'This company account has been deactivated. '
          'Contact EmberSoulLabs support.';
    }
  } catch (_) {
    // Offline or rules — allow post-login flow to surface other errors.
  }
  return null;
}
