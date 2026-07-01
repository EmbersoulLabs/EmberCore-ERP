import '/platform/platform_config_service.dart';
import '/platform/tenant_platform_config.dart';

/// Maps florist and generic order-type vocabularies for filters and forms.
const Map<String, Set<String>> kOrderTypeAliasGroups = {
  'Retail': {'Retail', 'OnSite'},
  'OnSite': {'Retail', 'OnSite'},
  'Delivery': {'Delivery', 'Remote'},
  'Remote': {'Delivery', 'Remote'},
  'PickUp': {'PickUp', 'WalkIn'},
  'WalkIn': {'PickUp', 'WalkIn'},
};

Set<String> orderTypeAliases(String filterType) =>
    kOrderTypeAliasGroups[filterType] ?? {filterType};

bool isRetailLikeOrderType(String type) =>
    orderTypeAliases('Retail').contains(type);

bool tenantUsesGenericOrderTypes([TenantPlatformConfig? config]) {
  final c = config ?? PlatformConfigService.instance.config;
  return c.orderTypes.contains('OnSite');
}

/// Non-retail fulfillment options for the delivery create-order form.
List<String> deliveryFormOrderTypeOptions([TenantPlatformConfig? config]) {
  final c = config ?? PlatformConfigService.instance.config;
  final nonRetail =
      c.orderTypes.where((t) => !isRetailLikeOrderType(t)).toList();
  if (nonRetail.isNotEmpty) {
    return nonRetail;
  }
  return const ['PickUp', 'Delivery'];
}

/// Filter value written by order-list type chips for the active tenant preset.
String orderListChipFilterValue(String chipKind, [TenantPlatformConfig? config]) {
  final generic = tenantUsesGenericOrderTypes(config);
  switch (chipKind) {
    case 'retail':
      return generic ? 'OnSite' : 'Retail';
    case 'delivery':
      return generic ? 'Remote' : 'Delivery';
    case 'pickUp':
      return generic ? 'WalkIn' : 'PickUp';
    default:
      return chipKind;
  }
}
