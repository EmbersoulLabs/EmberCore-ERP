import '/backend/backend.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/tenant_query_helpers.dart';

/// One hour bucket in the sales report (local time, 0–23).
class HourlySalesBreakdown {
  const HourlySalesBreakdown({
    required this.hour,
    required this.totalAmount,
    required this.orderCount,
  });

  final int hour;
  final double totalAmount;
  final int orderCount;
}

/// Day-over-day sales comparison for a single calendar day.
class DayOverDayComparison {
  const DayOverDayComparison({
    required this.currentAmount,
    required this.previousAmount,
  });

  final double currentAmount;
  final double previousAmount;

  double get delta => currentAmount - previousAmount;

  /// Percent change vs previous day; null when previous day had no sales.
  double? get changePercent {
    if (previousAmount <= 0) {
      return currentAmount > 0 ? null : 0;
    }
    return (delta / previousAmount) * 100;
  }

  bool get isUp => delta > 0;
  bool get isDown => delta < 0;
  bool get isFlat => delta.abs() < 0.005;
}

/// One product row in the sales report.
class ProductSalesBreakdown {
  const ProductSalesBreakdown({
    required this.productName,
    required this.totalQty,
    required this.totalAmount,
  });

  final String productName;
  final int totalQty;
  final double totalAmount;
}

/// One payment method row in the daily report.
class PaymentMethodBreakdown {
  const PaymentMethodBreakdown({
    required this.label,
    required this.orderCount,
    required this.totalAmount,
  });

  final String label;
  final int orderCount;
  final double totalAmount;
}

/// Aggregated sales for a calendar date range (paid orders only).
class DailySalesReport {
  const DailySalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalSalesAmount,
    required this.productBreakdown,
    required this.paymentBreakdown,
    required this.unpaidOrdersCount,
    required this.unpaidOrdersTotalAmount,
    required this.hourlyBreakdown,
    this.dayOverDayComparison,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final double totalSalesAmount;
  final List<ProductSalesBreakdown> productBreakdown;
  final List<PaymentMethodBreakdown> paymentBreakdown;
  final int unpaidOrdersCount;
  final double unpaidOrdersTotalAmount;
  final List<HourlySalesBreakdown> hourlyBreakdown;
  final DayOverDayComparison? dayOverDayComparison;

  bool get isSingleDay =>
      calendarDay(startDate) == calendarDay(endDate);

  double get averageOrderAmount =>
      totalOrders > 0 ? totalSalesAmount / totalOrders : 0;

  List<ProductSalesBreakdown> get topProducts =>
      productBreakdown.take(3).toList(growable: false);

  bool get hasUnpaidOrders => unpaidOrdersTotalAmount > 0.005;
}

/// Normalizes stored paymentType values (e.g. Paynow → PayNow).
String normalizePaymentLabel(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(' ', '');
  if (normalized.isEmpty) {
    return 'Unspecified';
  }
  if (normalized == 'cash') {
    return 'Cash';
  }
  if (normalized == 'paynow') {
    return 'PayNow';
  }
  if (normalized == 'card') {
    return 'Card';
  }
  if (normalized == 'shopify') {
    return 'Shopify';
  }
  if (normalized == 'shopee') {
    return 'Shopee';
  }
  return raw.trim();
}

bool orderQualifiesForDailySales(OrdersRecord order) {
  if (order.paymentType.trim().isEmpty) {
    return false;
  }
  if (order.status == OrderStatus.cancelled) {
    return false;
  }
  final amount = order.totalAmount > 0 ? order.totalAmount : order.total;
  return amount > 0;
}

bool isOrderOnCalendarDay(DateTime? timestamp, DateTime day) {
  if (timestamp == null) {
    return false;
  }
  final local = timestamp.toLocal();
  return local.year == day.year &&
      local.month == day.month &&
      local.day == day.day;
}

DateTime calendarDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool isTodayCalendarDay(DateTime day) =>
    calendarDay(day) == calendarDay(DateTime.now());

/// Sales are attributed to the calendar day of [OrdersRecord.createdTime].
DateTime? dailySalesReportDate(OrdersRecord order) {
  if (order.createdTime != null) {
    return order.createdTime;
  }
  if (isRetailOrderRecord(order)) {
    return order.deliveryDate;
  }
  return null;
}

bool orderMatchesDailySalesDate(OrdersRecord order, DateTime day) {
  return isOrderOnCalendarDay(dailySalesReportDate(order), day);
}

bool orderMatchesDailySalesDateRange(
  OrdersRecord order, {
  required DateTime startDate,
  required DateTime endDate,
}) {
  final timestamp = dailySalesReportDate(order);
  if (timestamp == null) {
    return false;
  }
  final effective = timestamp.toLocal();
  return !effective.isBefore(startOfDay(startDate)) &&
      !effective.isAfter(endOfDay(endDate));
}

