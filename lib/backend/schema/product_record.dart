import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProductRecord extends FirestoreRecord {
  ProductRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  bool hasPrice() => _price != null;

  // "image" field.
  String? _image;
  String get image => _image ?? '';
  bool hasImage() => _image != null;

  // "sku" field.
  String? _sku;
  String get sku => _sku ?? '';
  bool hasSku() => _sku != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "companyRef" field.
  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  List<Map<String, dynamic>>? _recipeLines;
  List<Map<String, dynamic>> get recipeLines =>
      _recipeLines ?? const [];
  bool hasRecipeLines() => _recipeLines != null && _recipeLines!.isNotEmpty;

  int? _stockQty;
  int get stockQty => _stockQty ?? 0;
  bool hasStockQty() => _stockQty != null;

  bool? _trackStock;
  bool get trackStock => _trackStock ?? true;
  bool hasTrackStock() => _trackStock != null;

  bool? _allowZeroStock;
  bool get allowZeroStock => _allowZeroStock ?? false;
  bool hasAllowZeroStock() => _allowZeroStock != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _price = castToType<double>(snapshotData['price']);
    _image = snapshotData['image'] as String?;
    _sku = snapshotData['sku'] as String?;
    _isActive = snapshotData['isActive'] as bool?;
    _category = snapshotData['category'] as String?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    final rawRecipeLines = snapshotData['recipeLines'];
    if (rawRecipeLines is List) {
      _recipeLines = rawRecipeLines
          .whereType<Map>()
          .map((line) => Map<String, dynamic>.from(line))
          .toList();
    }
    _stockQty = castToType<int>(snapshotData['stockQty']);
    _trackStock = snapshotData['trackStock'] as bool?;
    _allowZeroStock = snapshotData['allowZeroStock'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('product');

  static Stream<ProductRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ProductRecord.fromSnapshot(s));

  static Future<ProductRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ProductRecord.fromSnapshot(s));

  static ProductRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ProductRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ProductRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ProductRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ProductRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ProductRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createProductRecordData({
  String? name,
  double? price,
  String? image,
  String? sku,
  bool? isActive,
  String? category,
  DocumentReference? companyRef,
  List<Map<String, dynamic>>? recipeLines,
  int? stockQty,
  bool? trackStock,
  bool? allowZeroStock,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'price': price,
      'image': image,
      'sku': sku,
      'isActive': isActive,
      'category': category,
      'companyRef': companyRef,
      'recipeLines': recipeLines,
      'stockQty': stockQty,
      'trackStock': trackStock,
      'allowZeroStock': allowZeroStock,
    }.withoutNulls,
  );

  return firestoreData;
}

class ProductRecordDocumentEquality implements Equality<ProductRecord> {
  const ProductRecordDocumentEquality();

  @override
  bool equals(ProductRecord? e1, ProductRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.price == e2?.price &&
        e1?.image == e2?.image &&
        e1?.sku == e2?.sku &&
        e1?.isActive == e2?.isActive &&
        e1?.category == e2?.category &&
        e1?.stockQty == e2?.stockQty &&
        e1?.trackStock == e2?.trackStock &&
        e1?.allowZeroStock == e2?.allowZeroStock;
  }

  @override
  int hash(ProductRecord? e) => const ListEquality()
      .hash([e?.name, e?.price, e?.image, e?.sku, e?.isActive, e?.category, e?.stockQty, e?.trackStock, e?.allowZeroStock]);

  @override
  bool isValidKey(Object? o) => o is ProductRecord;
}
