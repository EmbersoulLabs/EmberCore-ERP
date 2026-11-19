import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/storefront_catalog_sync_api.dart';

void main() {
  test('parseStorefrontCatalogSyncResult reads counts', () {
    final result = parseStorefrontCatalogSyncResult({
      'website': 'https://www.theflowerguy.sg',
      'createdCount': 2,
      'priceUpdateCount': 3,
      'deactivatedCount': 1,
      'storefrontProducts': 10,
      'firestoreProducts': 12,
    });
    expect(result.createdCount, 2);
    expect(result.priceUpdateCount, 3);
    expect(result.deactivatedCount, 1);
    expect(
      storefrontCatalogSyncSummary(result),
      'Catalog updated: 2 added, 3 prices, 1 deactivated.',
    );
  });

  test('storefrontCatalogSyncFunctionUri uses asia-southeast1', () {
    expect(
      storefrontCatalogSyncFunctionUri(projectId: 'tfg-sales-record').toString(),
      'https://asia-southeast1-tfg-sales-record.cloudfunctions.net/syncStorefrontCatalog',
    );
  });
}
