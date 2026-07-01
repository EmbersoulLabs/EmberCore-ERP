import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions region for Stripe billing callables.
const stripeBillingFunctionsRegion = 'asia-southeast1';

class StripeCheckoutResult {
  const StripeCheckoutResult({required this.url, this.sessionId});

  final String url;
  final String? sessionId;
}

class StripePortalResult {
  const StripePortalResult({required this.url});

  final String url;
}

Future<StripeCheckoutResult> createStripeCheckoutSession({
  required String companyId,
  required String planTier,
  String interval = 'month',
}) async {
  final callable = FirebaseFunctions.instanceFor(region: stripeBillingFunctionsRegion)
      .httpsCallable('createCheckoutSession');
  final response = await callable.call<Map<String, dynamic>>({
    'companyId': companyId,
    'planTier': planTier,
    'interval': interval,
  });
  final data = Map<String, dynamic>.from(response.data);
  final url = data['url']?.toString() ?? '';
  if (url.isEmpty) {
    throw Exception('Checkout URL missing from server response.');
  }
  return StripeCheckoutResult(
    url: url,
    sessionId: data['sessionId']?.toString(),
  );
}

Future<StripePortalResult> createStripePortalSession({
  required String companyId,
}) async {
  final callable = FirebaseFunctions.instanceFor(region: stripeBillingFunctionsRegion)
      .httpsCallable('createPortalSession');
  final response = await callable.call<Map<String, dynamic>>({
    'companyId': companyId,
  });
  final data = Map<String, dynamic>.from(response.data);
  final url = data['url']?.toString() ?? '';
  if (url.isEmpty) {
    throw Exception('Portal URL missing from server response.');
  }
  return StripePortalResult(url: url);
}

String describeStripeCallableError(Object error) {
  if (error is FirebaseFunctionsException) {
    return error.message ?? error.code;
  }
  return error.toString();
}
