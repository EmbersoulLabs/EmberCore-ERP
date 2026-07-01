import '/flutter_flow/flutter_flow_util.dart';
import 'tenant_list_page_widget.dart' show TenantListPageWidget;
import 'package:flutter/material.dart';

class TenantListPageModel extends FlutterFlowModel<TenantListPageWidget> {
  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchController?.dispose();
    searchFocusNode?.dispose();
  }
}
