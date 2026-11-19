import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_invoice_helpers.dart';

void main() {
  group('calculateCustomerInvoiceTotals', () {
    const lines = [
      CustomerInvoiceLineItem(
        orderId: 'TFG-JUN26-0001',
        productName: 'Rose bouquet',
        remark: '',
        qty: 1,
        unitPrice: 100,
        lineSubtotal: 100,
      ),
      CustomerInvoiceLineItem(
        orderId: 'TFG-JUN26-0002',
        productName: 'Hand bouquet',
        remark: 'pink',
        qty: 2,
        unitPrice: 50,
        lineSubtotal: 100,
      ),
    ];

    test('sums subtotal without discount', () {
      final totals = calculateCustomerInvoiceTotals(lines: lines);
      expect(totals.subtotal, 200);
      expect(totals.discount, 0);
      expect(totals.total, 200);
    });

    test('applies percent discount', () {
      final totals = calculateCustomerInvoiceTotals(
        lines: lines,
        discount: const CustomerInvoiceDiscountInput(
          type: CustomerInvoiceDiscountType.percent,
          value: 10,
        ),
      );
      expect(totals.discount, 20);
      expect(totals.total, 180);
      expect(totals.discountLabel, '10.00%');
    });

    test('applies amount discount without RM/SGD label', () {
      final totals = calculateCustomerInvoiceTotals(
        lines: lines,
        discount: const CustomerInvoiceDiscountInput(
          type: CustomerInvoiceDiscountType.amount,
          value: 25,
        ),
      );
      expect(totals.discount, 25);
      expect(totals.total, 175);
      expect(totals.discountLabel, '25.00');
      expect(totals.discountLabel.contains('RM'), isFalse);
      expect(totals.discountLabel.contains('SGD'), isFalse);
    });

    test('parses legacy RM and SGD amount labels', () {
      expect(parseAmountDiscountLabel('RM 12.50'), 12.5);
      expect(parseAmountDiscountLabel('SGD 8.00'), 8);
      expect(parseAmountDiscountLabel('25.00'), 25);
    });
  });
}
