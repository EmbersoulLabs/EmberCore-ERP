import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';
import 'package:tfg_vday/backend/schema/shopify_reviews_record.dart';
import 'package:tfg_vday/backend/shopify_order_identity_helpers.dart';
import 'package:tfg_vday/backend/shopify_pending_orders_helpers.dart';

import 'firebase_test_setup.dart';

ShopifyReviewsRecord _review({
  required String id,
  String status = ShopifyReviewStatus.pendingReview,
  String companyId = 'companyA',
}) {
  return ShopifyReviewsRecord.getDocumentFromData(
    {
      'source': 'shopify',
      'reviewStatus': status,
      'companyId': companyId,
    },
    FirebaseFirestore.instance.collection('shopify_reviews').doc(id),
  );
}

OrdersRecord _order({
  required String id,
  Map<String, dynamic> data = const {},
}) {
  return OrdersRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('badge count', () {
    test('BADGE-01 0 PENDING_REVIEW hides badge', () {
      expect(countShopifyReviewsAwaitingApproval(const []), 0);
      expect(shopifyReviewPendingBadgeLabel(0), isNull);
    });

    test('BADGE-02 1 PENDING_REVIEW shows 1', () {
      final reviews = [_review(id: 'p1')];
      expect(countShopifyReviewsAwaitingApproval(reviews), 1);
      expect(shopifyReviewPendingBadgeLabel(1), '1');
    });

    test('BADGE-03 multiple PENDING_REVIEW', () {
      final reviews = [_review(id: 'p1'), _review(id: 'p2')];
      expect(countShopifyReviewsAwaitingApproval(reviews), 2);
      expect(shopifyReviewPendingBadgeLabel(2), '2');
      expect(shopifyReviewPendingBadgeLabel(10), '10');
    });

    test('BADGE-04 APPROVED excluded', () {
      final reviews = [
        _review(id: 'p1'),
        _review(id: 'a1', status: ShopifyReviewStatus.approved),
      ];
      expect(countShopifyReviewsAwaitingApproval(reviews), 1);
    });

    test('BADGE-05 QUARANTINED retained but excluded from badge', () {
      final reviews = [
        _review(id: 'p1'),
        _review(id: 'q1', status: ShopifyReviewStatus.quarantined),
      ];
      expect(reviews[1].reviewStatus, ShopifyReviewStatus.quarantined);
      expect(countShopifyReviewsAwaitingApproval(reviews), 1);
    });

    test('BADGE-06 REJECTED and CLOSED excluded', () {
      final reviews = [
        _review(id: 'p1'),
        _review(id: 'r1', status: ShopifyReviewStatus.rejected),
        _review(id: 'c1', status: 'CLOSED'),
      ];
      expect(countShopifyReviewsAwaitingApproval(reviews), 1);
    });

    test('BADGE-07 another company PENDING_REVIEW excluded', () {
      final reviews = [
        _review(id: 'a1', companyId: 'companyA'),
        _review(id: 'b1', companyId: 'companyB'),
      ];
      expect(
        countShopifyReviewsAwaitingApproval(reviews, companyId: 'companyA'),
        1,
      );
    });

    test('BADGE-08 approval decreases pending count', () {
      final before = [
        _review(id: 'p1'),
        _review(id: 'p2'),
      ];
      final after = [
        _review(id: 'p1', status: ShopifyReviewStatus.approved),
        _review(id: 'p2'),
      ];
      expect(countShopifyReviewsAwaitingApproval(before), 2);
      expect(countShopifyReviewsAwaitingApproval(after), 1);
    });

    test('BADGE-09 last approval hides badge', () {
      final after = [
        _review(id: 'p1', status: ShopifyReviewStatus.approved),
        _review(id: 'p2', status: ShopifyReviewStatus.approved),
      ];
      expect(countShopifyReviewsAwaitingApproval(after), 0);
      expect(
        shopifyReviewPendingBadgeLabel(
          countShopifyReviewsAwaitingApproval(after),
        ),
        isNull,
      );
    });
  });

  group('display identity', () {
    test('DISPLAY-01 shopifyOrderName #1340', () {
      final order = _order(
        id: '1',
        data: {
          'Order_Id': 'TFG-AUG26-0106',
          'source': 'shopify',
          'shopifyOrderName': '#1340',
        },
      );
      expect(resolveShopifyDisplayOrderName(order), '#1340');
      expect(order.orderId, 'TFG-AUG26-0106');
    });

    test('DISPLAY-02 shopifyOrderNumber without stronger name', () {
      final order = _order(
        id: '2',
        data: {
          'Order_Id': 'TFG-AUG26-0106',
          'source': 'shopify',
          'shopifyOrderNumber': 1340,
        },
      );
      expect(resolveShopifyDisplayOrderName(order), '#1340');
    });

    test('DISPLAY-03 legacy externalOrderName', () {
      final order = _order(
        id: '3',
        data: {
          'source': 'shopify',
          'externalOrderName': '#1339',
        },
      );
      expect(resolveShopifyDisplayOrderName(order), '#1339');
    });

    test('DISPLAY-04 non-Shopify order has no display metadata', () {
      final order = _order(
        id: '4',
        data: {
          'Order_Id': 'TFG-AUG26-0001',
          'client_name': 'Alice',
        },
      );
      expect(resolveShopifyDisplayOrderName(order), isNull);
      expect(isOfficialShopifyOrder(order), isFalse);
    });

    test('DISPLAY-05 no trustworthy human-readable identity', () {
      final order = _order(
        id: '5',
        data: {
          'source': 'shopify',
          'shopifyOrderId': '820982911946154500',
          'externalOrderId': '820982911946154500',
        },
      );
      expect(resolveShopifyDisplayOrderName(order), isNull);
    });

    test('DISPLAY-06 long internal id is not the staff-facing reference', () {
      final order = _order(
        id: '6',
        data: {
          'source': 'shopify',
          'shopifyOrderName': '820982911946154500',
          'shopifyOrderId': '820982911946154500',
          'externalOrderName': '820982911946154500',
        },
      );
      expect(resolveShopifyDisplayOrderName(order), isNull);
    });

    test('DISPLAY-07 ERP Order_Id remains unchanged', () {
      final order = _order(
        id: '7',
        data: {
          'Order_Id': 'TFG-AUG26-0106',
          'source': 'shopify',
          'shopifyOrderName': '#1340',
        },
      );
      expect(order.orderId, 'TFG-AUG26-0106');
      expect(resolveShopifyDisplayOrderName(order), isNot(order.orderId));
    });

    test('DETAIL source Shopify uses human-readable number not payload id', () {
      final order = _order(
        id: 'd1',
        data: {
          'Order_Id': 'TFG-AUG26-0106',
          'source': 'shopify',
          'shopifyOrderName': '#1340',
          'shopifyOrderId': '820982911946154500',
        },
      );
      expect(order.orderId, 'TFG-AUG26-0106');
      expect(order.source, 'shopify');
      expect(resolveShopifyDisplayOrderName(order), '#1340');
      expect(resolveShopifyDisplayOrderName(order), isNot(order.shopifyOrderId));
    });

    test('DETAIL non-Shopify hides Shopify Order field', () {
      final order = _order(
        id: 'd2',
        data: {'Order_Id': 'TFG-AUG26-0001'},
      );
      expect(resolveShopifyDisplayOrderName(order), isNull);
    });
  });
}
