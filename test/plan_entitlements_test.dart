import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/platform/plan_entitlements.dart';
import 'package:tfg_vday/platform/platform_module.dart';

void main() {
  test('starter, pro, business and trial modules follow the contract', () {
    expect(
      planAllowsModule(
        subscriptionStatus: 'active',
        planTier: 'starter',
        module: PlatformModule.orders,
      ),
      isTrue,
    );
    expect(
      planAllowsModule(
        subscriptionStatus: 'active',
        planTier: 'starter',
        module: PlatformModule.whatsappImport,
      ),
      isFalse,
    );
    expect(
      planAllowsModule(
        subscriptionStatus: 'active',
        planTier: 'pro',
        module: PlatformModule.shopifyImport,
      ),
      isTrue,
    );
    expect(
      planAllowsModule(
        subscriptionStatus: 'active',
        planTier: 'business',
        module: PlatformModule.customerBroadcast,
      ),
      isTrue,
    );
    expect(
      planAllowsModule(
        subscriptionStatus: 'trialing',
        planTier: 'pro',
        module: PlatformModule.materialsBom,
      ),
      isTrue,
    );
    expect(paidOrdersPerMonth['pro'], 3000);
    expect(
      planAllowsModule(
        subscriptionStatus: 'trialing',
        planTier: 'pro',
        module: PlatformModule.orders,
      ),
      isTrue,
    );
  });

  test('appointments stay off and legacy tenants stay unrestricted', () {
    expect(
      planAllowsModule(
        subscriptionStatus: 'active',
        planTier: 'business',
        module: PlatformModule.appointments,
      ),
      isFalse,
    );
    expect(
      planAllowsModule(
        subscriptionStatus: '',
        planTier: '',
        module: PlatformModule.shopifyImport,
      ),
      isTrue,
    );
  });

  test('audit log and broadcast quotas follow the plan', () {
    expect(
      planAllowsAuditLog(subscriptionStatus: 'active', planTier: 'starter'),
      isFalse,
    );
    expect(
      planAllowsAuditLog(subscriptionStatus: 'trialing', planTier: 'pro'),
      isTrue,
    );
    expect(
      planAllowsAuditLog(subscriptionStatus: null, planTier: null),
      isTrue,
    );
    expect(
      broadcastMonthlyRecipientLimit(
        subscriptionStatus: 'active',
        planTier: 'starter',
        superAdmin: false,
      ),
      0,
    );
    expect(
      broadcastMonthlyRecipientLimit(
        subscriptionStatus: 'active',
        planTier: 'pro',
        superAdmin: false,
      ),
      2000,
    );
    expect(
      broadcastMonthlyRecipientLimit(
        subscriptionStatus: 'active',
        planTier: 'business',
        superAdmin: false,
      ),
      10000,
    );
    expect(
      broadcastMonthlyRecipientLimit(
        subscriptionStatus: 'trialing',
        planTier: 'pro',
        superAdmin: false,
      ),
      2000,
    );
    expect(
      broadcastMonthlyRecipientLimit(
        subscriptionStatus: 'active',
        planTier: 'starter',
        superAdmin: true,
      ),
      isNull,
    );
    expect(paidStaffSeats['starter'], 2);
    expect(paidStaffSeats['business'], 30);
  });
}
