import '/backend/schema/companies_record.dart';
import '/backend/tenant_context.dart';

/// SaaS subscription status stored on [CompaniesRecord].
enum TenantSubscriptionStatus {
  trialing,
  active,
  pastDue,
  cancelled,
  unpaid,
}

TenantSubscriptionStatus? parseTenantSubscriptionStatus(String? raw) {
  switch (raw) {
    case 'trialing':
      return TenantSubscriptionStatus.trialing;
    case 'active':
      return TenantSubscriptionStatus.active;
    case 'past_due':
      return TenantSubscriptionStatus.pastDue;
    case 'cancelled':
      return TenantSubscriptionStatus.cancelled;
    case 'unpaid':
      return TenantSubscriptionStatus.unpaid;
    default:
      return null;
  }
}

String tenantSubscriptionStatusKey(TenantSubscriptionStatus status) {
  switch (status) {
    case TenantSubscriptionStatus.trialing:
      return 'trialing';
    case TenantSubscriptionStatus.active:
      return 'active';
    case TenantSubscriptionStatus.pastDue:
      return 'past_due';
    case TenantSubscriptionStatus.cancelled:
      return 'cancelled';
    case TenantSubscriptionStatus.unpaid:
      return 'unpaid';
  }
}

/// Legacy tenants without subscription fields keep full write access.
bool isSubscriptionWriteAllowed(CompaniesRecord company) {
  if (!company.isActive) {
    return false;
  }
  final raw = company.subscriptionStatus.trim();
  if (raw.isEmpty) {
    return true;
  }
  final status = parseTenantSubscriptionStatus(raw);
  switch (status) {
    case TenantSubscriptionStatus.active:
      return true;
    case TenantSubscriptionStatus.trialing:
      final trialEnds = company.trialEndsAt;
      if (trialEnds == null) {
        return true;
      }
      return trialEnds.isAfter(DateTime.now());
    case TenantSubscriptionStatus.pastDue:
    case TenantSubscriptionStatus.cancelled:
    case TenantSubscriptionStatus.unpaid:
    case null:
      return false;
  }
}

/// User-facing block message when subscription prevents writes.
String? subscriptionWriteBlockMessage(CompaniesRecord company) {
  if (isSubscriptionWriteAllowed(company)) {
    return null;
  }
  if (!company.isActive) {
    return 'This company account is inactive. Contact EmberSoulLabs support.';
  }
  final status = company.subscriptionStatus.trim();
  if (status == 'past_due' || status == 'unpaid') {
    return 'Subscription payment is overdue. Open Billing to renew and continue creating orders.';
  }
  if (status == 'cancelled') {
    return 'Subscription cancelled. Open Billing to subscribe again.';
  }
  if (status == 'trialing') {
    return 'Free trial ended. Open Billing to subscribe and continue creating orders.';
  }
  return 'Subscription inactive. Open Billing to continue.';
}

/// Display helper only. Trial pricing is written by the approval Cloud Function.
/// Do not save this map from the client.
Map<String, dynamic> defaultSubscriptionRecordData({
  String planTier = 'starter',
}) {
  final trialEnds = DateTime.now().add(const Duration(days: 14));
  return createCompaniesRecordData(
    planTier: planTier,
    subscriptionStatus: 'trialing',
    trialEndsAt: trialEnds,
    maxStaffSeats: planTier == 'pro' ? 20 : 5,
    maxOrdersPerMonth: planTier == 'pro' ? null : 500,
  );
}

String subscriptionStatusLabelKey(String? raw) {
  switch (parseTenantSubscriptionStatus(raw)) {
    case TenantSubscriptionStatus.trialing:
      return 'billing.status.trialing';
    case TenantSubscriptionStatus.active:
      return 'billing.status.active';
    case TenantSubscriptionStatus.pastDue:
      return 'billing.status.pastDue';
    case TenantSubscriptionStatus.cancelled:
      return 'billing.status.cancelled';
    case TenantSubscriptionStatus.unpaid:
      return 'billing.status.unpaid';
    case null:
      return 'billing.status.legacy';
  }
}

String planTierLabelKey(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'pro':
      return 'billing.plan.pro';
    case 'business':
      return 'billing.plan.business';
    case 'starter':
      return 'billing.plan.starter';
    default:
      return 'billing.plan.unknown';
  }
}

/// Loads active company and returns a block message when subscription disallows writes.
Future<String?> checkSubscriptionAllowsOrderWrites() async {
  final companyRef = TenantContext.instance.writeCompanyRef;
  if (companyRef == null) {
    return null;
  }
  try {
    final company = await CompaniesRecord.getDocumentOnce(companyRef);
    return subscriptionWriteBlockMessage(company);
  } catch (_) {
    return null;
  }
}
