import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/l10n/tr.dart';
import '/platform/platform_order_types.dart';

enum OrderListTypeChip {
  all,
  retail,
  delivery,
  pickUp,
}

extension OrderListTypeChipX on OrderListTypeChip {
  String label(BuildContext context) {
    if (tenantUsesGenericOrderTypes()) {
      switch (this) {
        case OrderListTypeChip.all:
          return tr(context, 'order.type.all');
        case OrderListTypeChip.retail:
          return tr(context, 'order.type.onSite');
        case OrderListTypeChip.delivery:
          return tr(context, 'order.type.remote');
        case OrderListTypeChip.pickUp:
          return tr(context, 'order.type.walkIn');
      }
    }
    switch (this) {
      case OrderListTypeChip.all:
        return tr(context, 'order.type.all');
      case OrderListTypeChip.retail:
        return tr(context, 'order.type.retail');
      case OrderListTypeChip.delivery:
        return tr(context, 'order.type.delivery');
      case OrderListTypeChip.pickUp:
        return tr(context, 'order.type.pickUp');
    }
  }

  String get filterValue {
    switch (this) {
      case OrderListTypeChip.all:
        return 'All';
      case OrderListTypeChip.retail:
        return orderListChipFilterValue('retail');
      case OrderListTypeChip.delivery:
        return orderListChipFilterValue('delivery');
      case OrderListTypeChip.pickUp:
        return orderListChipFilterValue('pickUp');
    }
  }
}

OrderListTypeChip? orderListTypeChipKeyFromLabel(String? label) {
  if (label == null || label.isEmpty) {
    return null;
  }
  for (final key in OrderListTypeChip.values) {
    if (_allLabelsForKey(key).contains(label)) {
      return key;
    }
  }
  return null;
}

List<String> _allLabelsForKey(OrderListTypeChip key) {
  switch (key) {
    case OrderListTypeChip.all:
      return const ['All', '全部', 'Semua'];
    case OrderListTypeChip.retail:
      if (tenantUsesGenericOrderTypes()) {
        return const ['OnSite', '现场', 'Di Tapak'];
      }
      return const ['Retail', '零售', 'Runcit'];
    case OrderListTypeChip.delivery:
      if (tenantUsesGenericOrderTypes()) {
        return const ['Remote', '远程', 'Jauh'];
      }
      return const ['Delivery', '配送', 'Penghantaran'];
    case OrderListTypeChip.pickUp:
      if (tenantUsesGenericOrderTypes()) {
        return const ['WalkIn', '到店', 'Walk-in'];
      }
      return const ['PickUp', '自取', 'Ambil Sendiri'];
  }
}

List<ChipData> orderListTypeChipOptions(BuildContext context) {
  return OrderListTypeChip.values
      .map((key) => ChipData(key.label(context)))
      .toList();
}

/// Maps localized chip label to filter value used by [applyOrderListClientFilters].
String? orderListTypeFilterValue(String? chipLabel) {
  final key = orderListTypeChipKeyFromLabel(chipLabel);
  if (key != null) {
    return key.filterValue;
  }
  const canonical = {
    'All',
    'Retail',
    'Delivery',
    'PickUp',
    'OnSite',
    'Remote',
    'WalkIn',
  };
  if (chipLabel != null && canonical.contains(chipLabel)) {
    return chipLabel;
  }
  return chipLabel;
}
