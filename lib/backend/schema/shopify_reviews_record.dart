import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ShopifyReviewsRecord extends FirestoreRecord {
  ShopifyReviewsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _companyId;
  String get companyId => _companyId ?? '';

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;

  String? _source;
  String get source => _source ?? '';

  String? _shopifyOrderId;
  String get shopifyOrderId => _shopifyOrderId ?? '';

  String? _shopifyOrderName;
  String get shopifyOrderName => _shopifyOrderName ?? '';

  int? _shopifyOrderNumber;
  int get shopifyOrderNumber => _shopifyOrderNumber ?? 0;

  String? _financialStatus;
  String get financialStatus => _financialStatus ?? '';

  String? _currency;
  String get currency => _currency ?? '';

  double? _totalPrice;
  double get totalPrice => _totalPrice ?? 0;

  String? _customerName;
  String get customerName => _customerName ?? '';

  String? _recipientName;
  String get recipientName => _recipientName ?? '';

  String? _shippingAddress;
  String get shippingAddress => _shippingAddress ?? '';

  String? _billingAddress;
  String get billingAddress => _billingAddress ?? '';

  String? _region;
  String get region => _region ?? '';

  String? _postalCode;
  String get postalCode => _postalCode ?? '';

  String? _phone;
  String get phone => _phone ?? '';

  String? _senderPhone;
  String get senderPhone => _senderPhone ?? '';

  String? _recipientPhone;
  String get recipientPhone => _recipientPhone ?? '';

  String? _notes;
  String get notes => _notes ?? '';

  String? _remarks;
  String get remarks => _remarks ?? '';

  List<String>? _addons;
  List<String> get addons => _addons ?? const [];

  String? _deliveryMethod;
  String get deliveryMethod => _deliveryMethod ?? '';

  String? _cardMessage;
  String get cardMessage => _cardMessage ?? '';

  DateTime? _deliveryDate;
  DateTime? get deliveryDate => _deliveryDate;

  String? _deliveryTimeSlot;
  String get deliveryTimeSlot => _deliveryTimeSlot ?? '';

  String? _orderType;
  String get orderType => _orderType ?? '';

  List<dynamic>? _lineItems;
  List<dynamic> get lineItems => _lineItems ?? const [];

  String? _itemSummary;
  String get itemSummary => _itemSummary ?? '';

  DateTime? _createdAtShopify;
  DateTime? get createdAtShopify => _createdAtShopify;

  DateTime? _paidAt;
  DateTime? get paidAt => _paidAt;

  DateTime? _receivedAt;
  DateTime? get receivedAt => _receivedAt;

  String? _reviewStatus;
  String get reviewStatus => _reviewStatus ?? '';

  String? _quarantineReason;
  String get quarantineReason => _quarantineReason ?? '';

  DateTime? _approvedAt;
  DateTime? get approvedAt => _approvedAt;

  String? _approvedBy;
  String get approvedBy => _approvedBy ?? '';

  String? _approvedByName;
  String get approvedByName => _approvedByName ?? '';

  String? _officialOrderId;
  String get officialOrderId => _officialOrderId ?? '';

  DocumentReference? _officialOrderRef;
  DocumentReference? get officialOrderRef => _officialOrderRef;

  void _initializeFields() {
    _companyId = snapshotData['companyId'] as String?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    _source = snapshotData['source'] as String?;
    _shopifyOrderId = snapshotData['shopifyOrderId'] as String?;
    _shopifyOrderName = snapshotData['shopifyOrderName'] as String?;
    _shopifyOrderNumber = castToType<int>(snapshotData['shopifyOrderNumber']);
    _financialStatus = snapshotData['financialStatus'] as String?;
    _currency = snapshotData['currency'] as String?;
    _totalPrice = castToType<double>(snapshotData['totalPrice']);
    _customerName = snapshotData['customerName'] as String?;
    _recipientName = snapshotData['recipientName'] as String?;
    _shippingAddress = snapshotData['shippingAddress'] as String?;
    _billingAddress = snapshotData['billingAddress'] as String?;
    _region = snapshotData['region'] as String?;
    _postalCode = snapshotData['postalCode'] as String?;
    _phone = snapshotData['phone'] as String?;
    _senderPhone = snapshotData['senderPhone'] as String?;
    _recipientPhone = snapshotData['recipientPhone'] as String?;
    _notes = snapshotData['notes'] as String?;
    _remarks = snapshotData['remarks'] as String?;
    final rawAddons = snapshotData['addons'];
    _addons = rawAddons is List
        ? rawAddons
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false)
        : null;
    _deliveryMethod = snapshotData['deliveryMethod'] as String?;
    _cardMessage = snapshotData['cardMessage'] as String?;
    _deliveryDate = snapshotData['deliveryDate'] as DateTime?;
    _deliveryTimeSlot = snapshotData['deliveryTimeSlot'] as String?;
    _orderType = snapshotData['orderType'] as String?;
    _lineItems = snapshotData['lineItems'] as List<dynamic>?;
    _itemSummary = snapshotData['itemSummary'] as String?;
    _createdAtShopify = snapshotData['createdAtShopify'] as DateTime?;
    _paidAt = snapshotData['paidAt'] as DateTime?;
    _receivedAt = snapshotData['receivedAt'] as DateTime?;
    _reviewStatus = snapshotData['reviewStatus'] as String?;
    _quarantineReason = snapshotData['quarantineReason'] as String?;
    _approvedAt = snapshotData['approvedAt'] as DateTime?;
    _approvedBy = snapshotData['approvedBy'] as String?;
    _approvedByName = snapshotData['approvedByName'] as String?;
    _officialOrderId = snapshotData['officialOrderId'] as String?;
    _officialOrderRef = snapshotData['officialOrderRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('shopify_reviews');

  static Stream<ShopifyReviewsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ShopifyReviewsRecord.fromSnapshot(s));

  static Future<ShopifyReviewsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ShopifyReviewsRecord.fromSnapshot(s));

  static ShopifyReviewsRecord fromSnapshot(DocumentSnapshot snapshot) {
    final raw = snapshot.data();
    return ShopifyReviewsRecord._(
      snapshot.reference,
      mapFromFirestore(
        raw != null ? raw as Map<String, dynamic> : <String, dynamic>{},
      ),
    );
  }

  static ShopifyReviewsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ShopifyReviewsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ShopifyReviewsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ShopifyReviewsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

class ShopifyReviewsRecordDocumentEquality
    implements Equality<ShopifyReviewsRecord> {
  const ShopifyReviewsRecordDocumentEquality();

  @override
  bool equals(ShopifyReviewsRecord? e1, ShopifyReviewsRecord? e2) =>
      e1?.reference == e2?.reference;

  @override
  int hash(ShopifyReviewsRecord? e) => e?.reference.hashCode ?? 0;

  @override
  bool isValidKey(Object? o) => o is ShopifyReviewsRecord;
}
