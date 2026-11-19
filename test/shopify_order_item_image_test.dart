import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/shopify_pending_orders_helpers.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);

  test('UI-04 Order_item image is the canonical snapshot URL', () {
    final item = OrderItemRecord.getDocumentFromData(
      {
        'name': 'Rose Box',
        'qty': 1,
        'price': 88,
        'image': 'https://cdn.shopify.com/rose.jpg',
      },
      FirebaseFirestore.instance.collection('Order_item').doc('i1'),
    );
    expect(item.image, 'https://cdn.shopify.com/rose.jpg');
    expect(item.productRef, isNull);
  });

  test('UI-05 Order_item without image stays placeholder-compatible', () {
    final item = OrderItemRecord.getDocumentFromData(
      {
        'name': 'Rose Box',
        'qty': 1,
      },
      FirebaseFirestore.instance.collection('Order_item').doc('i2'),
    );
    expect(item.image, isEmpty);
    expect(shopifyReviewLineItemImageUrl({'name': 'Rose Box'}), isNull);
  });

  test('UI-06 non-Shopify Order_item image field is unchanged', () {
    final item = OrderItemRecord.getDocumentFromData(
      {
        'name': 'Walk-in bouquet',
        'qty': 1,
        'image': 'https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg?alt=media&token=abc',
      },
      FirebaseFirestore.instance.collection('Order_item').doc('i3'),
    );
    expect(
      item.image,
      'https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg?alt=media&token=abc',
    );
  });
}
