import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/role_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_list_helpers.dart';

/// Distinct colors so the same staff always looks the same on the order list.
const kReadyByStaffColors = <Color>[
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFFC62828),
  Color(0xFF00838F),
  Color(0xFFEF6C00),
  Color(0xFFAD1457),
  Color(0xFF4527A0),
  Color(0xFF00695C),
  Color(0xFF5D4037),
];

Color readyByStaffColor(String? staffKey) {
  final key = (staffKey ?? '').trim();
  if (key.isEmpty) {
    return const Color(0xFF607D8B);
  }
  return kReadyByStaffColors[key.hashCode.abs() % kReadyByStaffColors.length];
}

String readyByStaffKey(UsersRecord user) =>
    user.uid.trim().isNotEmpty ? user.uid.trim() : user.reference.id;

String readyByDisplayName(UsersRecord user) => userListDisplayName(user);

bool isReadyByAssignableRole(UserRole? role) {
  if (role == null || isDriverRole(role) || isSuperAdminRole(role)) {
    return false;
  }
  return isShopFloristRole(role) ||
      isManagerRole(role) ||
      isDirectorRole(role) ||
      isCompanyAdminRole(role);
}

bool isReadyByAssignableStaff(UsersRecord user, {String? companyId}) {
  if (!userIsActive(user) || !isReadyByAssignableRole(user.role)) {
    return false;
  }
  final scopedCompanyId = (companyId ?? TenantContext.instance.writeCompanyId)
      .trim();
  if (scopedCompanyId.isEmpty) {
    return true;
  }
  return canonicalCompanyId(user.companyRef?.id) ==
      canonicalCompanyId(scopedCompanyId);
}

List<UsersRecord> readyByAssignableStaff(
  Iterable<UsersRecord> users, {
  String? companyId,
  DocumentReference? includeRef,
}) {
  final scoped = users.where((user) {
    if (includeRef != null && user.reference.path == includeRef.path) {
      return isReadyByAssignableRole(user.role);
    }
    return isReadyByAssignableStaff(user, companyId: companyId);
  }).toList()
    ..sort(
      (a, b) => readyByDisplayName(a)
          .toLowerCase()
          .compareTo(readyByDisplayName(b).toLowerCase()),
    );
  return scoped;
}

Map<String, UsersRecord> readyByStaffLookup(Iterable<UsersRecord> users) => {
      for (final user in users) user.reference.path: user,
    };

String? readyByStaffName(
  DocumentReference? readyBy, {
  required Map<String, UsersRecord> staffByPath,
}) {
  if (readyBy == null) {
    return null;
  }
  final user = staffByPath[readyBy.path];
  if (user != null) {
    return readyByDisplayName(user);
  }
  return readyBy.id;
}

bool canAssignReadyBy(UserRole? role) =>
    canUpdateOrderStatus(role) && !isDriverRole(role);

Future<void> saveOrderReadyBy({
  required DocumentReference orderRef,
  required DocumentReference? staffRef,
}) {
  return orderRef.update({
    'ready_by': staffRef ?? FieldValue.delete(),
  });
}
