import '/platform/platform_module.dart';

/// Display mirror of firebase/functions/plan_entitlements.js.
/// Server writes and security rules remain authoritative.

const starterPlanModules = <PlatformModule>[
  PlatformModule.orders,
  PlatformModule.pos,
  PlatformModule.customers,
  PlatformModule.products,
  PlatformModule.drivers,
  PlatformModule.fieldService,
  PlatformModule.invoices,
  PlatformModule.reports,
];

const proPlanModules = <PlatformModule>[
  ...starterPlanModules,
  PlatformModule.whatsappImport,
  PlatformModule.shopifyImport,
  PlatformModule.materialsBom,
  PlatformModule.productionMenu,
  PlatformModule.customerBroadcast,
];

const paidStaffSeats = <String, int>{
  'starter': 2,
  'pro': 10,
  'business': 30,
};

const paidOrdersPerMonth = <String, int>{
  'starter': 500,
  'pro': 3000,
  'business': 10000,
};

const broadcastQuotaMonthly = <String, int>{
  'starter': 0,
  'pro': 2000,
  'business': 10000,
};

const trialBroadcastQuotaMonthly = 2000;

String? _status(String? subscriptionStatus) =>
    subscriptionStatus?.trim().isEmpty ?? true ? null : subscriptionStatus!.trim();

String modulePlanFor({
  String? subscriptionStatus,
  String? planTier,
}) {
  final status = _status(subscriptionStatus);
  if (status == null) {
    return '';
  }
  if (status == 'trialing') {
    return 'pro';
  }
  final tier = planTier?.trim().toLowerCase() ?? '';
  if (tier == 'pro' || tier == 'business' || tier == 'starter') {
    return tier;
  }
  return 'starter';
}

bool planAllowsModule({
  required String? subscriptionStatus,
  required String? planTier,
  required PlatformModule module,
}) {
  if (module == PlatformModule.appointments) {
    return false;
  }
  final plan = modulePlanFor(
    subscriptionStatus: subscriptionStatus,
    planTier: planTier,
  );
  if (plan.isEmpty) {
    return true;
  }
  final modules = plan == 'starter' ? starterPlanModules : proPlanModules;
  return modules.contains(module);
}

bool planAllowsAuditLog({
  required String? subscriptionStatus,
  required String? planTier,
}) {
  final plan = modulePlanFor(
    subscriptionStatus: subscriptionStatus,
    planTier: planTier,
  );
  return plan.isEmpty || plan == 'pro' || plan == 'business';
}

/// Null means the caller is not capped (legacy tenant or Super Admin).
int? broadcastMonthlyRecipientLimit({
  required String? subscriptionStatus,
  required String? planTier,
  required bool superAdmin,
}) {
  if (superAdmin) {
    return null;
  }
  final plan = modulePlanFor(
    subscriptionStatus: subscriptionStatus,
    planTier: planTier,
  );
  if (plan.isEmpty) {
    return null;
  }
  if (_status(subscriptionStatus) == 'trialing') {
    return trialBroadcastQuotaMonthly;
  }
  return broadcastQuotaMonthly[plan] ?? 0;
}

String planUpgradeMessage(PlatformModule module) {
  switch (module) {
    case PlatformModule.whatsappImport:
      return 'WhatsApp order import is not included in the current plan. '
          'Upgrade to Pro to use it.';
    case PlatformModule.shopifyImport:
      return 'Shopify import is not included in the current plan. '
          'Upgrade to Pro to use it.';
    case PlatformModule.customerBroadcast:
      return 'Customer broadcast is not included in the current plan. '
          'Upgrade to Pro to use it.';
    case PlatformModule.materialsBom:
    case PlatformModule.productionMenu:
      return 'This production feature is not included in the current plan. '
          'Upgrade to Pro to use it.';
    case PlatformModule.appointments:
      return 'Appointments are not available yet.';
    default:
      return 'This feature is not included in the current plan.';
  }
}
