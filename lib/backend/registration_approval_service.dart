import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/staff_role_helpers.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/user_registration_request_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/platform/platform_config_service.dart';
import '/platform/tenant_platform_config.dart';

/// Cloud Functions region for `approveRegistrationRequest` (see `firebase/functions`).
const _functionsRegion = 'asia-southeast1';

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

  static UserRegistrationRequest fromFirestoreData({
    required String id,
    required Map<String, dynamic> rawData,
  }) {
    final data = mapFromFirestore(rawData);
    return UserRegistrationRequest(
      id: id,
      email: data['email']?.toString() ?? id,
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

  static UserRegistrationRequest fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return fromFirestoreData(
      id: snapshot.id,
      rawData: snapshot.data() ?? {},
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
    this.passwordResetLink,
  });

  final bool success;
  final String? errorMessage;

  /// Always false for server-side approval; kept for API compatibility with the
  /// legacy client-side flow that re-authenticated the superadmin.
  final bool signedOutSuperAdminSession;
  final DocumentReference? companyRef;
  final String? userUid;

  /// Set when the director was provisioned without a password (the link lets
  /// them set their own). Null when an initial password was supplied.
  final String? passwordResetLink;
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

  try {
    final callable = FirebaseFunctions.instanceFor(region: _functionsRegion)
        .httpsCallable('rejectRegistrationRequest');
    await callable.call<Map<String, dynamic>>({
      'requestId': requestId,
      'note': trimmedNote,
    });
    return const RegistrationRejectionResult(success: true);
  } on FirebaseFunctionsException catch (error) {
    return RegistrationRejectionResult(
      success: false,
      errorMessage:
          error.message ?? 'Could not reject this registration request.',
    );
  } catch (error) {
    return RegistrationRejectionResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}

/// Records first-login activation for a director provisioned by approval.
/// Existing accounts without the pending flag are left unchanged.
Future<void> recordDirectorFirstLogin() async {
  try {
    final callable = FirebaseFunctions.instanceFor(region: _functionsRegion)
        .httpsCallable('recordDirectorFirstLogin');
    await callable.call();
  } catch (_) {
    // Login must succeed even if this stamp is delayed.
  }
}

/// Approves a registration request by invoking the `approveRegistrationRequest`
/// Cloud Function. The function provisions the tenant + director Auth user with
/// the Admin SDK, so the calling superadmin's session is never disturbed.
///
/// [initialPassword] is optional: when blank, the director is provisioned
/// passwordless and a password-reset link is returned in
/// [RegistrationApprovalResult.passwordResetLink]; when provided it must be at
/// least 6 characters.
Future<RegistrationApprovalResult> approveRegistrationRequest({
  required String requestId,
  String initialPassword = '',
}) async {
  if (!isSuperAdminRole(currentViewerRole())) {
    return const RegistrationApprovalResult(
      success: false,
      errorMessage: 'Only super admins can approve registration requests.',
    );
  }

  if (initialPassword.isNotEmpty && initialPassword.length < 6) {
    return const RegistrationApprovalResult(
      success: false,
      errorMessage: 'Initial password must be at least 6 characters.',
    );
  }

  try {
    final callable = FirebaseFunctions.instanceFor(region: _functionsRegion)
        .httpsCallable('approveRegistrationRequest');
    final response = await callable.call<Map<String, dynamic>>({
      'requestId': requestId,
      if (initialPassword.isNotEmpty) 'initialPassword': initialPassword,
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    final companyPath = data['companyPath']?.toString();
    final resetLink = data['passwordResetLink']?.toString();
    return RegistrationApprovalResult(
      success: true,
      companyRef: companyPath != null && companyPath.isNotEmpty
          ? FirebaseFirestore.instance.doc(companyPath)
          : null,
      userUid: data['userUid']?.toString(),
      passwordResetLink: (resetLink == null || resetLink.isEmpty)
          ? null
          : resetLink,
    );
  } on FirebaseFunctionsException catch (error) {
    return RegistrationApprovalResult(
      success: false,
      errorMessage:
          error.message ?? 'Could not approve this registration request.',
    );
  } catch (error) {
    return RegistrationApprovalResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}
