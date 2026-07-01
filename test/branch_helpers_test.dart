import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/backend/branch_helpers.dart';
import 'package:tfg_vday/backend/schema/companies_record.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

import 'firebase_test_setup.dart';

CompaniesRecord _company({
  required String id,
  String planTier = 'starter',
  String companyKind = '',
  String orgId = '',
}) {
  final ref = CompaniesRecord.collection.doc(id);
  return CompaniesRecord.getDocumentFromData(
    createCompaniesRecordData(
      companyId: id,
      companyName: 'Test Co',
      planTier: planTier,
      companyKind: companyKind,
      orgId: orgId,
      isActive: true,
    ),
    ref,
  );
}

void main() {
  setUpAll(() async {
    await setupFirebaseForTests();
  });

  group('isBusinessPlanTier', () {
    test('true for business', () {
      expect(isBusinessPlanTier(_company(id: 'a', planTier: 'business')), isTrue);
    });
    test('false for starter', () {
      expect(isBusinessPlanTier(_company(id: 'b', planTier: 'starter')), isFalse);
    });
  });

  group('orgIdForCompany', () {
    test('uses org_id when set', () {
      final c = _company(id: 'hq1', orgId: 'org-hq');
      expect(orgIdForCompany(c), 'org-hq');
    });
    test('falls back to doc id for standalone', () {
      final c = _company(id: 'solo1');
      expect(orgIdForCompany(c), 'solo1');
    });
  });

  group('canManageOrgBranches', () {
    test('superadmin always allowed', () {
      expect(
        canManageOrgBranches(
          role: UserRole.superadmin,
          activeCompany: _company(id: 'x', planTier: 'starter'),
        ),
        isTrue,
      );
    });
    test('director on business HQ allowed', () {
      expect(
        canManageOrgBranches(
          role: UserRole.director,
          activeCompany: _company(id: 'hq', planTier: 'business', companyKind: 'hq'),
        ),
        isTrue,
      );
    });
    test('director on starter blocked by plan', () {
      expect(
        canManageOrgBranches(
          role: UserRole.director,
          activeCompany: _company(id: 'hq', planTier: 'starter'),
        ),
        isFalse,
      );
    });
    test('branch company cannot manage branches', () {
      expect(
        canManageOrgBranches(
          role: UserRole.director,
          activeCompany: _company(
            id: 'br',
            planTier: 'business',
            companyKind: 'branch',
          ),
        ),
        isFalse,
      );
    });
  });
}
