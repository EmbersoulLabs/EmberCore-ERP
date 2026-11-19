import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_detail_copy_helpers.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  Map<String, dynamic> data = const {},
}) {
  return OrdersRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

OrderItemRecord _item({
  required String id,
  String name = 'Rose',
  int qty = 1,
}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': name,
      'qty': qty,
      'price': 10.0,
    },
    FirebaseFirestore.instance.collection('Order_item').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('copy text includes id, date, slot, address, and products', () {
    final text = buildCopyableOrderDetailText(
      order: _order(
        id: 'o1',
        data: {
          'Order_Id': 'TFG-SEP26-00418',
          'delivery_date': DateTime(2026, 9, 20),
          'delivery_time_slot': '14:00-16:00',
          'address': '31 Bangkit Road #17-03',
          'PostalCode': '679973',
        },
      ),
      items: [
        _item(id: 'a', name: 'Red rose bouquet', qty: 1),
        _item(id: 'b', name: 'Orchid pot', qty: 2),
        _item(id: 'c', name: 'Removed', qty: 0),
      ],
    );

    expect(text, contains('Order ID: TFG-SEP26-00418'));
    expect(text, contains('Date: 20/9/2026'));
    expect(text, contains('Delivery slot: 14:00-16:00'));
    expect(text, contains('Address: 31 Bangkit Road #17-03, 679973'));
    expect(text, contains('1x Red rose bouquet'));
    expect(text, contains('2x Orchid pot'));
    expect(text, isNot(contains('Removed')));
  });

  test('copy text omits pickup address', () {
    final text = buildCopyableOrderDetailText(
      order: _order(
        id: 'p1',
        data: {
          'Order_Id': 'TFG-SEP26-0002',
          'pickup_delivery': 'Pick Up',
          'address': '51 kampong bugis',
          'PostalCode': '338986',
          'delivery_time_slot': '10:00-12:00',
        },
      ),
      items: [_item(id: 'a')],
    );

    expect(text, contains('Order ID: TFG-SEP26-0002'));
    expect(text, contains('Delivery slot: 10:00-12:00'));
    expect(text, isNot(contains('Address:')));
    expect(text, isNot(contains('kampong bugis')));
    expect(text, contains('1x Rose'));
  });
}
