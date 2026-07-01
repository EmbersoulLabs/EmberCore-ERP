import '/auth/role_helpers.dart';
import '/components/ember_app_shell.dart';
import '/components/ember_form_field.dart';
import '/components/ember_section_card.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_navigation.dart';
import '/backend/backend.dart';
import '/backend/product_category_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/product_recipe_helpers.dart';
import '/components/product_recipe_panel.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import '/productlist/productlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'productcreate_model.dart';
export 'productcreate_model.dart';

class ProductcreateWidget extends StatefulWidget {
  const ProductcreateWidget({
    super.key,
    this.productRef,
  });

  final DocumentReference? productRef;

  static String routeName = 'Productcreate';
  static String routePath = '/productcreate';

  @override
  State<ProductcreateWidget> createState() => _ProductcreateWidgetState();
}

class _ProductcreateWidgetState extends State<ProductcreateWidget> {
  late ProductcreateModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? _hydratedProductId;
  String _previewImageUrl = '';
  Uint8List? _pendingImageBytes;
  String _pendingImageFilename = 'photo.jpg';
  bool _savingProduct = false;
  List<ProductRecipeLine> _recipeLines = const [];
  /// Stable id for new products so photos upload before the first Firestore write.
  late final DocumentReference _draftProductRef;

  @override
  void initState() {
    super.initState();
    _draftProductRef =
        widget.productRef ?? ProductRecord.collection.doc();
    _model = createModel(context, () => ProductcreateModel());

    _model.productNameTextController ??= TextEditingController();
    _model.productNameFocusNode ??= FocusNode();
    _model.productNameFocusNode!.addListener(() => safeSetState(() {}));
    _model.skUTextController ??= TextEditingController();
    _model.skUFocusNode ??= FocusNode();
    _model.skUFocusNode!.addListener(() => safeSetState(() {}));
    _model.priceTextController ??= TextEditingController();
    _model.priceFocusNode ??= FocusNode();
    _model.priceFocusNode!.addListener(() => safeSetState(() {}));
    _model.switchValue = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  void _hydrateFromProduct(ProductRecord record) {
    if (_hydratedProductId == record.reference.id) {
      return;
    }
    _hydratedProductId = record.reference.id;
    _model.productNameTextController?.text = record.name;
    _model.skUTextController?.text = record.sku;
    _model.priceTextController?.text = record.price.toString();
    _model.switchValue = record.isActive;
    if (_pendingImageBytes == null && _previewImageUrl.isEmpty) {
      _previewImageUrl = productImageFromRecord(record);
    }
    if (record.category.isNotEmpty) {
      _model.skuValue = record.category;
      _model.skuValueController ??= FormFieldController<String>(record.category);
      _model.skuValueController?.value = record.category;
    }
    _recipeLines = parseProductRecipeLines(record);
  }

  Future<void> _handleUploadPhoto(DocumentReference? productRef) async {
    final targetRef = productRef ?? _draftProductRef;
    final persistNow = productRef != null;

    safeSetState(() => _model.isDataUploading_productimage = true);
    try {
      if (persistNow) {
        final result = await pickAndUploadProductImage(
          context: context,
          productRef: targetRef,
        );
        if (result != null) {
          safeSetState(() {
            _previewImageUrl = result.downloadUrl;
            _pendingImageBytes = null;
            _model.uploadedLocalFile_productimage = FFUploadedFile(
              name: 'photo.jpg',
              bytes: result.previewBytes,
            );
            _model.uploadedFileUrl_productimage = result.downloadUrl;
          });
        }
        return;
      }

      final selectedMedia = await selectMediaWithSourceBottomSheet(
        context: context,
        allowPhoto: true,
      );
      if (selectedMedia == null ||
          selectedMedia.isEmpty ||
          !selectedMedia.every(
            (m) => validateFileFormat(m.storagePath, context),
          )) {
        return;
      }
      final media = selectedMedia.first;
      final filename = media.storagePath.split('/').last;
      final uploadResult = await uploadProductImageBytes(
        productId: targetRef.id,
        bytes: media.bytes,
        filename: filename,
      );
      if (!uploadResult.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(storageUploadFailureMessage(uploadResult))),
          );
        }
        return;
      }
      final downloadUrl = uploadResult.downloadUrl!;
      if (!isValidFirebaseStorageDownloadUrl(downloadUrl)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'product.snack.invalidPhotoUrl')),
            ),
          );
        }
        return;
      }
      safeSetState(() {
        _previewImageUrl = downloadUrl;
        _pendingImageBytes = media.bytes;
        _pendingImageFilename = filename;
        _model.uploadedLocalFile_productimage = FFUploadedFile(
          name: filename,
          bytes: media.bytes,
        );
        _model.uploadedFileUrl_productimage = downloadUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'product.snack.photoUploaded')),
          ),
        );
      }
    } finally {
      safeSetState(() => _model.isDataUploading_productimage = false);
    }
  }

  String? _resolvedImageUrlForSave(ProductRecord? existing) {
    if (_previewImageUrl.isNotEmpty) {
      return _previewImageUrl;
    }
    if (_model.uploadedFileUrl_productimage.isNotEmpty) {
      return _model.uploadedFileUrl_productimage;
    }
    if (existing != null) {
      final fromRecord = productImageFromRecord(existing);
      if (fromRecord.isNotEmpty) {
        return fromRecord;
      }
    }
    return null;
  }

  Uint8List? _pendingPhotoBytes() {
    if (_pendingImageBytes != null && _pendingImageBytes!.isNotEmpty) {
      return _pendingImageBytes;
    }
    final modelBytes = _model.uploadedLocalFile_productimage.bytes;
    if (modelBytes != null && modelBytes.isNotEmpty) {
      return modelBytes;
    }
    return null;
  }

  Future<void> _saveProduct(ProductRecord? existing) async {
    if (_savingProduct) {
      return;
    }
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    if (_model.skuValue == null || _model.skuValue!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'product.snack.selectCategory'))),
      );
      return;
    }
    if (!ensureActiveCompanyForWrite(context)) {
      return;
    }

    safeSetState(() => _savingProduct = true);
    try {
      final price = double.tryParse(_model.priceTextController.text.trim());
      final ref = existing?.reference ?? _draftProductRef;
      final pendingBytes = _pendingPhotoBytes();
      var imageUrl = _resolvedImageUrlForSave(existing);

      if ((imageUrl == null || imageUrl.isEmpty) && pendingBytes != null) {
        final filename = _pendingImageFilename.isNotEmpty
            ? _pendingImageFilename
            : (_model.uploadedLocalFile_productimage.name ?? 'photo.jpg');
        final uploadResult = await uploadProductImageBytes(
          productId: ref.id,
          bytes: pendingBytes,
          filename: filename,
        );
        if (uploadResult.isSuccess) {
          imageUrl = uploadResult.downloadUrl;
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(storageUploadFailureMessage(uploadResult)),
            ),
          );
        }
      }

      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          !isValidFirebaseStorageDownloadUrl(imageUrl)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'product.snack.invalidPhotoUrl')),
            ),
          );
        }
        imageUrl = null;
      }

      final hasUploadedPhoto =
          imageUrl != null && imageUrl.isNotEmpty;
      final hadLocalPhoto = pendingBytes != null ||
          (_model.uploadedLocalFile_productimage.bytes?.isNotEmpty ?? false);

      final payload = {
        ...createTenantProductRecordData(
          name: _model.productNameTextController.text.trim(),
          price: price,
          image: hasUploadedPhoto ? imageUrl : null,
          sku: _model.skUTextController.text.trim(),
          isActive: _model.switchValue,
          category: _model.skuValue,
          recipeLines: productRecipeLinesToFirestore(_recipeLines),
        ),
        if (hasUploadedPhoto) 'Image': imageUrl,
      };

      try {
        if (existing == null) {
          await ref.set(payload);
        } else {
          await ref.update(payload);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(context, 'product.snack.saveFailed',
                    params: {'error': '$e'}),
              ),
            ),
          );
        }
        return;
      }

      if (hasUploadedPhoto) {
        safeSetState(() {
          _previewImageUrl = imageUrl!;
          _pendingImageBytes = null;
        });
      } else if (hadLocalPhoto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? tr(context, 'product.snack.photoNotSavedCreate')
                  : tr(context, 'product.snack.photoNotSavedUpdate'),
            ),
          ),
        );
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? (hasUploadedPhoto
                    ? tr(context, 'product.snack.createdWithPhoto')
                    : tr(context, 'product.snack.created'))
                : (hasUploadedPhoto
                    ? tr(context, 'product.snack.updatedWithPhoto')
                    : tr(context, 'product.snack.updated')),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
      context.pushNamed(ProductlistWidget.routeName);
    } finally {
      if (mounted) {
        safeSetState(() => _savingProduct = false);
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _buildProductCategoryDropdown() {
    return StreamBuilder<List<String>>(
      stream: streamTenantProductCategories(),
      builder: (context, categorySnapshot) {
        final categoryOptions = List<String>.from(
          categorySnapshot.data ?? defaultProductCategories,
        );
        if (_model.skuValue != null &&
            _model.skuValue!.isNotEmpty &&
            !categoryOptions.contains(_model.skuValue)) {
          categoryOptions.add(_model.skuValue!);
        }
        return FlutterFlowDropDown<String>(
          controller: _model.skuValueController ??=
              FormFieldController<String>(_model.skuValue),
          options: categoryOptions,
          onChanged: (val) => safeSetState(() => _model.skuValue = val),
          width: double.infinity,
          height: 48,
          textStyle: FlutterFlowTheme.of(context).bodyMedium,
          hintText: tr(context, 'product.form.categoryHint'),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: FlutterFlowTheme.of(context).secondaryText,
            size: 24,
          ),
          fillColor: EmberBrand.background,
          elevation: 0,
          borderColor: EmberBrand.border,
          borderWidth: 1,
          borderRadius: EmberBrand.radiusMd,
          margin: EdgeInsets.zero,
          hidesUnderline: true,
          isSearchable: true,
          isMultiSelect: false,
        );
      },
    );
  }

  Widget _buildLabeledField({
    required String labelKey,
    required Widget field,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, labelKey),
          style: emberFormFieldTextStyle(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: EmberBrand.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  InputDecoration _fieldDecoration(String labelKey, {String? hintKey}) {
    return emberFormInputDecoration(
      context,
      labelText: tr(context, labelKey),
      hintText: hintKey != null ? tr(context, hintKey) : null,
    );
  }

  Widget _buildProductForm(ProductRecord? formProductRecord) {
    return Form(
      key: _model.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmberSectionCard(
            title: tr(context, 'product.form.section.details'),
            child: Column(
              children: [
                _buildLabeledField(
                  labelKey: 'product.form.category',
                  field: _buildProductCategoryDropdown(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.productNameTextController,
                  focusNode: _model.productNameFocusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: emberFormFieldTextStyle(context),
                  decoration: _fieldDecoration(
                    'product.form.name',
                    hintKey: 'product.form.nameHint',
                  ),
                  validator: _model.productNameTextControllerValidator
                      .asValidator(context),
                  inputFormatters: [
                    if (!isAndroid && !isiOS)
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return TextEditingValue(
                          selection: newValue.selection,
                          text: newValue.text.toCapitalization(
                            TextCapitalization.words,
                          ),
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.skUTextController,
                  focusNode: _model.skUFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  style: emberFormFieldTextStyle(context),
                  decoration: _fieldDecoration(
                    'product.form.sku',
                    hintKey: 'product.form.skuHint',
                  ),
                  validator:
                      _model.skUTextControllerValidator.asValidator(context),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.priceTextController,
                  focusNode: _model.priceFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: emberFormFieldTextStyle(context),
                  decoration: _fieldDecoration(
                    'product.form.price',
                    hintKey: 'product.form.priceHint',
                  ),
                  validator: _model.priceTextControllerValidator
                      .asValidator(context),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(context, 'product.form.isActive')),
                  value: _model.switchValue ?? true,
                  activeThumbColor: EmberBrand.electricBlue,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchValue = newValue);
                    if (formProductRecord != null) {
                      await updateProductIsActive(
                        formProductRecord.reference,
                        newValue,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          EmberSectionCard(
            title: tr(context, 'product.form.section.photo'),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: buildZoomableProductImage(
                    context: context,
                    imageUrl: _previewImageUrl.isNotEmpty
                        ? _previewImageUrl
                        : null,
                    localBytes: _pendingPhotoBytes(),
                    productId:
                        (formProductRecord?.reference ?? _draftProductRef).id,
                    productRef:
                        formProductRecord?.reference ?? _draftProductRef,
                    title: _model.productNameTextController?.text,
                    width: double.infinity,
                    height: 160,
                    placeholderIcon: Icons.add_photo_alternate_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _model.isDataUploading_productimage
                      ? null
                      : () => _handleUploadPhoto(
                            formProductRecord?.reference,
                          ),
                  style: emberSecondaryButtonStyle(context),
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(
                    _model.isDataUploading_productimage
                        ? tr(context, 'common.uploading')
                        : tr(context, 'product.form.uploadPhoto'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ProductRecipePanel(
            lines: _recipeLines,
            onChanged: (lines) =>
                safeSetState(() => _recipeLines = lines),
            productCategorySelected: _model.skuValue != null &&
                _model.skuValue!.trim().isNotEmpty,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_savingProduct ||
                    _model.isDataUploading_productimage)
                ? null
                : () => _saveProduct(formProductRecord),
            style: emberPrimaryButtonStyle(context),
            child: Text(
              _savingProduct
                  ? tr(context, 'common.saving')
                  : (formProductRecord != null
                      ? tr(context, 'common.save')
                      : tr(context, 'common.create')),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = AppStateNotifier.instance.userRole;
    final isEdit = widget.productRef != null;
    final pageTitle = isEdit
        ? tr(context, 'product.edit.title')
        : tr(context, 'product.create.title');

    if (!canCreateProducts(role) || (isEdit && !canEditProducts(role))) {
      return EmberAppShell(
        selectedPath: ProductlistWidget.routePath,
        title: pageTitle,
        showBackButton: true,
        navGroups: buildEmberNavGroups(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              isEdit
                  ? tr(context, 'product.permission.noEdit')
                  : tr(context, 'product.permission.noCreate'),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyLarge,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: EmberAppShell(
        selectedPath: ProductlistWidget.routePath,
        title: pageTitle,
        subtitle: tr(context, 'product.form.subtitle'),
        showBackButton: true,
        navGroups: buildEmberNavGroups(context),
        body: SafeArea(
          child: StreamBuilder<List<ProductRecord>>(
            stream: widget.productRef != null
                ? ProductRecord.getDocument(widget.productRef!)
                    .map((record) => [record])
                : Stream.value(const <ProductRecord>[]),
            builder: (context, snapshot) {
              if (widget.productRef != null && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final formProductRecord =
                  snapshot.data != null && snapshot.data!.isNotEmpty
                      ? snapshot.data!.first
                      : null;

              if (formProductRecord != null) {
                _hydrateFromProduct(formProductRecord);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth =
                      constraints.maxWidth > 900 ? 720.0 : double.infinity;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _buildProductForm(formProductRecord),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
