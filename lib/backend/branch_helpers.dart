import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/companies_record.dart';
import '/backend/subscription_helpers.dart';
import '/auth/role_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';

/// Tenant org role: standalone (legacy), headquarters, or branch.
enum CompanyKind {
  hq,
  branch,
  standalone,
}

CompanyKind parseCompanyKind(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'hq':
      return CompanyKind.hq;
    case 'branch':
      return CompanyKind.branch;
    default:
      return CompanyKind.standalone;
  }
}

String companyKindKey(CompanyKind kind) {
  switch (kind) {
    case CompanyKind.hq:
      return 'hq';
    case CompanyKind.branch:
      return 'branch';
    case CompanyKind.standalone:
      return '';
  }
}

bool isBusinessPlanTier(CompaniesRecord company) {
  return company.planTier.trim().toLowerCase() == 'business';
}

/// Org id for grouping HQ + branches. Falls back to company doc id.
String orgIdForCompany(CompaniesRecord company) {
  if (company.orgId.isNotEmpty) {
    return company.orgId;
  }
  if (company.companyKind == 'branch' &&
      company.hasParentOrgRef()) {
    return company.parentOrgRef!.id;
  }
  return company.reference.id;
}

DocumentReference? headquartersRefForCompany(CompaniesRecord company) {
  if (company.companyKind == 'branch' && company.hasParentOrgRef()) {
    return company.parentOrgRef;
  }
  if (company.companyKind == 'hq' ||
      parseCompanyKind(company.companyKind) == CompanyKind.standalone) {
    return company.reference;
  }
  return company.reference;
}

Future<CompaniesRecord> resolveBillingCompany(CompaniesRecord company) async {
  final hqRef = headquartersRefForCompany(company);
  if (hqRef == null || hqRef.path == company.reference.path) {
    return company;
  }
  return CompaniesRecord.getDocumentOnce(hqRef);
}

bool canManageOrgBranches({
  required UserRole? role,
  required CompaniesRecord? activeCompany,
}) {
  if (isSuperAdminRole(role)) {
    return true;
  }
  if (!canManageBilling(role)) {
    return false;
  }
  if (activeCompany == null) {
    return false;
  }
  if (activeCompany.companyKind == 'branch') {
    return false;
  }
  return isBusinessPlanTier(activeCompany);
}

String? branchPlanBlockMessage(CompaniesRecord company) {
  if (isBusinessPlanTier(company)) {
    return null;
  }
  return 'branch.plan.businessRequired';
}

Query branchesQueryForOrg(String orgId) {
  return CompaniesRecord.collection
      .where('org_id', isEqualTo: orgId)
      .where('company_kind', isEqualTo: 'branch')
      .where('is_active', isEqualTo: true);
}

Future<int> countOrgBranches(String orgId) async {
  final snap = await branchesQueryForOrg(orgId).count().get();
  return snap.count ?? 0;
}

/// Subscription write check: branches inherit HQ billing status.
Future<bool> isOrgSubscriptionWriteAllowed(CompaniesRecord company) async {
  final billing = await resolveBillingCompany(company);
  return isSubscriptionWriteAllowed(billing);
}

Future<String?> orgIdForUserProfile(UsersRecord? profile) async {
  if (profile?.companyRef == null) {
    return null;
  }
  try {
    final company =
        await CompaniesRecord.getDocumentOnce(profile!.companyRef!);
    if (!isBusinessPlanTier(company)) {
      return null;
    }
    return orgIdForCompany(company);
  } catch (_) {
    return null;
  }
}

Future<String?> orgSubscriptionWriteBlockMessage(
  CompaniesRecord company,
) async {
  final billing = await resolveBillingCompany(company);
  return subscriptionWriteBlockMessage(billing);
}
