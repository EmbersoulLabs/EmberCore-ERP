import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_production_menu_helpers.dart';

void main() {
  group('production material qty overrides', () {
    test('sanitizes material path for Firestore map keys', () {
      expect(
        productionMaterialOverrideKey(
          materialName: 'Red Rose',
          unit: 'stem',
          materialRefPath: 'materials/rose',
        ),
        'materials_rose',
      );
    });

    test('applyProductionMaterialQtyOverrides replaces matching qty', () {
      const rose = OrderProductionMaterialLine(
        materialName: 'Red Rose',
        unit: 'stem',
        totalQty: 12,
        unitCost: 2,
        materialRefPath: 'materials/rose',
      );
      const wrap = OrderProductionMaterialLine(
        materialName: 'Wrapper',
        unit: 'sheet',
        totalQty: 1,
        unitCost: 0.5,
        materialRefPath: 'materials/wrap',
      );

      final applied = applyProductionMaterialQtyOverrides(
        [rose, wrap],
        {'materials_rose': 18},
      );

      expect(applied.first.totalQty, 18);
      expect(applied.first.lineCost, 36);
      expect(applied.last.totalQty, 1);
    });

    test('parseProductionMaterialQtysFromRaw ignores invalid values', () {
      final parsed = parseProductionMaterialQtysFromRaw({
        'materials_rose': 10,
        'bad': 'nope',
        '': 4,
        'materials_wrap': -1,
      });
      expect(parsed, {'materials_rose': 10.0});
    });
  });
}
