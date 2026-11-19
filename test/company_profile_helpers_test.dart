import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/company_profile_helpers.dart';

void main() {
  test('normalizeCompanyWebsite accepts host and https URL', () {
    expect(
      normalizeCompanyWebsite('www.theflowerguy.sg'),
      'https://www.theflowerguy.sg',
    );
    expect(
      normalizeCompanyWebsite('https://www.theflowerguy.sg/products/a1'),
      'https://www.theflowerguy.sg',
    );
  });

  test('normalizeCompanyWebsite rejects empty and invalid values', () {
    expect(normalizeCompanyWebsite(''), isNull);
    expect(normalizeCompanyWebsite('not a url'), isNull);
    expect(normalizeCompanyWebsite('ftp://example.com'), isNull);
  });
}
