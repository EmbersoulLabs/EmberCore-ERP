import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_list_ui_labels.dart';
import 'package:tfg_vday/flutter_flow/form_field_controller.dart';

void main() {
  test('normalizeOrderListStatusSelection treats all as exclusive', () {
    expect(normalizeOrderListStatusSelection(null), ['all']);
    expect(normalizeOrderListStatusSelection([]), ['all']);
    expect(normalizeOrderListStatusSelection(['all']), ['all']);
    expect(normalizeOrderListStatusSelection(['all', 'pending']), ['pending']);
    expect(normalizeOrderListStatusSelection(['pending', 'all']), ['all']);
    expect(
      normalizeOrderListStatusSelection(['pending', 'completed']),
      ['pending', 'completed'],
    );
  });

  test('normalizeOrderListPersonSelection treats all as exclusive', () {
    expect(normalizeOrderListPersonSelection(['all', 'unassigned']), [
      'unassigned',
    ]);
    expect(normalizeOrderListPersonSelection(['unassigned', 'all']), ['all']);
  });

  test('rewriting a normalized status list does not re-enter listeners', () {
    final controller = FormFieldController<List<String>?>(['all']);
    var notifications = 0;
    controller.addListener(() {
      notifications++;
      expect(
        notifications,
        lessThan(8),
        reason: 'status filter listener re-entered',
      );
      final normalized = normalizeOrderListStatusSelection(controller.value);
      if (listEquals(controller.value, normalized)) {
        return;
      }
      controller.value = List<String>.from(normalized);
    });

    controller.value = ['all', 'pending'];
    expect(controller.value, ['pending']);
    expect(notifications, 2);
  });
}
