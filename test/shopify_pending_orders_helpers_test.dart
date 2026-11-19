import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/shopify_reviews_record.dart';
import 'package:tfg_vday/backend/shopify_pending_orders_helpers.dart';
import 'package:tfg_vday/backend/shopify_review_approval_api.dart';

import 'firebase_test_setup.dart';

ShopifyReviewsRecord _review({
  required String id,
  String status = ShopifyReviewStatus.pendingReview,
  String shopifyOrderName = '',
  String shopifyOrderId = '',
  String customerName = '',
  DateTime? receivedAt,
}) {
  return ShopifyReviewsRecord.getDocumentFromData(
    {
      'source': 'shopify',
      'reviewStatus': status,
      if (shopifyOrderName.isNotEmpty) 'shopifyOrderName': shopifyOrderName,
      if (shopifyOrderId.isNotEmpty) 'shopifyOrderId': shopifyOrderId,
      if (customerName.isNotEmpty) 'customerName': customerName,
      if (receivedAt != null) 'receivedAt': receivedAt,
    },
    FirebaseFirestore.instance.collection('shopify_reviews').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('filterShopifyReviewsForQueue keeps pending reviews by default', () {
    final reviews = [
      _review(
        id: 's1',
        shopifyOrderName: '#1001',
        receivedAt: DateTime(2026, 8, 10, 12),
      ),
      _review(
        id: 's2',
        status: ShopifyReviewStatus.approved,
        shopifyOrderName: '#1002',
        receivedAt: DateTime(2026, 8, 10, 13),
      ),
      _review(
        id: 's3',
        status: ShopifyReviewStatus.quarantined,
        shopifyOrderName: '#1003',
        receivedAt: DateTime(2026, 8, 10, 14),
      ),
    ];

    final pending = filterShopifyReviewsForQueue(reviews);
    expect(pending.map((o) => o.reference.id), ['s3', 's1']);

    final all = filterShopifyReviewsForQueue(reviews, pendingOnly: false);
    expect(all.map((o) => o.reference.id).toList(), ['s3', 's2', 's1']);
  });

  test('filterShopifyReviewsForQueue search matches Shopify name and customer', () {
    final reviews = [
      _review(
        id: 'a',
        shopifyOrderName: '#9001',
        customerName: 'Alice Tan',
        receivedAt: DateTime(2026, 8, 1),
      ),
      _review(
        id: 'b',
        shopifyOrderName: '#9002',
        customerName: 'Bob Lee',
        receivedAt: DateTime(2026, 8, 2),
      ),
    ];

    final byShopify = filterShopifyReviewsForQueue(
      reviews,
      searchQuery: '9001',
    );
    expect(byShopify.single.reference.id, 'a');

    final byCustomer = filterShopifyReviewsForQueue(
      reviews,
      searchQuery: 'bob',
    );
    expect(byCustomer.single.reference.id, 'b');
  });

  test('shopifyReviewShopifyLabel prefers shopifyOrderName', () {
    final named = _review(id: 'a', shopifyOrderName: '#42');
    expect(shopifyReviewShopifyLabel(named), '#42');

    final byId = _review(id: 'b', shopifyOrderId: '99');
    expect(shopifyReviewShopifyLabel(byId), '#99');
  });

  test('approved rows are not selectable; quarantined rows stay actionable', () {
    expect(
      isShopifyReviewSelectable(_review(id: 'p')),
      isTrue,
    );
    expect(
      isShopifyReviewSelectable(
        _review(id: 'a', status: ShopifyReviewStatus.approved),
      ),
      isFalse,
    );
    expect(
      isShopifyReviewSelectable(
        _review(id: 'q', status: ShopifyReviewStatus.quarantined),
      ),
      isTrue,
    );
  });

  test('shopifyReviewScheduleLabel joins date and time slot', () {
    final withBoth = ShopifyReviewsRecord.getDocumentFromData(
      {
        'source': 'shopify',
        'deliveryDate': DateTime(2026, 8, 18),
        'deliveryTimeSlot': '10:00-12:00',
        'cardMessage': 'Happy Birthday',
      },
      FirebaseFirestore.instance.collection('shopify_reviews').doc('sched'),
    );
    expect(shopifyReviewDeliveryDateLabel(withBoth), '18 Aug 2026');
    expect(shopifyReviewScheduleLabel(withBoth), '18 Aug 2026 · 10:00-12:00');
  });

  test('shopifyReviewLooksPaid is true only for fully paid', () {
    final paid = ShopifyReviewsRecord.getDocumentFromData(
      {
        'source': 'shopify',
        'reviewStatus': ShopifyReviewStatus.pendingReview,
        'financialStatus': 'paid',
      },
      FirebaseFirestore.instance.collection('shopify_reviews').doc('paid'),
    );
    final voided = ShopifyReviewsRecord.getDocumentFromData(
      {
        'source': 'shopify',
        'reviewStatus': ShopifyReviewStatus.pendingReview,
        'financialStatus': 'voided',
      },
      FirebaseFirestore.instance.collection('shopify_reviews').doc('voided'),
    );
    final partial = ShopifyReviewsRecord.getDocumentFromData(
      {
        'source': 'shopify',
        'reviewStatus': ShopifyReviewStatus.pendingReview,
        'financialStatus': 'partially_paid',
        'totalPrice': 10,
      },
      FirebaseFirestore.instance.collection('shopify_reviews').doc('partial'),
    );
    expect(shopifyReviewLooksPaid(paid), isTrue);
    expect(shopifyReviewLooksPaid(voided), isFalse);
    expect(shopifyReviewLooksVoided(voided), isTrue);
    expect(shopifyReviewLooksPaid(partial), isFalse);
    expect(shopifyReviewFinancialStatusKey(voided), 'voided');
    expect(shopifyReviewFinancialStatusKey(partial), 'partially_paid');
  });

  test('parseShopifyBulkApproveResult keeps partial failure recoverable', () {
    final result = parseShopifyBulkApproveResult({
      'approved': [
        {
          'reviewId': 'r1',
          'shopifyOrderId': '1',
          'officialOrderId': 'TFG-1',
        },
      ],
      'alreadyApproved': [
        {
          'reviewId': 'r2',
          'shopifyOrderId': '2',
          'officialOrderId': 'TFG-2',
        },
      ],
      'failed': [
        {
          'reviewId': 'r3',
          'code': 'failed-precondition',
          'error': 'Quarantined',
        },
      ],
    });

    expect(result.hasFailures, isTrue);
    expect(result.approved.single.officialOrderId, 'TFG-1');
    expect(result.alreadyApproved.single.reviewId, 'r2');
    expect(result.failed.single.reviewId, 'r3');
  });

  test('parseShopifyBulkDeleteResult keeps partial failure recoverable', () {
    final result = parseShopifyBulkDeleteResult({
      'deleted': [
        {
          'reviewId': 'r1',
          'shopifyOrderId': '1',
          'officialOrderId': '',
        },
      ],
      'failed': [
        {
          'reviewId': 'r2',
          'code': 'failed-precondition',
          'error': 'Approved Shopify review cannot be deleted',
        },
      ],
    });

    expect(result.hasFailures, isTrue);
    expect(result.deletedCount, 1);
    expect(result.failed.single.reviewId, 'r2');
  });

  test('UI-01 review line item image URL is the stored https reference', () {
    final review = ShopifyReviewsRecord.getDocumentFromData(
      {
        'reviewStatus': ShopifyReviewStatus.pendingReview,
        'lineItems': [
          {
            'name': 'Rose Box',
            'title': 'Rose Box',
            'variantTitle': 'Red',
            'qty': 1,
            'price': 88,
            'imageUrl': 'https://cdn.shopify.com/rose.jpg',
          },
        ],
      },
      FirebaseFirestore.instance.collection('shopify_reviews').doc('r-img'),
    );
    final item = shopifyReviewLineItemMaps(review).single;
    expect(shopifyReviewLineItemImageUrl(item), 'https://cdn.shopify.com/rose.jpg');
    expect(shopifyReviewLineItemTitle(item), 'Rose Box');
    expect(shopifyReviewLineItemVariant(item), 'Red');
    expect(shopifyReviewLineItemImageUrls(review), ['https://cdn.shopify.com/rose.jpg']);
  });

  test('UI-02 missing review image is null so UI can show placeholder', () {
    final review = ShopifyReviewsRecord.getDocumentFromData(
      {
        'reviewStatus': ShopifyReviewStatus.pendingReview,
        'lineItems': [
          {'name': 'Rose Box', 'qty': 1, 'price': 88},
        ],
      },
      FirebaseFirestore.instance.collection('shopify_reviews').doc('r-empty'),
    );
    expect(
      shopifyReviewLineItemImageUrl(shopifyReviewLineItemMaps(review).single),
      isNull,
    );
    expect(shopifyReviewLineItemImageUrls(review), isEmpty);
  });

  test('filterShopifyReviewsForQueue search matches billing address and sender phone', () {
    final reviews = [
      ShopifyReviewsRecord.getDocumentFromData(
        {
          'source': 'shopify',
          'reviewStatus': ShopifyReviewStatus.pendingReview,
          'shopifyOrderName': '#1342',
          'billingAddress': '1 Billing Lane, Singapore',
          'senderPhone': '88663763',
          'receivedAt': DateTime(2026, 8, 1),
        },
        FirebaseFirestore.instance.collection('shopify_reviews').doc('a'),
      ),
      ShopifyReviewsRecord.getDocumentFromData(
        {
          'source': 'shopify',
          'reviewStatus': ShopifyReviewStatus.pendingReview,
          'shopifyOrderName': '#1343',
          'shippingAddress': '200 Cantonment Road',
          'receivedAt': DateTime(2026, 8, 2),
        },
        FirebaseFirestore.instance.collection('shopify_reviews').doc('b'),
      ),
    ];

    expect(
      filterShopifyReviewsForQueue(reviews, searchQuery: 'billing lane')
          .single
          .reference
          .id,
      'a',
    );
    expect(
      filterShopifyReviewsForQueue(reviews, searchQuery: '88663763')
          .single
          .reference
          .id,
      'a',
    );
    expect(
      filterShopifyReviewsForQueue(reviews, searchQuery: 'cantonment')
          .single
          .reference
          .id,
      'b',
    );
  });

  test('shopifyReviewLineItemExtra reads addon without treating it as a priced SKU', () {
    final extra = shopifyReviewLineItemExtra({
      'name': 'PSF 04',
      'price': 74.9,
      'properties': [
        {'name': '_Addon', 'value': 'Warm Fairy Light (\$6.90 SGD)'},
        {'name': '_tpo_add_by', 'value': 'app'},
      ],
    });
    expect(extra, 'Add-on: Warm Fairy Light (\$6.90 SGD)');
  });

  test('shopifyReviewLineItemExtra keeps leftover options and skips card/phone', () {
    final extra = shopifyReviewLineItemExtra({
      'name': 'Omakase Bouquet',
      'price': 98,
      'properties': [
        {'name': 'Sender Hp No', 'value': '83497477'},
        {'name': 'Flowers Selection', 'value': 'Mix Flower Bouquet'},
        {'name': 'Message Card', 'value': 'Happy Graduation'},
        {'name': 'Remarks', 'value': 'Please call'},
      ],
    });
    expect(extra, contains('Flowers Selection: Mix Flower Bouquet'));
    expect(extra, contains('Please call'));
    expect(extra, isNot(contains('Happy Graduation')));
    expect(extra, isNot(contains('83497477')));
  });

  test('shopifyReviewLineItemCardMessage keeps a distinct card per bouquet', () {
    final young = shopifyReviewLineItemCardMessage({
      'name': 'Young Hearts',
      'properties': [
        {'name': 'Message Card', 'value': 'proud of you sayang'},
      ],
    });
    final blush = shopifyReviewLineItemCardMessage({
      'name': 'Blush Pink',
      'properties': [
        {'name': 'Message Card', 'value': 'proud of you ain'},
      ],
    });
    expect(young, contains('sayang'));
    expect(blush, contains('ain'));
    expect(
      shopifyReviewShouldShowPerProductCards([
        {'name': 'Young Hearts'},
        {'name': 'Blush Pink'},
        {'name': 'Delivery fee'},
      ]),
      isTrue,
    );
    expect(
      shopifyReviewResolvedLineCardMessage(
        item: {'name': 'Blush Pink', 'properties': []},
        orderCardMessage: 'shared only',
        items: [
          {'name': 'Young Hearts'},
          {'name': 'Blush Pink'},
        ],
      ),
      'shared only',
    );
  });
}
