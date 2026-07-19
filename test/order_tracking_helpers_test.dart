import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_tracking_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order(Map<String, dynamic> data) {
  return OrdersRecord.getDocumentFromData(
    data,
    OrdersRecord.collection.doc('test-order'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('maskRecipientName', () {
    test('keeps first three characters of first word', () {
      expect(maskRecipientName('Ali Hassan'), 'Ali***');
      expect(maskRecipientName('Jo'), 'Jo***');
      expect(maskRecipientName(''), '');
      expect(maskRecipientName(null), '');
    });
  });

  group('shouldAutoSendTrackingLink', () {
    test('delivery sends on out_of_delivery only', () {
      final delivery = _order({'pickup_delivery': 'Delivery'});
      expect(
        shouldAutoSendTrackingLink(delivery, OrderStatus.out_of_delivery),
        isTrue,
      );
      expect(
        shouldAutoSendTrackingLink(delivery, OrderStatus.ready_to_delivery),
        isFalse,
      );
    });

    test('pickup sends on ready_to_delivery only', () {
      final pickup = _order({'pickup_delivery': 'Pick Up'});
      expect(
        shouldAutoSendTrackingLink(pickup, OrderStatus.ready_to_delivery),
        isTrue,
      );
      expect(
        shouldAutoSendTrackingLink(pickup, OrderStatus.out_of_delivery),
        isFalse,
      );
    });

    test('retail is never trackable', () {
      final retail = _order({'orderType': 'Retail'});
      expect(
        shouldAutoSendTrackingLink(retail, OrderStatus.out_of_delivery),
        isFalse,
      );
      expect(isTrackableCustomerOrder(retail), isFalse);
    });
  });

  group('phonesMatchLast4', () {
    test('compares last four digits', () {
      expect(phonesMatchLast4('+65 9123 4567', '4567'), isTrue);
      expect(phonesMatchLast4('91234567', '1234'), isFalse);
      expect(phoneLast4Digits('+65 9123 4567'), '4567');
    });
  });
}
