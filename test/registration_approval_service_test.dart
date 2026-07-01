import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/backend/registration_approval_service.dart';
import 'package:tfg_vday/backend/user_registration_request_helpers.dart';

void main() {
  group('UserRegistrationRequest.fromSnapshot', () {
    test('converts Firestore Timestamp fields to DateTime', () {
      final created = DateTime(2026, 6, 27, 11, 36, 44);
      final snapshot = _FakeSnapshot(
        id: 'test@example.com',
        data: {
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

      final request = UserRegistrationRequest.fromSnapshot(snapshot);

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
}

class _FakeSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeSnapshot({required this.id, required Map<String, dynamic> data})
      : _data = data;

  @override
  final String id;

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
