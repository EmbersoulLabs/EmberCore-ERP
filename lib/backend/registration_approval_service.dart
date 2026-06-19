import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/register_user_service.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/staff_role_helpers.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/user_registration_request_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/platform/platform_config_service.dart';
import '/platform/tenant_platform_config.dart';
import 'package:flutter/material.dart';

enum RegistrationRequestStatus {
  pending,
  approved,
  rejected,
}

RegistrationRequestStatus? parseRegistrationRequestStatus(String? raw) {
  switch (raw) {
    case 'pending':
      return RegistrationRequestStatus.pending;
    case 'approved':
      return RegistrationRequestStatus.approved;
    case 'rejected':
      return RegistrationRequestStatus.rejected;
    default:
      return null;
  }
}

String registrationRequestStatusKey(RegistrationRequestStatus status) {
  switch (status) {
    case RegistrationRequestStatus.pending:
      return 'pending';
    case RegistrationRequestStatus.approved:
      return 'approved';
    case RegistrationRequestStatus.rejected:
      return 'rejected';
  }
}

class UserRegistrationRequest {
  const UserRegistrationRequest({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.accountType,
    required this.status,
    this.createdTime,
    this.birthday,
    this.companyName,
    this.companyUen,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companyLogoUrl,
    this.rejectionNote,
    this.reviewedAt,
    this.reviewedByUid,
    this.provisionedCompanyRef,
    this.provisionedUserUid,
  });

  final String id;
  final String email;
  final String name;
  final String phone;
  final UserSignupAccountType accountType;
  final RegistrationRequestStatus status;
  final DateTime? createdTime;
  final DateTime? birthday;
  final String? companyName;
  final String? companyUen;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyLogoUrl;
  final String? rejectionNote;
  final DateTime? reviewedAt;
  final String? reviewedByUid;
  final DocumentReference? provisionedCompanyRef;
  final String? provisionedUserUid;

  bool get isPending => status == RegistrationRequestStatus.pending;
  bool get isCompanyAccount =>
      accountType == UserSignupAccountType.company;

  static UserRegistrationRequest fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return UserRegistrationRequest(
      id: snapshot.id,
      email: data['email']?.toString() ?? snapshot.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      accountType: parseUserSignupAccountType(
            data['account_type']?.toString(),
          ) ??
          UserSignupAccountType.private,
      status: parseRegistrationRequestStatus(data['status']?.toString()) ??
          RegistrationRequestStatus.pending,
      createdTime: data['created_time'] as DateTime?,
      birthday: data['birthday'] as DateTime?,
      companyName: data['company_name']?.toString(),
      companyUen: data['company_uen']?.toString(),
      companyAddress: data['company_address']?.toString(),
      companyPhone: data['company_phone']?.toString(),
      companyEmail: data['company_email']?.toString(),
      companyLogoUrl: data['company_logo_url']?.toString(),
      rejectionNote: data['rejection_note']?.toString(),
      reviewedAt: data['reviewed_at'] as DateTime?,
      reviewedByUid: data['reviewed_by_uid']?.toString(),
      provisionedCompanyRef:
          data['provisioned_company_ref'] as DocumentReference?,
      provisionedUserUid: data['provisioned_user_uid']?.toString(),
    );
  }
}

DocumentReference<Map<String, dynamic>> registrationRequestDocRef(String id) =>
    FirebaseFirestore.instance
        .collection(userRegistrationRequestsCollection)
        .doc(id);

Stream<List<UserRegistrationRequest>> streamRegistrationRequests({
  RegistrationRequestStatus? statusFilter,
  int limit = 200,
}) {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection(userRegistrationRequestsCollection)
      .orderBy('created_time', descending: true)
      .limit(limit);

  if (statusFilter != null) {
    query = query.where(
      'status',
      isEqualTo: registrationRequestStatusKey(statusFilter),
    );
  }

  return query.snapshots().map(
        (snapshot) => snapshot.docs
            .map(UserRegistrationRequest.fromSnapshot)
            .toList(growable: false),
      );
}

Future<List<UserRegistrationRequest>> loadRegistrationRequestsOnce({
  RegistrationRequestStatus? statusFilter,
  int limit = 200,
}) async {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection(userRegistrationRequestsCollection)
      .orderBy('created_time', descending: true)
      .limit(limit);

  if (statusFilter != null) {
    query = query.where(
      'status',
      isEqualTo: registrationRequestStatusKey(statusFilter),
    );
  }

  final snapshot = await query.get();
  return snapshot.docs
      .map(UserRegistrationRequest.fromSnapshot)
      .toList(growable: false);
}

class RegistrationApprovalResult {
  const RegistrationApprovalResult({
    required this.success,
    this.errorMessage,
    this.signedOutSuperAdminSession = false,
    this.companyRef,
    this.userUid,
  });

  final bool success;
  final String? errorMessage;
  final bool signedOutSuperAdminSession;
  final DocumentReference? companyRef;
  final String? userUid;
}

