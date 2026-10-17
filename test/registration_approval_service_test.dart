import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/backend/registration_approval_service.dart';
import 'package:tfg_vday/backend/user_registration_request_helpers.dart';

void main() {
  group('UserRegistrationRequest.fromFirestoreData', () {
    test('converts Firestore Timestamp fields to DateTime', () {
      final created = DateTime(2026, 6, 27, 11, 36, 44);
      final request = UserRegistrationRequest.fromFirestoreData(
        id: 'test@example.com',
        rawData: {
          'email': 'test@example.com',
          'name': 'Test User',
          'phone': '+60123456789',
          'account_type': 'company',
          'status': 'pending',
          'created_time': Timestamp.fromDate(created),
          'birthday': Timestamp.fromDate(DateTime(1990, 1, 1)),
          'company_name': 'Acme Co',
        },
      );

      expect(request.id, 'test@example.com');
      expect(request.email, 'test@example.com');
      expect(request.name, 'Test User');
      expect(request.accountType, UserSignupAccountType.company);
      expect(request.status, RegistrationRequestStatus.pending);
      expect(request.createdTime, created);
      expect(request.birthday, DateTime(1990, 1, 1));
      expect(request.companyName, 'Acme Co');
    });
  });

  group('validateUserRegistrationInput', () {
    test('accepts Malaysia and Singapore', () {
      expect(
        validateUserRegistrationInput(
          name: 'A',
          phone: '1',
          email: 'a@b.com',
          accountType: UserSignupAccountType.private,
          country: 'MY',
        ),
        isNull,
      );
      expect(
        validateUserRegistrationInput(
          name: 'A',
          phone: '1',
          email: 'a@b.com',
          accountType: UserSignupAccountType.company,
          companyName: 'Shop',
          country: 'sg',
        ),
        isNull,
      );
    });

    test('rejects an unsupported country and a duplicate-prone empty company', () {
      expect(
        validateUserRegistrationInput(
          name: 'A',
          phone: '1',
          email: 'a@b.com',
          accountType: UserSignupAccountType.private,
          country: 'US',
        ),
        isNotNull,
      );
      expect(
        validateUserRegistrationInput(
          name: '',
          phone: '1',
          email: 'not-an-email',
          accountType: UserSignupAccountType.company,
          country: 'MY',
        ),
        isNotNull,
      );
    });
  });
}
