import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/register_user_service.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/company_provisioning_service.dart';
import '/backend/create_order_service.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ManualCompanyCreationInput {
  const ManualCompanyCreationInput({
    required this.companyName,
    this.companyPhone = '',
    this.companyAddress = '',
    this.companyUen = '',
    this.createDirector = false,
    this.directorName = '',
    this.directorEmail = '',
    this.directorPhone = '',
    this.directorPassword = '',
  });

  final String companyName;
  final String companyPhone;
  final String companyAddress;
  final String companyUen;
  final bool createDirector;
  final String directorName;
  final String directorEmail;
  final String directorPhone;
  final String directorPassword;
}

class ManualCompanyCreationResult {
  const ManualCompanyCreationResult({
    required this.success,
    this.errorMessage,
    this.companyRef,
    this.signedOutSuperAdminSession = false,
    this.directorUserUid,
  });

  final bool success;
  final String? errorMessage;
  final DocumentReference? companyRef;
  final bool signedOutSuperAdminSession;
  final String? directorUserUid;
}

Future<ManualCompanyCreationResult> createCompanyManually({
  required BuildContext context,
  required ManualCompanyCreationInput input,
}) async {
  if (!isSuperAdminRole(currentViewerRole())) {
    return const ManualCompanyCreationResult(
      success: false,
      errorMessage: 'Only super admins can create companies.',
    );
  }

  final companyName = input.companyName.trim();
  if (companyName.isEmpty) {
    return const ManualCompanyCreationResult(
      success: false,
      errorMessage: 'Company name is required.',
    );
  }

  if (input.createDirector) {
    if (input.directorName.trim().isEmpty) {
      return const ManualCompanyCreationResult(
        success: false,
        errorMessage: 'Director name is required.',
      );
    }
    if (input.directorEmail.trim().isEmpty) {
      return const ManualCompanyCreationResult(
        success: false,
        errorMessage: 'Director email is required.',
      );
    }
    if (input.directorPassword.length < 6) {
      return const ManualCompanyCreationResult(
        success: false,
        errorMessage: 'Director password must be at least 6 characters.',
      );
    }
  }

  try {
    final companyRef = await provisionNewCompanyDocument(
      companyName: companyName,
      companyPhone: input.companyPhone,
      companyAddress: input.companyAddress,
      companyUen: input.companyUen,
    );

    if (!input.createDirector) {
      return ManualCompanyCreationResult(
        success: true,
        companyRef: companyRef,
      );
    }

    if (!context.mounted) {
      return ManualCompanyCreationResult(
        success: false,
        errorMessage: 'Company created but director setup was cancelled.',
        companyRef: companyRef,
      );
    }

    final registerResult = await registerStaffUser(
      context: context,
      email: input.directorEmail.trim(),
      password: input.directorPassword,
      name: input.directorName.trim(),
      role: UserRole.director,
      companyRef: companyRef,
      phoneNumber: input.directorPhone.trim().isEmpty
          ? null
          : input.directorPhone.trim(),
    );

    if (!registerResult.success) {
      return ManualCompanyCreationResult(
        success: false,
        errorMessage: registerResult.errorMessage ??
            'Company was created but the director account could not be added.',
        companyRef: companyRef,
      );
    }

    return ManualCompanyCreationResult(
      success: true,
      companyRef: companyRef,
      signedOutSuperAdminSession: registerResult.signedOutAdminSession,
      directorUserUid: registerResult.createdUserUid,
    );
  } catch (error) {
    return ManualCompanyCreationResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}
