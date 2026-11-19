import '/backend/schema/order_item_record.dart';

/// Greeting card text stored on a line item (`Order_item.cardmessage`).
String lineCardMessage(OrderItemRecord item) => item.cardmessage.trim();

bool isGreetingCardProductLine(OrderItemRecord item) =>
    item.name.trim().toLowerCase() != 'delivery fee';

List<OrderItemRecord> greetingCardProductLines(
  Iterable<OrderItemRecord> items,
) =>
    items.where(isGreetingCardProductLine).toList();

/// Two or more merchandise lines: one copyable card under each product.
bool shouldShowPerProductMessageCards(Iterable<OrderItemRecord> items) =>
    greetingCardProductLines(items).length > 1;

bool anyLineHasCardMessage(Iterable<OrderItemRecord> items) =>
    items.any((item) => lineCardMessage(item).isNotEmpty);

List<OrderItemRecord> itemsWithCardMessage(Iterable<OrderItemRecord> items) =>
    items.where((item) => lineCardMessage(item).isNotEmpty).toList();

/// Line text, or the order-level card when a multi-product order has no
/// per-line gift message (typical Shopify `note_attributes`).
String resolvedLineCardMessage({
  required OrderItemRecord item,
  required String orderCardMessage,
  required Iterable<OrderItemRecord> items,
}) {
  final own = lineCardMessage(item);
  if (own.isNotEmpty) {
    return own;
  }
  if (shouldShowPerProductMessageCards(items) &&
      isGreetingCardProductLine(item)) {
    return orderCardMessage.trim();
  }
  return '';
}

bool shouldShowLineMessageCard({
  required OrderItemRecord item,
  required String orderCardMessage,
  required Iterable<OrderItemRecord> items,
}) {
  if (!isGreetingCardProductLine(item)) {
    return false;
  }
  if (lineCardMessage(item).isNotEmpty) {
    return true;
  }
  return shouldShowPerProductMessageCards(items);
}

/// Old single-product orders only stored `orders.card_message`. Hidden when
/// the list already shows one card per product.
bool shouldShowLegacyOrderCard({
  required String orderCardMessage,
  required Iterable<OrderItemRecord> items,
}) {
  if (shouldShowPerProductMessageCards(items)) {
    return false;
  }
  return !anyLineHasCardMessage(items) && orderCardMessage.trim().isNotEmpty;
}

/// Copy payload: card body plus order id, matching the printed card footer.
String messageCardCopyText({
  required String message,
  required String orderId,
}) {
  final body = message.trim();
  final id = orderId.trim();
  if (body.isEmpty && id.isEmpty) {
    return '';
  }
  if (body.isEmpty) {
    return id;
  }
  if (id.isEmpty) {
    return body;
  }
  return '$body\n\n$id';
}

/// New catalog/custom lines inherit the order-level card only while the order
/// is still in the legacy "one card for the whole order" state.
String inheritCardMessageForNewLine({
  required String orderCardMessage,
  required Iterable<OrderItemRecord> existingItems,
}) {
  if (anyLineHasCardMessage(existingItems)) {
    return '';
  }
  return orderCardMessage.trim();
}

/// Fallback / CSV / thermal when a caller still reads `orders.card_message`.
/// One shared line text stays as-is; different texts are labeled by product.
String syncedOrderCardMessage({
  required Iterable<OrderItemRecord> items,
  required String fallback,
}) {
  final filled = itemsWithCardMessage(items);
  if (filled.isEmpty) {
    return fallback.trim();
  }
  final unique = filled.map(lineCardMessage).toSet();
  if (unique.length == 1) {
    return unique.first;
  }
  return filled.map((item) {
    final name = item.name.trim().isEmpty ? 'Item' : item.name.trim();
    return '$name\n${lineCardMessage(item)}';
  }).join('\n\n');
}

class PrintableMessageCard {
  const PrintableMessageCard({
    required this.message,
    this.productName = '',
  });

  final String message;
  final String productName;

  bool get isLegacyOrderCard => productName.isEmpty;
}

/// One printed card per filled line; otherwise the order-level fallback.
/// Multi-product orders print one card per merchandise line (order-level
/// text fills lines that have no gift message of their own).
List<PrintableMessageCard> printableMessageCards({
  required String orderCardMessage,
  required Iterable<OrderItemRecord> items,
}) {
  if (shouldShowPerProductMessageCards(items)) {
    return [
      for (final item in greetingCardProductLines(items))
        PrintableMessageCard(
          message: resolvedLineCardMessage(
            item: item,
            orderCardMessage: orderCardMessage,
            items: items,
          ),
          productName: item.name.trim(),
        ),
    ];
  }
  final filled = itemsWithCardMessage(items);
  if (filled.isNotEmpty) {
    return [
      for (final item in filled)
        PrintableMessageCard(
          message: lineCardMessage(item),
          productName: item.name.trim(),
        ),
    ];
  }
  final fallback = orderCardMessage.trim();
  if (fallback.isEmpty) {
    return const [];
  }
  return [PrintableMessageCard(message: fallback)];
}
