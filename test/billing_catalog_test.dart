import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/billing_catalog.dart';

void main() {
  test('monthly and annual prices match the server contract', () {
    expect(
      billingListPriceMinor(country: 'MY', plan: 'starter', interval: 'month'),
      6900,
    );
    expect(
      billingListPriceMinor(country: 'SG', plan: 'pro', interval: 'month'),
      7900,
    );
    expect(
      billingListPriceMinor(country: 'MY', plan: 'business', interval: 'year'),
      399000,
    );
    expect(
      billingListPriceMinor(country: 'Singapore', plan: 'business', interval: 'annual'),
      159000,
    );
    expect(
      billingListPriceMinor(country: 'US', plan: 'starter', interval: 'month'),
      isNull,
    );
    expect(
      formatBillingPrice(country: 'MY', plan: 'pro', interval: 'month'),
      'MYR 199 / month',
    );
    expect(
      formatBillingPrice(country: 'SG', plan: 'starter', interval: 'year'),
      'SGD 290 / year',
    );
  });
}
