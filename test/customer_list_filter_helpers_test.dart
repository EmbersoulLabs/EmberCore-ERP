import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_list_filter_helpers.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';

import 'firebase_test_setup.dart';

CustomersRecord _customer({
  required String name,
  bool isCredit = false,
  String phone = '',
  String email = '',
  String customerId = '',
  String uen = '',
}) {
  return CustomersRecord.getDocumentFromData(
    {
      'name': name,
      'phone': phone,
      'email': email,
      'customer_id': customerId,
      'uen': uen,
      'billing_address': '123 Test Street',
      'is_credit_customer': isCredit,
    },
    FirebaseFirestore.instance.collection('customers').doc(name),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('applyCustomerListFilters', () {
    test('returns all customers when filter is all and search is empty', () {
      final customers = [
        _customer(name: 'Alice Tan', isCredit: true, phone: '91234567'),
        _customer(name: 'Bob Lim', customerId: 'C-100'),
        _customer(name: 'Carol Ong', isCredit: true, email: 'carol@shop.com'),
      ];

      final filtered = applyCustomerListFilters(
        customers: customers,
        searchQuery: '',
        creditFilter: CustomerListCreditFilter.all,
      );

      expect(filtered.map((c) => c.name), ['Alice Tan', 'Bob Lim', 'Carol Ong']);
    });

    test('keeps only credit customers', () {
      final customers = [
        _customer(name: 'Alice Tan', isCredit: true),
        _customer(name: 'Bob Lim'),
        _customer(name: 'Carol Ong', isCredit: true),
      ];

      final filtered = applyCustomerListFilters(
        customers: customers,
        searchQuery: '',
        creditFilter: CustomerListCreditFilter.credit,
      );

      expect(filtered.map((c) => c.name), ['Alice Tan', 'Carol Ong']);
    });

    test('keeps only non-credit customers', () {
      final customers = [
        _customer(name: 'Alice Tan', isCredit: true),
        _customer(name: 'Bob Lim'),
        _customer(name: 'Carol Ong', isCredit: true),
      ];

      final filtered = applyCustomerListFilters(
        customers: customers,
        searchQuery: '',
        creditFilter: CustomerListCreditFilter.nonCredit,
      );

      expect(filtered.map((c) => c.name), ['Bob Lim']);
    });

    test('applies search after credit filter', () {
      final customers = [
        _customer(name: 'Alice Tan', isCredit: true),
        _customer(name: 'Bob Lim'),
        _customer(name: 'Carol Ong', isCredit: true, email: 'carol@shop.com'),
      ];

      final filtered = applyCustomerListFilters(
        customers: customers,
        searchQuery: 'carol',
        creditFilter: CustomerListCreditFilter.credit,
      );

      expect(filtered.map((c) => c.name), ['Carol Ong']);
    });

    test('search matches customer id', () {
      final customers = [
        _customer(name: 'Alice Tan', isCredit: true),
        _customer(name: 'Bob Lim', customerId: 'C-100'),
        _customer(name: 'Carol Ong', isCredit: true),
      ];

      final filtered = applyCustomerListFilters(
        customers: customers,
        searchQuery: 'c-100',
        creditFilter: CustomerListCreditFilter.all,
      );

      expect(filtered.map((c) => c.name), ['Bob Lim']);
    });
  });
}
