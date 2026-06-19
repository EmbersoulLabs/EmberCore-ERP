import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/platform/platform_module.dart';
import 'package:tfg_vday/platform/tenant_platform_config.dart';

void main() {
  group('TenantPlatformConfig.genericDefaults', () {
    test('uses neutral order types and EC prefix', () {
      final config = TenantPlatformConfig.genericDefaults();
      expect(config.orderTypes, ['OnSite', 'WalkIn', 'Remote']);
      expect(config.orderIdPrefix, 'EC');
      expect(config.industryPreset, IndustryPreset.generic);
      expect(config.isModuleEnabled(PlatformModule.materialsBom), isFalse);
      expect(config.isModuleEnabled(PlatformModule.orders), isTrue);
      expect(config.isModuleEnabled(PlatformModule.drivers), isTrue);
    });

    test('field labels are generic not florist', () {
      final config = TenantPlatformConfig.genericDefaults();
      expect(
        config.fieldLabel(PlatformFieldKey.serviceNotes, locale: 'en'),
        'Service notes',
      );
      expect(
        config.fieldLabel(PlatformFieldKey.scheduledDate, locale: 'zh'),
        '预约日期',
      );
    });
  });

  group('TenantPlatformConfig.floristLegacy', () {
    test('enables legacy modules and TFG prefix', () {
      final config = TenantPlatformConfig.floristLegacy();
      expect(config.orderIdPrefix, 'TFG');
      expect(config.orderTypes, contains('Delivery'));
      expect(config.isModuleEnabled(PlatformModule.whatsappImport), isTrue);
      expect(
        config.fieldLabel(PlatformFieldKey.serviceNotes, locale: 'en'),
        'Card message',
      );
    });
  });

  group('TenantPlatformConfig.fromFirestore', () {
    test('empty data returns generic defaults', () {
      final config = TenantPlatformConfig.fromFirestore(null);
      expect(config.orderIdPrefix, 'EC');
    });

    test('florist industry_key applies legacy preset', () {
      final config = TenantPlatformConfig.fromFirestore({
        'industry_key': 'florist',
      });
      expect(config.orderIdPrefix, 'TFG');
      expect(config.orderTypes, contains('Retail'));
    });

    test('merges custom field labels', () {
      final config = TenantPlatformConfig.fromFirestore({
        'field_labels_en': {
          'serviceNotes': 'Work order notes',
        },
      });
      expect(
        config.fieldLabel(PlatformFieldKey.serviceNotes, locale: 'en'),
        'Work order notes',
      );
      expect(
        config.fieldLabel(PlatformFieldKey.scheduledDate, locale: 'en'),
        'Scheduled date',
      );
    });

    test('enabled_modules override preset', () {
      final config = TenantPlatformConfig.fromFirestore({
        'enabled_modules': ['orders', 'appointments'],
      });
      expect(config.isModuleEnabled(PlatformModule.orders), isTrue);
      expect(config.isModuleEnabled(PlatformModule.appointments), isTrue);
      expect(config.isModuleEnabled(PlatformModule.drivers), isFalse);
    });
  });
}
