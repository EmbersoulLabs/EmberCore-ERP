import '/backend/backend.dart';
import '/components/edit_price_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'productlist_widget.dart' show ProductlistWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductlistModel extends FlutterFlowModel<ProductlistWidget> {
  ///  Local state fields for this page.

  DocumentReference? selectedproduct;

  TextEditingController? searchController;
  FocusNode? searchFocusNode;
  String? selectedCategory;

  final Set<String> selectedProductPaths = {};

  List<ProductRecord> selectedProducts(List<ProductRecord> visibleProducts) =>
      visibleProducts
          .where((p) => selectedProductPaths.contains(p.reference.path))
          .toList();

  void pruneSelection(Iterable<ProductRecord> products) {
    final validPaths = products.map((p) => p.reference.path).toSet();
    selectedProductPaths.removeWhere((path) => !validPaths.contains(path));
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchFocusNode?.dispose();
    searchController?.dispose();
  }
}
