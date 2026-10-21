import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CompaniesRecord extends FirestoreRecord {
  CompaniesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Company_id" field.
  String? _companyId;
  String get companyId => _companyId ?? '';
  bool hasCompanyId() => _companyId != null;

  // "Company_name" field.
  String? _companyName;
  String get companyName => _companyName ?? '';
  bool hasCompanyName() => _companyName != null;

  // "Company_phone" field.
  String? _companyPhone;
  String get companyPhone => _companyPhone ?? '';
  bool hasCompanyPhone() => _companyPhone != null;

  // "company_address" field.
  String? _companyAddress;
  String get companyAddress => _companyAddress ?? '';
  bool hasCompanyAddress() => _companyAddress != null;

  // "company_uen" field.
  String? _companyUen;
  String get companyUen => _companyUen ?? '';
  bool hasCompanyUen() => _companyUen != null;

  // "is_active" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "logo" field.
  String? _logo;
  String get logo => _logo ?? '';
  bool hasLogo() => _logo != null;

  // SaaS subscription fields (segment E).
  String? _planTier;
  String get planTier => _planTier ?? '';
  bool hasPlanTier() => _planTier != null;

  String? _billingCountry;
  String get billingCountry => _billingCountry ?? '';
  bool hasBillingCountry() => _billingCountry != null;

  String? _subscriptionStatus;
  String get subscriptionStatus => _subscriptionStatus ?? '';
  bool hasSubscriptionStatus() => _subscriptionStatus != null;

  DateTime? _trialEndsAt;
  DateTime? get trialEndsAt => _trialEndsAt;
  bool hasTrialEndsAt() => _trialEndsAt != null;

  DateTime? _currentPeriodEnd;
  DateTime? get currentPeriodEnd => _currentPeriodEnd;
  bool hasCurrentPeriodEnd() => _currentPeriodEnd != null;

  String? _stripeCustomerId;
  String get stripeCustomerId => _stripeCustomerId ?? '';
  bool hasStripeCustomerId() => _stripeCustomerId != null;

  String? _stripeSubscriptionId;
  String get stripeSubscriptionId => _stripeSubscriptionId ?? '';
  bool hasStripeSubscriptionId() => _stripeSubscriptionId != null;

  int? _maxStaffSeats;
  int get maxStaffSeats => _maxStaffSeats ?? 0;
  bool hasMaxStaffSeats() => _maxStaffSeats != null;

  int? _maxOrdersPerMonth;
  int get maxOrdersPerMonth => _maxOrdersPerMonth ?? 0;
  bool hasMaxOrdersPerMonth() => _maxOrdersPerMonth != null;

  // Multi-branch org fields (Business plan).
  String? _companyKind;
  String get companyKind => _companyKind ?? '';
  bool hasCompanyKind() => _companyKind != null;

  String? _orgId;
  String get orgId => _orgId ?? '';
  bool hasOrgId() => _orgId != null;

  String? _branchCode;
  String get branchCode => _branchCode ?? '';
  bool hasBranchCode() => _branchCode != null;

  // "parent_org_ref" field.
  DocumentReference? _parentOrgRef;
  DocumentReference? get parentOrgRef => _parentOrgRef;
  bool hasParentOrgRef() => _parentOrgRef != null;

  void _initializeFields() {
    _companyId = snapshotData['Company_id'] as String?;
    _companyName = snapshotData['Company_name'] as String?;
    _companyPhone = snapshotData['Company_phone'] as String?;
    _companyAddress = snapshotData['company_address'] as String?;
    _companyUen = snapshotData['company_uen'] as String?;
    _isActive = snapshotData['is_active'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _logo = snapshotData['logo'] as String?;
    _planTier = snapshotData['plan_tier'] as String?;
    _billingCountry = snapshotData['billing_country'] as String?;
    _subscriptionStatus = snapshotData['subscription_status'] as String?;
    _trialEndsAt = snapshotData['trial_ends_at'] as DateTime?;
    _currentPeriodEnd = snapshotData['current_period_end'] as DateTime?;
    _stripeCustomerId = snapshotData['stripe_customer_id'] as String?;
    _stripeSubscriptionId = snapshotData['stripe_subscription_id'] as String?;
    _maxStaffSeats = castToType<int>(snapshotData['max_staff_seats']);
    _maxOrdersPerMonth = castToType<int>(snapshotData['max_orders_per_month']);
    _companyKind = snapshotData['company_kind'] as String?;
    _orgId = snapshotData['org_id'] as String?;
    _branchCode = snapshotData['branch_code'] as String?;
    _parentOrgRef = snapshotData['parent_org_ref'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Companies');

  static Stream<CompaniesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CompaniesRecord.fromSnapshot(s));

  static Future<CompaniesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CompaniesRecord.fromSnapshot(s));

  static CompaniesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CompaniesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CompaniesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CompaniesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CompaniesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CompaniesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCompaniesRecordData({
  String? companyId,
  String? companyName,
  String? companyPhone,
  String? companyAddress,
  String? companyUen,
  bool? isActive,
  DateTime? createdAt,
  String? logo,
  String? planTier,
  String? subscriptionStatus,
  DateTime? trialEndsAt,
  DateTime? currentPeriodEnd,
  String? stripeCustomerId,
  String? stripeSubscriptionId,
  int? maxStaffSeats,
  int? maxOrdersPerMonth,
  String? companyKind,
  String? orgId,
  String? branchCode,
  DocumentReference? parentOrgRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Company_id': companyId,
      'Company_name': companyName,
      'Company_phone': companyPhone,
      'company_address': companyAddress,
      'company_uen': companyUen,
      'is_active': isActive,
      'created_at': createdAt,
      'logo': logo,
      'plan_tier': planTier,
      'subscription_status': subscriptionStatus,
      'trial_ends_at': trialEndsAt,
      'current_period_end': currentPeriodEnd,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'max_staff_seats': maxStaffSeats,
      'max_orders_per_month': maxOrdersPerMonth,
      'company_kind': companyKind,
      'org_id': orgId,
      'branch_code': branchCode,
      'parent_org_ref': parentOrgRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class CompaniesRecordDocumentEquality implements Equality<CompaniesRecord> {
  const CompaniesRecordDocumentEquality();

  @override
  bool equals(CompaniesRecord? e1, CompaniesRecord? e2) {
    return e1?.companyId == e2?.companyId &&
        e1?.companyName == e2?.companyName &&
        e1?.companyPhone == e2?.companyPhone &&
        e1?.companyAddress == e2?.companyAddress &&
        e1?.companyUen == e2?.companyUen &&
        e1?.isActive == e2?.isActive &&
        e1?.createdAt == e2?.createdAt &&
        e1?.logo == e2?.logo &&
        e1?.planTier == e2?.planTier &&
        e1?.subscriptionStatus == e2?.subscriptionStatus &&
        e1?.trialEndsAt == e2?.trialEndsAt &&
        e1?.currentPeriodEnd == e2?.currentPeriodEnd &&
        e1?.stripeCustomerId == e2?.stripeCustomerId &&
        e1?.stripeSubscriptionId == e2?.stripeSubscriptionId &&
        e1?.maxStaffSeats == e2?.maxStaffSeats &&
        e1?.maxOrdersPerMonth == e2?.maxOrdersPerMonth &&
        e1?.companyKind == e2?.companyKind &&
        e1?.orgId == e2?.orgId &&
        e1?.branchCode == e2?.branchCode &&
        e1?.parentOrgRef == e2?.parentOrgRef;
  }

  @override
  int hash(CompaniesRecord? e) => const ListEquality().hash([
        e?.companyId,
        e?.companyName,
        e?.companyPhone,
        e?.companyAddress,
        e?.companyUen,
        e?.isActive,
        e?.createdAt,
        e?.logo,
        e?.planTier,
        e?.subscriptionStatus,
        e?.trialEndsAt,
        e?.currentPeriodEnd,
        e?.stripeCustomerId,
        e?.stripeSubscriptionId,
        e?.maxStaffSeats,
        e?.maxOrdersPerMonth,
        e?.companyKind,
        e?.orgId,
        e?.branchCode,
        e?.parentOrgRef,
      ]);

  @override
  bool isValidKey(Object? o) => o is CompaniesRecord;
}
