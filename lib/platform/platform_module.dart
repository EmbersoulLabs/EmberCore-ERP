/// Feature modules a tenant can enable via [tenant_platform_config].
enum PlatformModule {
  orders,
  pos,
  fieldService,
  drivers,
  customers,
  invoices,
  products,
  materialsBom,
  productionMenu,
  reports,
  shopifyImport,
  whatsappImport,
  customerBroadcast,
  /// Calendar / resource booking — not implemented yet; reserved for SaaS customize.
  appointments,
}

String platformModuleKey(PlatformModule module) => module.name;

PlatformModule? parsePlatformModuleKey(String? key) {
  if (key == null || key.isEmpty) {
    return null;
  }
  for (final module in PlatformModule.values) {
    if (module.name == key) {
      return module;
    }
  }
  return null;
}