({DateTime start, DateTime end}) normalizeSalesReportDateRange({
  required DateTime startDate,
  required DateTime endDate,
}) {
  var start = calendarDay(startDate);
  var end = calendarDay(endDate);
  if (start.isAfter(end)) {
    final swapped = start;
    start = end;
    end = swapped;
  }
  return (start: start, end: end);
}

bool isTodayDateRange(DateTime startDate, DateTime endDate) {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  final today = calendarDay(DateTime.now());
  return range.start == today && range.end == today;
}

double orderSalesAmount(OrdersRecord order) {
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  return order.total;
}

double orderItemSalesAmount(OrderItemRecord item) {
  if (item.subtotal > 0) {
    return item.subtotal;
  }
  if (item.qty <= 0) {
    return 0;
  }
  return item.price * item.qty;
}

/// Aggregates sold qty and revenue by product name for active line items.
List<ProductSalesBreakdown> aggregateProductSales(List<OrderItemRecord> items) {
  final totalsByName = <String, ({int qty, double amount})>{};

  for (final item in activeOrderItems(items)) {
    final name = item.name.trim().isEmpty ? 'Item' : item.name.trim();
    final existing = totalsByName[name];
    if (existing == null) {
      totalsByName[name] = (
        qty: item.qty,
        amount: orderItemSalesAmount(item),
      );
    } else {
      totalsByName[name] = (
        qty: existing.qty + item.qty,
        amount: existing.amount + orderItemSalesAmount(item),
      );
    }
  }

  final breakdown = totalsByName.entries
      .map(
        (entry) => ProductSalesBreakdown(
          productName: entry.key,
          totalQty: entry.value.qty,
          totalAmount: entry.value.amount,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byAmount = b.totalAmount.compareTo(a.totalAmount);
      if (byAmount != 0) {
        return byAmount;
      }
      return a.productName.compareTo(b.productName);
    });

  return breakdown;
}

bool isSalesReportOrderCancelled(OrdersRecord order) =>
    order.status == OrderStatus.cancelled;

/// Doc IDs (`original_order_id`) of orders archived in [deleted_orders] and not
/// restored. Used to keep deleted orders out of sales aggregates even when a
/// stale `orders` doc or orphan `order_item` rows remain.
Future<Set<String>> loadActiveDeletedOrderDocIds() async {
  final archives = await queryTenantDeletedOrdersRecordOnce(
    queryBuilder: (q) => q.where('is_restored', isEqualTo: false),
  );
  return archives
      .map((archive) => archive.originalOrderId.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
}

bool isExcludedDeletedSalesOrder(
  OrdersRecord order,
  Set<String> deletedOrderDocIds,
) {
  if (deletedOrderDocIds.isEmpty) {
    return false;
  }
  return deletedOrderDocIds.contains(order.reference.id);
}

List<OrdersRecord> excludeArchivedDeletedOrders(
  Iterable<OrdersRecord> orders,
  Set<String> deletedOrderDocIds,
) {
  if (deletedOrderDocIds.isEmpty) {
    return orders.toList(growable: false);
  }
  return orders
      .where((order) => !isExcludedDeletedSalesOrder(order, deletedOrderDocIds))
      .toList(growable: false);
}

/// Unpaid orders in the report range (excludes cancelled, zero-total).
bool isUnpaidForSalesReport(OrdersRecord order) {
  if (isSalesReportOrderCancelled(order)) {
    return false;
  }
  if (orderSalesAmount(order) <= 0) {
    return false;
  }
  return !isCustomerOrderPaid(order);
}

double unpaidOrderOutstandingAmount(OrdersRecord order) {
  if (order.balanceDue > 0) {
    return order.balanceDue;
  }
  return orderSalesAmount(order);
}

/// Buckets paid-order revenue by local hour of [dailySalesReportDate].
List<HourlySalesBreakdown> aggregateHourlySales(List<OrdersRecord> paidOrders) {
  final amounts = List<double>.filled(24, 0);
  final counts = List<int>.filled(24, 0);

  for (final order in paidOrders) {
    final timestamp = dailySalesReportDate(order);
    if (timestamp == null) {
      continue;
    }
    final hour = timestamp.toLocal().hour;
    amounts[hour] += orderSalesAmount(order);
    counts[hour]++;
  }

  return List.generate(
    24,
    (hour) => HourlySalesBreakdown(
      hour: hour,
      totalAmount: amounts[hour],
      orderCount: counts[hour],
    ),
  );
}

double sumOrderSalesAmount(Iterable<OrdersRecord> orders) {
  var total = 0.0;
  for (final order in orders) {
    total += orderSalesAmount(order);
  }
  return total;
}

/// Loads non-cancelled orders between [startDate] and [endDate] (inclusive).
/// Excludes orders archived in [deleted_orders] ([loadActiveDeletedOrderDocIds]).
Future<List<OrdersRecord>> loadOrdersForSalesReportRange({
  required DateTime startDate,
  required DateTime endDate,
  Set<String>? excludedDeletedOrderDocIds,
}) async {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  final rangeStart = startOfDay(range.start);
  final rangeEnd = endOfDay(range.end);

  List<OrdersRecord> orders;
  try {
    orders = await queryTenantOrdersRecordOnce(
      queryBuilder: (q) => q
          .where('created_time', isGreaterThanOrEqualTo: rangeStart)
          .where('created_time', isLessThanOrEqualTo: rangeEnd),
    );
    orders = orders
        .where(
          (order) => orderMatchesDailySalesDateRange(
            order,
            startDate: range.start,
            endDate: range.end,
          ),
        )
        .toList();
  } catch (_) {
    orders = await queryTenantOrdersRecordOnce();
    orders = orders
        .where(
          (order) => orderMatchesDailySalesDateRange(
            order,
            startDate: range.start,
            endDate: range.end,
          ),
        )
        .toList();
  }

  final deletedDocIds =
      excludedDeletedOrderDocIds ?? await loadActiveDeletedOrderDocIds();

  return excludeArchivedDeletedOrders(
    orders.where((order) => !isSalesReportOrderCancelled(order)),
    deletedDocIds,
  );
}

/// Loads paid orders between [startDate] and [endDate] (inclusive).
Future<List<OrdersRecord>> loadPaidOrdersForSalesReportRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final orders = await loadOrdersForSalesReportRange(
    startDate: startDate,
    endDate: endDate,
  );
  return orders.where(orderQualifiesForDailySales).toList(growable: false);
}

