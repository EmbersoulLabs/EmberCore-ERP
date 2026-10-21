import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/monthly_usage.dart';

void main() {
  test('billing period wins until it ends', () {
    final end = DateTime.utc(2026, 11, 17);
    expect(
      usagePeriodId(
        nowUtc: DateTime.utc(2026, 10, 17),
        storedPeriodId: 'bill-1',
        periodEnd: end,
      ),
      'bill-1',
    );
    expect(
      usagePeriodId(
        nowUtc: DateTime.utc(2026, 11, 17),
        storedPeriodId: 'bill-1',
        periodEnd: end,
      ),
      '2026-11',
    );
    expect(
      usagePeriodId(nowUtc: DateTime.utc(2026, 10, 1)),
      '2026-10',
    );
  });

  test('remaining usage never goes below zero', () {
    expect(remainingAllowance(500, 499), 1);
    expect(remainingAllowance(500, 500), 0);
    expect(remainingAllowance(500, 640), 0);
    expect(remainingAllowance(2000, 2000), 0);
    expect(remainingAllowance(10000, 9999), 1);
  });
}
