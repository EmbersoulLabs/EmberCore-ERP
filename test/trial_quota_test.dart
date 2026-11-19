import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/trial_quota.dart';

void main() {
  test('legacy companies are not capped', () {
    expect(trialQuotaApplies(null), isFalse);
    expect(trialQuotaApplies({'Company_name': 'A'}), isFalse);
    expect(
      trialQuotaApplies({
        'subscription_status': 'trialing',
        'pricing_version': 'v1',
      }),
      isTrue,
    );
    expect(
      trialQuotaApplies({
        'subscription_status': 'active',
        'pricing_version': 'v1',
      }),
      isFalse,
    );
  });

  test('slots stop at the configured trial maximum', () {
    expect(nextTrialSlot(consumed: 2, max: 3), 3);
    expect(nextTrialSlot(consumed: 3, max: 3), isNull);
    expect(nextTrialSlot(consumed: 99, max: 100), 100);
    expect(nextTrialSlot(consumed: 100, max: 100), isNull);
  });
}
