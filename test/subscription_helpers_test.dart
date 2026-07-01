import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/companies_record.dart';
import 'package:tfg_vday/backend/subscription_helpers.dart';

import 'firebase_test_setup.dart';

CompaniesRecord _company({
  bool isActive = true,
  String subscriptionStatus = '',
  DateTime? trialEndsAt,
}) {
  return CompaniesRecord.getDocumentFromData(
    {
      'Company_id': 'c1',
      'Company_name': 'Test Co',
      'is_active': isActive,
      if (subscriptionStatus.isNotEmpty)
        'subscription_status': subscriptionStatus,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt,
    },
    FirebaseFirestore.instance.collection('Companies').doc('c1'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);
  test('legacy company without subscription fields allows writes', () {
    expect(isSubscriptionWriteAllowed(_company()), isTrue);
    expect(subscriptionWriteBlockMessage(_company()), isNull);
  });

  test('active subscription allows writes', () {
    final company = _company(subscriptionStatus: 'active');
    expect(isSubscriptionWriteAllowed(company), isTrue);
  });

  test('trialing before trial end allows writes', () {
    final company = _company(
      subscriptionStatus: 'trialing',
      trialEndsAt: DateTime.now().add(const Duration(days: 3)),
    );
    expect(isSubscriptionWriteAllowed(company), isTrue);
  });

  test('expired trial blocks writes', () {
    final company = _company(
      subscriptionStatus: 'trialing',
      trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(isSubscriptionWriteAllowed(company), isFalse);
    expect(
      subscriptionWriteBlockMessage(company),
      contains('Free trial ended'),
    );
  });

  test('past_due blocks writes', () {
    final company = _company(subscriptionStatus: 'past_due');
    expect(isSubscriptionWriteAllowed(company), isFalse);
    expect(
      subscriptionWriteBlockMessage(company),
      contains('payment is overdue'),
    );
  });

  test('inactive company blocks writes', () {
    final company = _company(isActive: false, subscriptionStatus: 'active');
    expect(isSubscriptionWriteAllowed(company), isFalse);
  });
}
