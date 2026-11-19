import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/backend/order_ready_by_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/users_record.dart';

import 'firebase_test_setup.dart';

UsersRecord _user({
  required String id,
  required UserRole role,
  String? name,
  bool active = true,
  String companyId = 'c1',
}) {
  return UsersRecord.getDocumentFromData(
    {
      'role': role,
      'uid': id,
      'name': name ?? id,
      'is_active': active,
      'companyRef': FirebaseFirestore.instance.doc('Companies/$companyId'),
    },
    FirebaseFirestore.instance.collection('users').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('same staff key always maps to the same color', () {
    final first = readyByStaffColor('alice');
    final second = readyByStaffColor('alice');
    final other = readyByStaffColor('bob');
    expect(first, second);
    expect(first, isNot(other));
    expect(kReadyByStaffColors, contains(first));
  });

  test('empty staff key uses the unassigned color', () {
    expect(readyByStaffColor(''), const Color(0xFF607D8B));
  });

  test('florists and managers are assignable; drivers are not', () {
    expect(
      isReadyByAssignableStaff(
        _user(id: 'f1', role: UserRole.florist),
        companyId: 'c1',
      ),
      isTrue,
    );
    expect(
      isReadyByAssignableStaff(
        _user(id: 'm1', role: UserRole.manager),
        companyId: 'c1',
      ),
      isTrue,
    );
    expect(
      isReadyByAssignableStaff(
        _user(id: 'd1', role: UserRole.driver),
        companyId: 'c1',
      ),
      isFalse,
    );
    expect(
      isReadyByAssignableStaff(
        _user(id: 'f2', role: UserRole.florist, active: false),
        companyId: 'c1',
      ),
      isFalse,
    );
  });

  test('canAssignReadyBy follows status permission but excludes drivers', () {
    expect(canAssignReadyBy(UserRole.florist), isTrue);
    expect(canAssignReadyBy(UserRole.senior_florist), isTrue);
    expect(canAssignReadyBy(UserRole.manager), isTrue);
    expect(canAssignReadyBy(UserRole.driver), isFalse);
    expect(canAssignReadyBy(UserRole.hr), isFalse);
  });

  test('readyByStaffName prefers the live staff display name', () {
    final alice = _user(id: 'alice', role: UserRole.florist, name: 'Alice Tan');
    final lookup = readyByStaffLookup([alice]);
    expect(
      readyByStaffName(alice.reference, staffByPath: lookup),
      'Alice Tan',
    );
    expect(
      readyByStaffName(null, staffByPath: lookup),
      isNull,
    );
  });
}
