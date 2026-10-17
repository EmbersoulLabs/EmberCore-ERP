import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyUsageException implements Exception {
  const MonthlyUsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Active paid v1 subscription. Trial and legacy companies stay on their
/// existing paths.
bool paidOrderQuotaApplies(Map<String, dynamic>? company) {
  if (company == null) {
    return false;
  }
  return company['subscription_status'] == 'active' &&
      company['pricing_version'] == 'v1';
}

/// Stripe period while it is still open. Otherwise the UTC calendar month.
/// Client dates are ignored; [nowUtc] must be the device clock only as a
/// hint. Firestore rules recompute the same value from request.time.
String usagePeriodId({
  required DateTime nowUtc,
  String? storedPeriodId,
  DateTime? periodEnd,
}) {
  final id = storedPeriodId?.trim() ?? '';
  if (periodEnd != null &&
      nowUtc.isBefore(periodEnd.toUtc()) &&
      id.isNotEmpty) {
    return id;
  }
  final month = nowUtc.month.toString().padLeft(2, '0');
  return '${nowUtc.year}-${month.toString()}';
}

int remainingAllowance(int max, int used) {
  final left = max - used;
  return left < 0 ? 0 : left;
}

class BroadcastReservation {
  const BroadcastReservation({
    required this.attemptId,
    required this.count,
    required this.duplicate,
    required this.status,
  });

  final String attemptId;
  final int count;
  final bool duplicate;
  final String status;
}

/// Claims the next paid order slot. A failed transaction writes nothing.
Future<void> applyPaidOrderCreate({
  required Transaction transaction,
  required FirebaseFirestore db,
  required DocumentReference companyRef,
  required Map<String, dynamic> company,
  required DocumentReference orderRef,
  required Map<String, dynamic> orderData,
  DateTime? nowUtc,
}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final period = usagePeriodId(
    nowUtc: now,
    storedPeriodId: company['usage_period_id'] as String?,
    periodEnd: _asDate(company['current_period_end']),
  );
  final usageRef = db.collection('plan_usage').doc(companyRef.id);
  final usageSnap = await transaction.get(usageRef);
  final usage = usageSnap.data() ?? {};
  final same = usage['period_id'] == period;
  final consumed = same ? (usage['orders_consumed'] as num?)?.toInt() ?? 0 : 0;
  final broadcast =
      same ? (usage['broadcast_consumed'] as num?)?.toInt() ?? 0 : 0;
  final max = (company['max_orders_per_month'] as num?)?.toInt() ?? 0;
  final slot = consumed + 1;
  if (slot > max) {
    throw MonthlyUsageException(
      'Plan limit reached: this plan allows $max orders this period. '
      'Existing orders can still be updated.',
    );
  }
  final slotRef = db
      .collection('plan_order_slots')
      .doc(companyRef.id)
      .collection('periods')
      .doc(period)
      .collection('slots')
      .doc('$slot');
  transaction.set(orderRef, {
    ...orderData,
    'companyRef': companyRef,
    'plan_period': period,
    'plan_slot': '$slot',
  });
  transaction.set(slotRef, {'order_id': orderRef.id});
  transaction.set(usageRef, {
    'period_id': period,
    'orders_consumed': slot,
    'broadcast_consumed': same ? broadcast : 0,
  });
}

/// Reserves [count] recipients. A repeated [attemptId] does not count again.
Future<BroadcastReservation> reserveBroadcastRecipients({
  required String companyId,
  required String attemptId,
  required int count,
}) {
  final db = FirebaseFirestore.instance;
  return db.runTransaction((transaction) async {
    final companyRef = db.collection('Companies').doc(companyId);
    final companySnap = await transaction.get(companyRef);
    final company = companySnap.data() ?? {};
    if (!paidOrderQuotaApplies(company)) {
      throw MonthlyUsageException(
        'Customer broadcast is not included in the current plan.',
      );
    }
    final reservationRef =
        db.collection('broadcast_reservations').doc(attemptId);
    final existing = await transaction.get(reservationRef);
    if (existing.exists) {
      final data = existing.data() ?? {};
      if (data['company_id'] != companyId) {
        throw MonthlyUsageException('Broadcast reservation does not match.');
      }
      return BroadcastReservation(
        attemptId: attemptId,
        count: (data['count'] as num?)?.toInt() ?? count,
        duplicate: true,
        status: data['status'] as String? ?? 'reserved',
      );
    }
    final now = DateTime.now().toUtc();
    final period = usagePeriodId(
      nowUtc: now,
      storedPeriodId: company['usage_period_id'] as String?,
      periodEnd: _asDate(company['current_period_end']),
    );
    final usageRef = db.collection('plan_usage').doc(companyId);
    final usageSnap = await transaction.get(usageRef);
    final usage = usageSnap.data() ?? {};
    final same = usage['period_id'] == period;
    final orders = same ? (usage['orders_consumed'] as num?)?.toInt() ?? 0 : 0;
    final used =
        same ? (usage['broadcast_consumed'] as num?)?.toInt() ?? 0 : 0;
    final max = (company['broadcast_quota_monthly'] as num?)?.toInt() ?? 0;
    final next = used + count;
    if (count < 1 || next > max) {
      throw MonthlyUsageException(
        'Plan limit reached: this plan allows $max broadcast recipients '
        'this period.',
      );
    }
    transaction.set(usageRef, {
      'period_id': period,
      'orders_consumed': orders,
      'broadcast_consumed': next,
      'broadcast_attempt': attemptId,
    });
    transaction.set(reservationRef, {
      'company_id': companyId,
      'period_id': period,
      'count': count,
      'status': 'reserved',
    });
    return BroadcastReservation(
      attemptId: attemptId,
      count: count,
      duplicate: false,
      status: 'reserved',
    );
  });
}

/// Returns the reservation to the period counter. Only a still-reserved
/// attempt can be released. This does not mean the message was undelivered
/// by WhatsApp or email; those receipts are not visible to EmberCore.
Future<void> releaseBroadcastReservation({
  required String companyId,
  required String attemptId,
}) {
  final db = FirebaseFirestore.instance;
  return db.runTransaction((transaction) async {
    final reservationRef =
        db.collection('broadcast_reservations').doc(attemptId);
    final reservation = await transaction.get(reservationRef);
    final data = reservation.data();
    if (data == null ||
        data['company_id'] != companyId ||
        data['status'] != 'reserved') {
      return;
    }
    final count = (data['count'] as num?)?.toInt() ?? 0;
    final usageRef = db.collection('plan_usage').doc(companyId);
    final usageSnap = await transaction.get(usageRef);
    final usage = usageSnap.data() ?? {};
    if (usage['period_id'] != data['period_id']) {
      return;
    }
    final used = (usage['broadcast_consumed'] as num?)?.toInt() ?? 0;
    transaction.set(
      usageRef,
      {
        'broadcast_consumed': used - count,
        'broadcast_attempt': attemptId,
      },
      SetOptions(merge: true),
    );
    transaction.set(
      reservationRef,
      {'status': 'released'},
      SetOptions(merge: true),
    );
  });
}

Future<void> markBroadcastReservationOpened({
  required String companyId,
  required String attemptId,
}) {
  final db = FirebaseFirestore.instance;
  return db.runTransaction((transaction) async {
    final reservationRef =
        db.collection('broadcast_reservations').doc(attemptId);
    final reservation = await transaction.get(reservationRef);
    final data = reservation.data();
    if (data == null ||
        data['company_id'] != companyId ||
        data['status'] != 'reserved') {
      return;
    }
    transaction.set(
      reservationRef,
      {'status': 'opened'},
      SetOptions(merge: true),
    );
  });
}

DateTime? _asDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}
