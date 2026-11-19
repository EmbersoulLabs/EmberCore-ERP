import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/asset_library_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

class AssetLibraryPageWidget extends StatefulWidget {
  const AssetLibraryPageWidget({super.key});

  static String routeName = 'AssetLibraryPage';
  static String routePath = '/assetLibraryPage';

  @override
  State<AssetLibraryPageWidget> createState() => _AssetLibraryPageWidgetState();
}

class _AssetLibraryPageWidgetState extends State<AssetLibraryPageWidget> {
  List<AssetImageEntry> _assets = const [];
  final Set<String> _selectedPaths = {};
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAndLoad());
  }

  Future<void> _bootstrapAndLoad() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    await _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assets = await loadTenantAssetImages()
          .timeout(const Duration(seconds: 60));
      if (!mounted) {
        return;
      }
      setState(() {
        _assets = assets;
        _selectedPaths.removeWhere(
          (path) => !assets.any((entry) => entry.storagePath == path),
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error is TimeoutException
            ? 'Timed out loading images. Pull to refresh.'
            : describeFirestoreError(error);
      });
    }
  }

  void _toggleSelection(AssetImageEntry entry) {
    setState(() {
      if (_selectedPaths.contains(entry.storagePath)) {
        _selectedPaths.remove(entry.storagePath);
      } else {
        _selectedPaths.add(entry.storagePath);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPaths
        ..clear()
        ..addAll(_assets.map((entry) => entry.storagePath));
    });
  }

  void _clearSelection() {
    setState(_selectedPaths.clear);
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedPaths.isEmpty || _deleting) {
      return;
    }
    final count = _selectedPaths.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'asset.delete.title')),
        content: Text(
          tr(context, 'asset.delete.body', params: {'count': '$count'}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              tr(context, 'common.delete'),
              style: TextStyle(color: FlutterFlowTheme.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deleting = true);
    try {
      final targets = _assets
          .where((entry) => _selectedPaths.contains(entry.storagePath))
          .toList();
      final deleted = await deleteAssetImageEntries(targets);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'asset.delete.success', params: {'count': '$deleted'}),
          ),
        ),
      );
      await _loadAssets();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeFirestoreError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canManage = canEditProducts(AppStateNotifier.instance.userRole);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        title: Text(tr(context, 'asset.page.title')),
        actions: [
          if (canManage && _assets.isNotEmpty)
            IconButton(
              tooltip: tr(context, 'asset.action.selectAll'),
              icon: const Icon(Icons.select_all, color: Colors.white),
              onPressed: _deleting ? null : _selectAll,
            ),
          if (_selectedPaths.isNotEmpty)
            IconButton(
              tooltip: tr(context, 'asset.action.clearSelection'),
              icon: const Icon(Icons.deselect, color: Colors.white),
              onPressed: _deleting ? null : _clearSelection,
            ),
          IconButton(
            tooltip: tr(context, 'common.refresh'),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading || _deleting ? null : _loadAssets,
          ),
          const HomeNavIconButton.onPrimary(),
        ],
      ),
      floatingActionButton: canManage && _selectedPaths.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _deleting ? null : _confirmDeleteSelected,
              backgroundColor: theme.error,
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(
                tr(
                  context,
                  'asset.action.deleteSelected',
                  params: {'count': '${_selectedPaths.length}'},
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _assets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr(context, 'asset.page.empty'),
                          textAlign: TextAlign.center,
                          style: theme.bodyLarge.override(
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAssets,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _assets.length,
                        itemBuilder: (context, index) {
                          final entry = _assets[index];
                          final selected =
                              _selectedPaths.contains(entry.storagePath);
                          return InkWell(
                            onTap: canManage
                                ? () => _toggleSelection(entry)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.secondaryBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? theme.primary
                                      : theme.alternate,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(9),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          buildProductImage(
                                            context: context,
                                            imageUrl: entry.downloadUrl,
                                            productId: entry.parentId,
                                            storageFolderPrefix: entry.kind ==
                                                    AssetImageKind.product
                                                ? 'product_images'
                                                : 'custom_product_images',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                          if (canManage)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Icon(
                                                selected
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .radio_button_unchecked,
                                                color: selected
                                                    ? theme.primary
                                                    : Colors.white,
                                                shadows: const [
                                                  Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.black54,
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.labelMedium.override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          entry.kind ==
                                                  AssetImageKind.product
                                              ? tr(context, 'asset.kind.product')
                                              : tr(
                                                  context,
                                                  'asset.kind.custom',
                                                ),
                                          style: theme.bodySmall.override(
                                            color: theme.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
