import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_card_message_helpers.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';

import 'firebase_test_setup.dart';

OrderItemRecord _item({
  required String id,
  String name = 'Rose',
  String card = '',
  int qty = 1,
}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': name,
      'qty': qty,
      'price': 10.0,
      if (card.isNotEmpty) 'cardmessage': card,
    },
    FirebaseFirestore.instance.collection('Order_item').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('legacy card shows only when no line has text', () {
    final empty = [_item(id: 'a')];
    expect(
      shouldShowLegacyOrderCard(
        orderCardMessage: 'Happy Birthday',
        items: empty,
      ),
      isTrue,
    );
    expect(
      shouldShowLegacyOrderCard(
        orderCardMessage: 'Happy Birthday',
        items: [_item(id: 'a', card: 'For Mum')],
      ),
      isFalse,
    );
    expect(
      shouldShowLegacyOrderCard(orderCardMessage: '  ', items: empty),
      isFalse,
    );
  });

  test('multi-product orders hide the standalone legacy card', () {
    expect(
      shouldShowLegacyOrderCard(
        orderCardMessage: 'Happy Birthday',
        items: [_item(id: 'a'), _item(id: 'b', name: 'Orchid')],
      ),
      isFalse,
    );
    expect(
      shouldShowPerProductMessageCards([
        _item(id: 'a'),
        _item(id: 'b', name: 'Orchid'),
      ]),
      isTrue,
    );
  });

  test('delivery fee does not count as a product for per-line cards', () {
    expect(
      shouldShowPerProductMessageCards([
        _item(id: 'a'),
        _item(id: 'fee', name: 'Delivery Fee'),
      ]),
      isFalse,
    );
    expect(
      shouldShowLineMessageCard(
        item: _item(id: 'fee', name: 'Delivery Fee'),
        orderCardMessage: 'Hi',
        items: [
          _item(id: 'a'),
          _item(id: 'b', name: 'Orchid'),
          _item(id: 'fee', name: 'Delivery Fee'),
        ],
      ),
      isFalse,
    );
  });

  test('multi-product empty lines inherit the order-level card', () {
    final rose = _item(id: 'a');
    final orchid = _item(id: 'b', name: 'Orchid');
    final items = [rose, orchid];
    expect(
      resolvedLineCardMessage(
        item: rose,
        orderCardMessage: 'Happy Birthday',
        items: items,
      ),
      'Happy Birthday',
    );
    expect(
      shouldShowLineMessageCard(
        item: rose,
        orderCardMessage: 'Happy Birthday',
        items: items,
      ),
      isTrue,
    );
  });

  test('printable cards are one per product on multi-item orders', () {
    final cards = printableMessageCards(
      orderCardMessage: 'Order level',
      items: [
        _item(id: 'a', name: 'Rose bouquet', card: 'Happy Birthday Mum'),
        _item(id: 'b', name: 'Orchid pot'),
        _item(id: 'c', name: 'Lily', card: 'Get well soon'),
      ],
    );
    expect(cards, hasLength(3));
    expect(cards[0].productName, 'Rose bouquet');
    expect(cards[0].message, 'Happy Birthday Mum');
    expect(cards[1].productName, 'Orchid pot');
    expect(cards[1].message, 'Order level');
    expect(cards[2].productName, 'Lily');
    expect(cards[2].isLegacyOrderCard, isFalse);
  });

  test('printable cards fall back to the order-level message', () {
    final cards = printableMessageCards(
      orderCardMessage: 'Happy Birthday Mum',
      items: [_item(id: 'a')],
    );
    expect(cards, hasLength(1));
    expect(cards.single.isLegacyOrderCard, isTrue);
    expect(cards.single.message, 'Happy Birthday Mum');
  });

  test('printable multi-product cards copy the shared order message', () {
    final cards = printableMessageCards(
      orderCardMessage: 'Happy Birthday Mum',
      items: [_item(id: 'a'), _item(id: 'b', name: 'Orchid')],
    );
    expect(cards, hasLength(2));
    expect(cards[0].message, 'Happy Birthday Mum');
    expect(cards[1].message, 'Happy Birthday Mum');
    expect(cards[0].isLegacyOrderCard, isFalse);
  });

  test('new lines inherit order card only in the legacy state', () {
    expect(
      inheritCardMessageForNewLine(
        orderCardMessage: 'Hello',
        existingItems: [_item(id: 'a')],
      ),
      'Hello',
    );
    expect(
      inheritCardMessageForNewLine(
        orderCardMessage: 'Hello',
        existingItems: [_item(id: 'a', card: 'For Mum')],
      ),
      '',
    );
  });

  test('synced order card keeps a shared line text', () {
    expect(
      syncedOrderCardMessage(
        items: [
          _item(id: 'a', card: 'Hello'),
          _item(id: 'b', name: 'Orchid', card: 'Hello'),
        ],
        fallback: 'ignored',
      ),
      'Hello',
    );
  });

  test('synced order card labels distinct line texts', () {
    expect(
      syncedOrderCardMessage(
        items: [
          _item(id: 'a', name: 'Rose', card: 'For Mum'),
          _item(id: 'b', name: 'Orchid', card: 'Get well'),
        ],
        fallback: 'ignored',
      ),
      'Rose\nFor Mum\n\nOrchid\nGet well',
    );
  });

  test('copy text appends the order id', () {
    expect(
      messageCardCopyText(message: 'For Mum', orderId: 'TFG-SEP26-0001'),
      'For Mum\n\nTFG-SEP26-0001',
    );
    expect(
      messageCardCopyText(message: '  ', orderId: 'TFG-SEP26-0001'),
      'TFG-SEP26-0001',
    );
  });
}
