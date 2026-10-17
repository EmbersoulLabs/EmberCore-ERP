/// Display catalog for the billing page.
/// The server quote in saas_pricing_v1.js is authoritative.
/// This map must use the same minor-unit amounts.

const Map<String, Map<String, int>> billingMonthlyMinor = {
  'MY': {'starter': 6900, 'pro': 19900, 'business': 39900},
  'SG': {'starter': 2900, 'pro': 7900, 'business': 15900},
};

const Map<String, Map<String, int>> billingAnnualMinor = {
  'MY': {'starter': 69000, 'pro': 199000, 'business': 399000},
  'SG': {'starter': 29000, 'pro': 79000, 'business': 159000},
};

String normalizeBillingCountry(String? value) {
  final raw = value?.trim().toUpperCase() ?? '';
  if (raw == 'MALAYSIA') {
    return 'MY';
  }
  if (raw == 'SINGAPORE') {
    return 'SG';
  }
  return raw;
}

String normalizeBillingInterval(String? value) {
  final raw = value?.trim().toLowerCase() ?? '';
  return raw == 'year' || raw == 'yearly' || raw == 'annual' ? 'year' : 'month';
}

int? billingListPriceMinor({
  required String? country,
  required String plan,
  required String interval,
}) {
  final code = normalizeBillingCountry(country);
  final tier = plan.trim().toLowerCase();
  final period = normalizeBillingInterval(interval);
  final table = period == 'year' ? billingAnnualMinor : billingMonthlyMinor;
  return table[code]?[tier];
}

String billingCurrencyCode(String? country) {
  return normalizeBillingCountry(country) == 'SG' ? 'SGD' : 'MYR';
}

String formatBillingPrice({
  required String? country,
  required String plan,
  required String interval,
}) {
  final amount = billingListPriceMinor(
    country: country,
    plan: plan,
    interval: interval,
  );
  if (amount == null) {
    return '—';
  }
  final period = normalizeBillingInterval(interval) == 'year' ? 'year' : 'month';
  return '${billingCurrencyCode(country)} ${amount ~/ 100} / $period';
}
