import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StaffNoticesRecord extends FirestoreRecord {
  StaffNoticesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  DocumentReference? _recipientUserRef;
  DocumentReference? get recipientUserRef => _recipientUserRef;
  bool hasRecipientUserRef() => _recipientUserRef != null;

  DocumentReference? _orderRef;
  DocumentReference? get orderRef => _orderRef;
  bool hasOrderRef() => _orderRef != null;

  String? _orderId;
  String get orderId => _orderId ?? '';
  bool hasOrderId() => _orderId != null;

  DateTime? _deliveryDate;
  DateTime? get deliveryDate => _deliveryDate;
  bool hasDeliveryDate() => _deliveryDate != null;

  String? _itemSummary;
  String get itemSummary => _itemSummary ?? '';
  bool hasItemSummary() => _itemSummary != null;

  String? _message;
  String get message => _message ?? '';
  bool hasMessage() => _message != null;

  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  DateTime? _readAt;
  DateTime? get readAt => _readAt;
  bool hasReadAt() => _readAt != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  String? _noticeTitle;
  String get noticeTitle => _noticeTitle ?? '';
  bool hasNoticeTitle() => _noticeTitle != null && _noticeTitle!.isNotEmpty;

  int? _prepDeliveryCount;
  int get prepDeliveryCount => _prepDeliveryCount ?? 0;
  bool hasPrepDeliveryCount() => _prepDeliveryCount != null;

  int? _prepPendingCount;
  int get prepPendingCount => _prepPendingCount ?? 0;
  bool hasPrepPendingCount() => _prepPendingCount != null;

  String? _prepStatus;
  String get prepStatus => _prepStatus ?? '';
  bool hasPrepStatus() => _prepStatus != null && _prepStatus!.isNotEmpty;

  void _initializeFields() {
    _type = snapshotData['type'] as String?;
    _recipientUserRef = snapshotData['recipient_user_ref'] as DocumentReference?;
    _orderRef = snapshotData['order_ref'] as DocumentReference?;
    _orderId = snapshotData['order_id'] as String?;
    _deliveryDate = snapshotData['delivery_date'] as DateTime?;
    _itemSummary = snapshotData['item_summary'] as String?;
    _message = snapshotData['message'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _readAt = snapshotData['read_at'] as DateTime?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    _noticeTitle = snapshotData['notice_title'] as String?;
    _prepDeliveryCount = (snapshotData['prep_delivery_count'] as num?)?.toInt();
    _prepPendingCount = (snapshotData['prep_pending_count'] as num?)?.toInt();
    _prepStatus = snapshotData['prep_status'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('staff_notices');

  static Stream<StaffNoticesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => StaffNoticesRecord.fromSnapshot(s));

  static Future<StaffNoticesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => StaffNoticesRecord.fromSnapshot(s));

  static StaffNoticesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      StaffNoticesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static StaffNoticesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      StaffNoticesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'StaffNoticesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is StaffNoticesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createStaffNoticesRecordData({
  String? type,
  DocumentReference? recipientUserRef,
  DocumentReference? orderRef,
  String? orderId,
  DateTime? deliveryDate,
  String? itemSummary,
  String? message,
  DateTime? createdTime,
  DateTime? readAt,
  DocumentReference? companyRef,
  String? noticeTitle,
  int? prepDeliveryCount,
  int? prepPendingCount,
  String? prepStatus,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'type': type,
      'recipient_user_ref': recipientUserRef,
      'order_ref': orderRef,
      'order_id': orderId,
      'delivery_date': deliveryDate,
      'item_summary': itemSummary,
      'message': message,
      'created_time': createdTime,
      'read_at': readAt,
      'companyRef': companyRef,
      'notice_title': noticeTitle,
      'prep_delivery_count': prepDeliveryCount,
      'prep_pending_count': prepPendingCount,
      'prep_status': prepStatus,
    }.withoutNulls,
  );
}

class StaffNoticesRecordDocumentEquality implements Equality<StaffNoticesRecord> {
  const StaffNoticesRecordDocumentEquality();

  @override
  bool equals(StaffNoticesRecord? e1, StaffNoticesRecord? e2) =>
      e1?.reference == e2?.reference;

  @override
  int hash(StaffNoticesRecord? e) => e?.reference.hashCode ?? 0;

  @override
  bool isValidKey(Object? o) => o is StaffNoticesRecord;
}
