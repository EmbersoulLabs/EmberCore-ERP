import 'package:cloud_functions/cloud_functions.dart';

const branchFunctionsRegion = 'asia-southeast1';

class BranchCreationInput {
  const BranchCreationInput({
    required this.headquartersCompanyId,
    required this.branchName,
    this.branchPhone = '',
    this.branchAddress = '',
    this.branchUen = '',
    this.branchCode = '',
  });

  final String headquartersCompanyId;
  final String branchName;
  final String branchPhone;
  final String branchAddress;
  final String branchUen;
  final String branchCode;
}

class BranchCreationResult {
  const BranchCreationResult({
    required this.success,
    this.branchId,
    this.errorMessage,
  });

  final bool success;
  final String? branchId;
  final String? errorMessage;
}

Future<BranchCreationResult> createBranchViaCallable(
  BranchCreationInput input,
) async {
  try {
    final callable = FirebaseFunctions.instanceFor(
      region: branchFunctionsRegion,
    ).httpsCallable('createBranch');
    final response = await callable.call<Map<String, dynamic>>({
      'headquartersCompanyId': input.headquartersCompanyId,
      'branchName': input.branchName.trim(),
      'branchPhone': input.branchPhone.trim(),
      'branchAddress': input.branchAddress.trim(),
      'branchUen': input.branchUen.trim(),
      'branchCode': input.branchCode.trim(),
    });
    final data = Map<String, dynamic>.from(response.data);
    return BranchCreationResult(
      success: data['success'] == true,
      branchId: data['branchId']?.toString(),
    );
  } catch (error) {
    return BranchCreationResult(
      success: false,
      errorMessage: describeBranchCallableError(error),
    );
  }
}

String describeBranchCallableError(Object error) {
  if (error is FirebaseFunctionsException) {
    return error.message ?? error.code;
  }
  return error.toString();
}
