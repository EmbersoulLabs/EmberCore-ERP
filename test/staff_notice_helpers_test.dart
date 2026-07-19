import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/staff_notices_record.dart';
import 'package:tfg_vday/backend/schema/users_record.dart';
import 'package:tfg_vday/backend/staff_notice_helpers.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);
  group('staff notice recipients', () {
    test('operations leadership and florists receive order created notices', () {
      expect(receivesOrderCreatedNotices(UserRole.admin), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.director), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.manager), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.senior_florist), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.florist), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.driver), isFalse);
      expect(receivesOrderCreatedNotices(UserRole.account), isFalse);
    });

    test('operation reminders go to all active roles except driver', () {
      expect(receivesOperationReminders(UserRole.admin), isTrue);
      expect(receivesOperationReminders(UserRole.account), isTrue);
      expect(receivesOperationReminders(UserRole.hr), isTrue);
      expect(receivesOperationReminders(UserRole.florist), isTrue);
      expect(receivesOperationReminders(UserRole.driver), isFalse);
      expect(receivesOperationReminders(null), isFalse);
    });
  });

  group('loadOrderCreatedNoticeRecipients', () {
    test('excludes users without uid field', () {
      expect(
        staffNoticeRecipientRef(
          UsersRecord.getDocumentFromData(
            {'uid': 'auth-uid-1', 'role': UserRole.florist},
            FirebaseFirestore.instance.collection('users').doc('legacy-id'),
          ),
        ).path,
        'users/auth-uid-1',
      );
    });
  });

  group('staffNoticeBody', () {
    test('formats order notice details', () {
      final notice = StaffNoticesRecord.getDocumentFromData(
        {
          'type': StaffNoticeType.orderCreated,
          'order_id': 'ORD-100',
          'delivery_date': DateTime(2026, 6, 11),
          'item_summary': '2x Rose Bouquet',
        },
        FirebaseFirestore.instance.collection('staff_notices').doc('n1'),
      );

      expect(
        staffNoticeBody(notice),
        'Order ORD-100\nDelivery 11 Jun 2026\n2x Rose Bouquet',
      );
    });

    test('uses professional tomorrow prep title and body', () {
      final notice = StaffNoticesRecord.getDocumentFromData(
        {
          'type': StaffNoticeType.tomorrowPrepReminder,
          'notice_title': "Tomorrow's Preparation",
          'message':
              '8 deliveries scheduled\n3 orders pending preparation',
          'prep_status': 'pending',
        },
        FirebaseFirestore.instance.collection('staff_notices').doc('n2'),
      );

      expect(staffNoticeTitle(notice), "Tomorrow's Preparation");
      expect(
        staffNoticeBody(notice),
        '8 deliveries scheduled\n3 orders pending preparation',
      );
      expect(staffNoticeStatusIcon(notice), '🟠');
      expect(
        staffNoticeDisplayBody(notice),
        '🟠 8 deliveries scheduled\n3 orders pending preparation',
      );
      expect(staffNoticeNavigationPayload(notice), staffNoticeNavTomorrowPrep);
    });

    test('builds tomorrow prep body from prep counts when present', () {
      final notice = StaffNoticesRecord.getDocumentFromData(
        {
          'type': StaffNoticeType.tomorrowPrepReminder,
          'message': 'stale message',
          'prep_delivery_count': 8,
          'prep_pending_count': 3,
          'nav_target': 'tomorrow_prep',
        },
        FirebaseFirestore.instance.collection('staff_notices').doc('n2b'),
      );

      expect(
        staffNoticeBody(notice),
        '8 deliveries scheduled\n3 orders pending preparation',
      );
      expect(staffNoticeNavigationPayload(notice), 'nav:tomorrow_prep');
    });

    test('uses reminder message for special procurement notices', () {
      final notice = StaffNoticesRecord.getDocumentFromData(
        {
          'type': StaffNoticeType.specialProcurementReminder,
          'message': 'Special purchase needed for order TFG-JUN26-0001',
        },
        FirebaseFirestore.instance.collection('staff_notices').doc('n3'),
      );

      expect(
        staffNoticeTitle(notice),
        'Special purchase reminder',
      );
      expect(
        staffNoticeBody(notice),
        'Special purchase needed for order TFG-JUN26-0001',
      );
    });
  });
}
