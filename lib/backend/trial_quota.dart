import 'package:cloud_firestore/cloud_firestore.dart';

/// True only for a provisioned SaaS trial. Legacy companies have no status.
bool trialQuotaApplies(Map<String, dynamic>? company) {
  if (company == null) {
    return false;
  }
  return company['subscription_status'] == 'trialing' &&
      company['pricing_version'] == 'v1';
}

/// Trial and active paid v1 companies share the lifetime staff-seat counter.
/// Paid monthly order caps are not applied through this counter.
bool staffSeatQuotaApplies(Map<String, dynamic>? company) {
  if (company == null || company['pricing_version'] != 'v1') {
    return false;
  }
  final status = company['subscription_status'];
  return status == 'trialing' || status == 'active';
}

/// Next slot, or null when the configured maximum is already used.
int? nextTrialSlot({required int consumed, required int max}) {
  final next = consumed + 1;
  if (next > max) {
    return null;
  }
  return next;
}

class TrialQuotaException implements Exception {
  const TrialQuotaException(this.message);

  final String message;

  @override
  String toString() => message;
}

String trialOrderLimitMessage(int max) =>
    'Trial limit reached: this trial allows $max orders. '
    'You can still update and complete existing orders.';

String trialStaffLimitMessage(int max) =>
    'Trial limit reached: this trial allows $max staff accounts.';

String staffSeatLimitMessage(int max, {required bool trial}) => trial
    ? trialStaffLimitMessage(max)
    : 'Staff limit reached: this plan allows $max staff accounts. '
        'Upgrade to add more.';

/// Null when another staff profile is allowed. Does not consume a slot.
Future<String?> trialStaffLimitMessageIfFull(String companyId) async {
  final db = FirebaseFirestore.instance;
  final companySnap = await db.collection('Companies').doc(companyId).get();
  final company = companySnap.data();
  if (!staffSeatQuotaApplies(company)) {
    return null;
  }
  final quotaSnap = await db.collection('trial_quota').doc(companyId).get();
  final consumed =
      (quotaSnap.data()?['staff_consumed'] as num?)?.toInt() ?? 0;
  final max = (company?['max_staff_seats'] as num?)?.toInt() ?? 3;
  if (nextTrialSlot(consumed: consumed, max: max) == null) {
    return staffSeatLimitMessage(
      max,
      trial: company?['subscription_status'] == 'trialing',
    );
  }
  return null;
}

/// Creates an order. Trial tenants also claim the next order slot.
Future<void> commitOrderCreate({
  required DocumentReference orderRef,
  required Map<String, dynamic> orderData,
  required String companyId,
}) {
  return _commitCreate(
    companyId: companyId,
    kind: 'orders',
    recordRef: orderRef,
    recordData: orderData,
  );
}

/// Creates a staff profile. Trial tenants also claim the next staff slot.
Future<void> commitStaffCreate({
  required DocumentReference userRef,
  required Map<String, dynamic> userData,
  required String companyId,
}) {
  return _commitCreate(
    companyId: companyId,
    kind: 'staff',
    recordRef: userRef,
    recordData: userData,
  );
}

Future<void> _commitCreate({
  required String companyId,
  required String kind,
  required DocumentReference recordRef,
  required Map<String, dynamic> recordData,
}) async {
  final db = FirebaseFirestore.instance;
  final companyRef = db.collection('Companies').doc(companyId);
  final quotaRef = db.collection('trial_quota').doc(companyId);
  final orders = kind == 'orders';

  await db.runTransaction((transaction) async {
    final companySnap = await transaction.get(companyRef);
    final company = companySnap.data();
    final enforced = orders
        ? trialQuotaApplies(company)
        : staffSeatQuotaApplies(company);
    if (!enforced) {
      transaction.set(recordRef, recordData);
      return;
    }

    final quotaSnap = await transaction.get(quotaRef);
    if (!quotaSnap.exists) {
      throw TrialQuotaException(
        'Trial quota is not initialized for this company.',
      );
    }
    final quota = quotaSnap.data() ?? {};
    final consumed = orders
        ? (quota['orders_consumed'] as num?)?.toInt() ?? 0
        : (quota['staff_consumed'] as num?)?.toInt() ?? 0;
    final max = orders
        ? (company?['max_orders_per_month'] as num?)?.toInt() ?? 100
        : (company?['max_staff_seats'] as num?)?.toInt() ?? 3;
    final slot = nextTrialSlot(consumed: consumed, max: max);
    if (slot == null) {
      throw TrialQuotaException(
        orders
            ? trialOrderLimitMessage(max)
            : staffSeatLimitMessage(
                max,
                trial: company?['subscription_status'] == 'trialing',
              ),
      );
    }

    final slotCollection =
        orders ? 'trial_order_slots' : 'trial_staff_slots';
    final slotRef = db
        .collection(slotCollection)
        .doc(companyId)
        .collection('slots')
        .doc('$slot');
    transaction.set(recordRef, {
      ...recordData,
      'trial_slot': '$slot',
      if (orders) 'companyRef': companyRef,
      if (!orders) 'trial_enforced': true,
    });
    transaction.set(slotRef, {
      if (orders) 'order_id': recordRef.id,
      if (!orders) 'user_id': recordRef.id,
    });
    transaction.update(quotaRef, {
      if (orders) 'orders_consumed': slot,
      if (!orders) 'staff_consumed': slot,
    });
  });
}
