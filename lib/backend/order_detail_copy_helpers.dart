import '/backend/order_item_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';

/// Plain-text order summary for clipboard: id, date, slot, address, products.
String buildCopyableOrderDetailText({
  required OrdersRecord order,
  required Iterable<OrderItemRecord> items,
  String? locale,
}) {
  final lines = <String>[
    'Order ID: ${orderListOrderId(order)}',
  ];

  final date = orderListDeliveryDateOnly(order, locale: locale);
  if (date != '-') {
    lines.add('Date: $date');
  }

  final slot = order.deliveryTimeSlot.trim();
  if (slot.isNotEmpty) {
    lines.add('Delivery slot: $slot');
  }

  if (!shouldHidePickupAddressOnOpsSurfaces(order)) {
    final address = [
      order.address.trim(),
      order.postalCode.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    if (address.isNotEmpty) {
      lines.add('Address: $address');
    }
  }

  final products = activeOrderItems(items.toList());
  if (products.isNotEmpty) {
    lines.add('Products:');
    for (final item in products) {
      final name = item.name.trim().isEmpty ? 'Item' : item.name.trim();
      final qty = item.qty > 0 ? item.qty : 1;
      lines.add('${qty}x $name');
    }
  }

  return lines.join('\n');
}