class RegistrationRejectionResult {
  const RegistrationRejectionResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

Future<void> initializeNewTenantFirestore(DocumentReference companyRef) async {
  final companyId = canonicalCompanyId(companyRef.id);
  final now = getCurrentTimestamp;

  await FirebaseFirestore.instance
      .collection(PlatformConfigService.collectionName)
      .doc(companyId)
      .set(
        TenantPlatformConfig.genericDefaults().toFirestore(),
        SetOptions(merge: true),
      );

  await FirebaseFirestore.instance.collection('staff_roles').doc(companyId).set(
    {
      'companyRef': companyRef,
      'roles': defaultCompanyStaffRoles.map((role) => role.serialize()).toList(),
      'updated_time': now,
    },
    SetOptions(merge: true),
  );

  await FirebaseFirestore.instance
      .collection('role_permissions')
      .doc(companyId)
      .set(
    {
      'companyRef': companyRef,
      'roles': <String, dynamic>{},
      'updated_time': now,
    },
    SetOptions(merge: true),
  );
}

Future<DocumentReference> createCompanyFromRegistrationRequest(
  UserRegistrationRequest request,
) async {
  final companyRef = CompaniesRecord.collection.doc();
  final companyId = companyRef.id;
  final displayName = request.isCompanyAccount
      ? (request.companyName ?? '').trim()
      : request.name.trim();

  await companyRef.set(
    createCompaniesRecordData(
      companyId: companyId,
      companyName: displayName.isEmpty ? request.name.trim() : displayName,
      companyPhone: request.isCompanyAccount
          ? (request.companyPhone ?? request.phone).trim()
          : request.phone.trim(),
      companyAddress: (request.companyAddress ?? '').trim(),
      companyUen: (request.companyUen ?? '').trim(),
      isActive: true,
      createdAt: getCurrentTimestamp,
      logo: (request.companyLogoUrl ?? '').trim().isEmpty
          ? null
          : request.companyLogoUrl!.trim(),
    ),
  );

  await initializeNewTenantFirestore(companyRef);
  return companyRef;
}

Future<RegistrationRejectionResult> rejectRegistrationRequest({
  required String requestId,
  required String note,
}) async {
  if (!isSuperAdminRole(currentViewerRole())) {
    return const RegistrationRejectionResult(
      success: false,
      errorMessage: 'Only super admins can reject registration requests.',
    );
  }

  final trimmedNote = note.trim();
  if (trimmedNote.isEmpty) {
    return const RegistrationRejectionResult(
      success: false,
      errorMessage: 'Please enter a rejection reason.',
    );
  }

  final docRef = registrationRequestDocRef(requestId);
  try {
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      return const RegistrationRejectionResult(
        success: false,
        errorMessage: 'Registration request not found.',
      );
    }
    final request = UserRegistrationRequest.fromSnapshot(snapshot);
    if (!request.isPending) {
      return const RegistrationRejectionResult(
        success: false,
        errorMessage: 'This request is no longer pending.',
      );
    }

    await docRef.update({
      'status': registrationRequestStatusKey(
        RegistrationRequestStatus.rejected,
      ),
      'rejection_note': trimmedNote,
      'reviewed_at': FieldValue.serverTimestamp(),
      'reviewed_by_uid': currentUserUid,
    });
    return const RegistrationRejectionResult(success: true);
  } catch (error) {
    return RegistrationRejectionResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}

Future<RegistrationApprovalResult> approveRegistrationRequest({
  required BuildContext context,
  required String requestId,
  required String initialPassword,
}) async {
  if (!isSuperAdminRole(currentViewerRole())) {
    return const RegistrationApprovalResult(
      success: false,
      errorMessage: 'Only super admins can approve registration requests.',
    );
  }

  if (initialPassword.length < 6) {
    return const RegistrationApprovalResult(
      success: false,
      errorMessage: 'Initial password must be at least 6 characters.',
    );
  }

  final docRef = registrationRequestDocRef(requestId);
  try {
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      return const RegistrationApprovalResult(
        success: false,
        errorMessage: 'Registration request not found.',
      );
    }

    final request = UserRegistrationRequest.fromSnapshot(snapshot);
    if (!request.isPending) {
      return const RegistrationApprovalResult(
        success: false,
        errorMessage: 'This request is no longer pending.',
      );
    }

    if (request.isCompanyAccount &&
        (request.companyName ?? '').trim().isEmpty) {
      return const RegistrationApprovalResult(
        success: false,
        errorMessage: 'Company name is missing on this request.',
      );
    }

    final companyRef = await createCompanyFromRegistrationRequest(request);

    final reviewerUid = currentUserUid;
    if (!context.mounted) {
      return RegistrationApprovalResult(
        success: false,
        errorMessage: 'Approval cancelled.',
        companyRef: companyRef,
      );
    }
    final registerResult = await registerStaffUser(
      context: context,
      email: request.email,
      password: initialPassword,
      name: request.name,
      role: UserRole.director,
      companyRef: companyRef,
      phoneNumber: request.phone,
    );

    if (!registerResult.success) {
      return RegistrationApprovalResult(
        success: false,
        errorMessage: registerResult.errorMessage ??
            'Could not create the director login.',
        companyRef: companyRef,
      );
    }

    await docRef.update({
      'status': registrationRequestStatusKey(
        RegistrationRequestStatus.approved,
      ),
      'reviewed_at': FieldValue.serverTimestamp(),
      'reviewed_by_uid': reviewerUid,
      'provisioned_company_ref': companyRef,
      if (registerResult.createdUserUid != null)
        'provisioned_user_uid': registerResult.createdUserUid,
      'initial_password_set': true,
    });

    return RegistrationApprovalResult(
      success: true,
      signedOutSuperAdminSession: registerResult.signedOutAdminSession,
      companyRef: companyRef,
      userUid: registerResult.createdUserUid,
    );
  } catch (error) {
    return RegistrationApprovalResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}
