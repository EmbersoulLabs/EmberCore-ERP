import 'package:flutter/material.dart';

import '/backend/schema/enums/enums.dart';
import '/theme/ember_brand.dart';

/// Order status badge colors aligned with EmberSoul brand system.
Color emberOrderStatusColor(OrderStatus? status) {
  switch (status) {
    case OrderStatus.pending:
      return EmberBrand.amber;
    case OrderStatus.processing:
      return EmberBrand.electricBlue;
    case OrderStatus.ready_to_delivery:
      return EmberBrand.teal;
    case OrderStatus.out_of_delivery:
      return EmberBrand.electricBlue;
    case OrderStatus.completed:
      return EmberBrand.teal;
    case OrderStatus.cancelled:
      return EmberBrand.error;
    case null:
      return EmberBrand.textSecondary;
  }
}

Color emberOrderStatusBackground(OrderStatus? status) {
  return emberOrderStatusColor(status).withValues(alpha: 0.12);
}
