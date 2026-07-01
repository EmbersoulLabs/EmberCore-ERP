import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_id_service.dart';

void main() {
  group('OrderIdService.counterDocId', () {
    test('scopes delivery counter by month period', () {
      expect(
        OrderIdService.counterDocId('delivery', period: 'JUN26'),
        'default_delivery_JUN26',
      );
      expect(
        OrderIdService.counterDocId('retail', period: 'JUL26'),
        'default_retail_JUL26',
      );
    });

    test('different months use different counter docs', () {
      final june = OrderIdService.counterDocId('delivery', period: 'JUN26');
      final july = OrderIdService.counterDocId('delivery', period: 'JUL26');
      expect(june, isNot(equals(july)));
    });
  });

  group('OrderIdService order id patterns', () {
    test('detects delivery and retail ids regardless of tenant prefix', () {
      // Legacy florist prefix.
      expect(OrderIdService.isDeliveryOrderId('TFG-JUN26-0001'), isTrue);
      expect(OrderIdService.isRetailOrderId('TFG-JUN26-WI0001'), isTrue);
      expect(OrderIdService.isDeliveryOrderId('TFG-JUN26-WI0001'), isFalse);
      // Generic SaaS prefix.
      expect(OrderIdService.isDeliveryOrderId('EC-JUN26-0001'), isTrue);
      expect(OrderIdService.isRetailOrderId('EC-JUN26-WI0001'), isTrue);
      expect(OrderIdService.isDeliveryOrderId('EC-JUN26-WI0001'), isFalse);
      // Arbitrary tenant prefix.
      expect(OrderIdService.isDeliveryOrderId('ACME-JUN26-0001'), isTrue);
      expect(OrderIdService.isRetailOrderId('ACME-JUN26-WI0007'), isTrue);
    });

    test('legacy year-based delivery ids still detected', () {
      expect(OrderIdService.isDeliveryOrderId('TFG-2024-5'), isTrue);
      expect(OrderIdService.isDeliveryOrderId('EC-2024-5'), isTrue);
    });

    test('invoice numbers are not classified as delivery ids', () {
      expect(OrderIdService.isDeliveryOrderId('IN-TFG-JUN26-0001'), isFalse);
      expect(OrderIdService.isDeliveryOrderId('IN-EC-JUN26-0001'), isFalse);
    });

    test('detects invoice numbers regardless of tenant prefix', () {
      expect(OrderIdService.isInvoiceNumber('IN-TFG-JUN26-0001'), isTrue);
      expect(OrderIdService.isInvoiceNumber('IN-EC-JUN26-0001'), isTrue);
      expect(OrderIdService.isInvoiceNumber('TFG-JUN26-0001'), isFalse);
    });

    test('invoice counter doc id uses monthly period', () {
      expect(
        OrderIdService.counterDocId('invoice', period: 'JUN26'),
        'default_invoice_JUN26',
      );
    });
  });

  group('OrderIdService customer ids', () {
    test('formats customer ids with explicit prefix', () {
      expect(OrderIdService.formatCustomerId(1, prefix: 'TFG'), 'TFG01');
      expect(OrderIdService.formatCustomerId(9, prefix: 'TFG'), 'TFG09');
      expect(OrderIdService.formatCustomerId(99, prefix: 'TFG'), 'TFG99');
      expect(OrderIdService.formatCustomerId(100, prefix: 'TFG'), 'TFG100');
      expect(OrderIdService.formatCustomerId(1000, prefix: 'TFG'), 'TFG1000');
      // Generic tenant prefix.
      expect(OrderIdService.formatCustomerId(1, prefix: 'EC'), 'EC01');
      expect(OrderIdService.formatCustomerId(100, prefix: 'EC'), 'EC100');
    });

    test('defaults customer prefix to generic when no tenant loaded', () {
      // Singleton platform config defaults to the generic preset (`EC`).
      expect(OrderIdService.formatCustomerId(1), 'EC01');
    });

    test('detects valid customer public ids for a given prefix', () {
      expect(OrderIdService.isCustomerPublicId('TFG01', prefix: 'TFG'), isTrue);
      expect(
          OrderIdService.isCustomerPublicId('TFG1000', prefix: 'TFG'), isTrue);
      expect(
          OrderIdService.isCustomerPublicId('TFG1001', prefix: 'TFG'), isFalse);
      expect(
        OrderIdService.isCustomerPublicId('TFG-JUN26-0001', prefix: 'TFG'),
        isFalse,
      );
      expect(OrderIdService.isCustomerPublicId('EC07', prefix: 'EC'), isTrue);
    });

    test('uses fixed customer counter doc', () {
      expect(OrderIdService.customerCounterId, 'default_customer');
    });

    test('reuses lowest released customer sequence', () {
      expect(
        OrderIdService.pickNextCustomerSequence(
          current: 10,
          available: const [3, 7],
        ),
        3,
      );
      expect(
        OrderIdService.pickNextCustomerSequence(
          current: 10,
          available: const [],
        ),
        11,
      );
      expect(
        OrderIdService.pickNextCustomerSequence(
          current: 1000,
          available: const [],
        ),
        isNull,
      );
    });

    test('addReleasedCustomerSequence keeps sorted unique values', () {
      expect(
        OrderIdService.addReleasedCustomerSequence(const [5, 9], 3),
        [3, 5, 9],
      );
      expect(
        OrderIdService.addReleasedCustomerSequence(const [5], 5),
        [5],
      );
    });
  });
}