/// Aggregated sales for a calendar date range (paid orders only).
Future<DailySalesReport> buildDailySalesReportRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );

  final deletedDocIds = await loadActiveDeletedOrderDocIds();
  final ordersInRange = await loadOrdersForSalesReportRange(
    startDate: range.start,
    endDate: range.end,
    excludedDeletedOrderDocIds: deletedDocIds,
  );
  final paidOrders =
      ordersInRange.where(orderQualifiesForDailySales).toList(growable: false);
  final unpaidOrders =
      ordersInRange.where(isUnpaidForSalesReport).toList(growable: false);

  final totalsByPayment = <String, PaymentMethodBreakdown>{};
  var salesSum = 0.0;

  for (final order in paidOrders) {
    final label = normalizePaymentLabel(order.paymentType);
    final amount = orderSalesAmount(order);
    salesSum += amount;

    final existing = totalsByPayment[label];
    if (existing == null) {
      totalsByPayment[label] = PaymentMethodBreakdown(
        label: label,
        orderCount: 1,
        totalAmount: amount,
      );
    } else {
      totalsByPayment[label] = PaymentMethodBreakdown(
        label: label,
        orderCount: existing.orderCount + 1,
        totalAmount: existing.totalAmount + amount,
      );
    }
  }

  final breakdown = totalsByPayment.values.toList()
    ..sort((a, b) {
      const order = ['Cash', 'PayNow', 'Card'];
      final ai = order.indexOf(a.label);
      final bi = order.indexOf(b.label);
      if (ai >= 0 && bi >= 0) {
        return ai.compareTo(bi);
      }
      if (ai >= 0) {
        return -1;
      }
      if (bi >= 0) {
        return 1;
      }
      return a.label.compareTo(b.label);
    });

  final paidOrderIds = paidOrders.map((order) => order.reference.id).toSet();
  final orderItems = await queryTenantOrderItemRecordOnce();
  final paidOrderItems = orderItems
      .where(
        (item) =>
            item.orderRef != null &&
            paidOrderIds.contains(item.orderRef!.id) &&
            !deletedDocIds.contains(item.orderRef!.id),
      )
      .toList(growable: false);
  final productBreakdown = aggregateProductSales(paidOrderItems);
  final hourlyBreakdown = aggregateHourlySales(paidOrders);

  var unpaidSum = 0.0;
  for (final order in unpaidOrders) {
    unpaidSum += unpaidOrderOutstandingAmount(order);
  }

  DayOverDayComparison? dayOverDay;
  if (calendarDay(range.start) == calendarDay(range.end)) {
    final previousDay = range.start.subtract(const Duration(days: 1));
    final previousPaid = await loadPaidOrdersForSalesReportRange(
      startDate: previousDay,
      endDate: previousDay,
    );
    dayOverDay = DayOverDayComparison(
      currentAmount: salesSum,
      previousAmount: sumOrderSalesAmount(previousPaid),
    );
  }

  return DailySalesReport(
    startDate: range.start,
    endDate: range.end,
    totalOrders: paidOrders.length,
    totalSalesAmount: salesSum,
    productBreakdown: productBreakdown,
    paymentBreakdown: breakdown,
    unpaidOrdersCount: unpaidOrders.length,
    unpaidOrdersTotalAmount: unpaidSum,
    hourlyBreakdown: hourlyBreakdown,
    dayOverDayComparison: dayOverDay,
  );
}

/// Loads paid orders for a single [day].
Future<DailySalesReport> buildDailySalesReport(DateTime day) =>
    buildDailySalesReportRange(startDate: day, endDate: day);
