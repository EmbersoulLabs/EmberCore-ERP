import '/backend/schema/customers_record.dart';

/// Credit vs cash-account filter on the customer list.
enum CustomerListCreditFilter {
  all,
  credit,
  nonCredit,
}

bool customerMatchesSearchQuery(CustomersRecord customer, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return customer.name.toLowerCase().contains(normalized) ||
      customer.customerId.toLowerCase().contains(normalized) ||
      customer.phone.contains(normalized) ||
      customer.email.toLowerCase().contains(normalized) ||
      customer.billingAddress.toLowerCase().contains(normalized) ||
      customer.uen.toLowerCase().contains(normalized);
}

bool customerMatchesCreditFilter(
  CustomersRecord customer,
  CustomerListCreditFilter filter,
) {
  switch (filter) {
    case CustomerListCreditFilter.all:
      return true;
    case CustomerListCreditFilter.credit:
      return customer.isCreditCustomer;
    case CustomerListCreditFilter.nonCredit:
      return !customer.isCreditCustomer;
  }
}

List<CustomersRecord> applyCustomerListFilters({
  required List<CustomersRecord> customers,
  required String searchQuery,
  required CustomerListCreditFilter creditFilter,
}) {
  return customers
      .where((customer) => customerMatchesCreditFilter(customer, creditFilter))
      .where((customer) => customerMatchesSearchQuery(customer, searchQuery))
      .toList();
}

Set<String> visibleCustomerPaths(List<CustomersRecord> customers) =>
    customers.map((customer) => customer.reference.path).toSet();
