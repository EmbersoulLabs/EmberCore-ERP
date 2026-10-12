import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/audit_log_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/custom_product_helpers.dart';
import '/backend/draft_order_writer.dart';
import '/backend/order_id_service.dart';
import '/backend/order_status_helpers.dart';
import '/backend/order_whatsapp_import_helpers.dart';
import '/backend/order_import_parser_service.dart';
import '/backend/price_list_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/product_match_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/product_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/components/whatsapp_order_paste_button.dart' show showWhatsAppOrderPasteDialog;
import '/platform/platform_labels.dart';
import '/pages/create_order_form/create_order_form_widget.dart';
import '/pages/order_detail_page/order_detail_page_widget.dart';

export '/backend/order_whatsapp_import_helpers.dart' show isWhatsAppOrderImportEnabled;

Future<double?> promptWhatsAppProductPriceDialog(
  BuildContext context, {
  String? productHint,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<double>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Enter product price'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (productHint != null && productHint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(productHint),
            ),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price (SGD)',
              prefixText: 'SGD ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final price = double.tryParse(controller.text.trim());
            if (price == null || price <= 0) {
              return;
            }
            Navigator.pop(dialogContext, price);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<DocumentReference> addCatalogProductToOrder({
  required DocumentReference orderRef,
  required ProductRecord product,
  required int qty,
  String? imageUrl,
}) async {
  final unitPrice = await resolveProductUnitPriceForOrder(
    orderRef: orderRef,
    product: product,
  );
  final itemRef = OrderItemRecord.collection.doc();
  await itemRef.set(
        createTenantOrderItemRecordData(
          orderRef: orderRef,
          productRef: product.reference,
          name: product.name,
          qty: qty,
          sku: product.sku,
          price: unitPrice,
          subtotal: functions.newCustomFunction2(unitPrice, qty),
          image: imageUrl ?? productImageFromRecord(product),
        ),
      );
  return itemRef;
}

Future<void> addDeliveryFeeLineItem(
  DocumentReference orderRef, {
  double fee = whatsAppDeliveryFeeAmount,
}) async {
  await OrderItemRecord.collection.doc().set(
        createTenantOrderItemRecordData(
          orderRef: orderRef,
          name: 'Delivery Fee',
          sku: 'Delivery',
          qty: 1,
          price: fee,
          subtotal: fee,
        ),
      );
}

Future<void> recalculateOrderTotals(DocumentReference orderRef) async {
  final items = await queryTenantOrderItemRecordOnce(
    queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    limit: 100,
  );
  if (items.isEmpty) {
    return;
  }
  final total = functions.calculationTotal(
    items.map((item) => item.price).toList(),
    items.map((item) => item.qty).toList(),
  );
  final totalQty = items.fold<int>(0, (sum, item) => sum + item.qty);
  await orderRef.update(
    createOrdersRecordData(
      totalAmount: total,
      total: total,
      totalQty: totalQty,
      productSelection: items.first.reference,
    ),
  );
}

bool shouldAddWhatsAppDeliveryFee({
  required String? orderType,
  required double merchandiseSubtotal,
}) {
  if (orderType != 'Delivery') {
    return false;
  }
  return merchandiseSubtotal > 0 &&
      merchandiseSubtotal < whatsAppDeliveryFeeThreshold;
}

Future<({String url, DocumentReference itemRef})?> _maybeUploadReferencePhoto(
  BuildContext context,
  WhatsAppParsedOrderDetails parsed,
) async {
  if (!parsed.needsReferencePhoto) {
    return null;
  }
  final uploadNow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reference photo'),
      content: const Text(
        'This WhatsApp message mentions a photo (如图). '
        'Upload the reference photo now?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Upload Photo'),
        ),
      ],
    ),
  );
  if (uploadNow != true || !context.mounted) {
    return null;
  }
  final itemRef = OrderItemRecord.collection.doc();
  final url = await pickAndUploadCustomProductImage(
    context: context,
    orderItemId: itemRef.id,
  );
  if (url == null) {
    return null;
  }
  return (url: url, itemRef: itemRef);
}

Future<bool> _addParsedProductLine({
  required BuildContext context,
  required DocumentReference orderRef,
  required WhatsAppParsedOrderDetails parsed,
  String? referencePhotoUrl,
  DocumentReference? referencePhotoItemRef,
}) async {
  final hint = parsed.productHint?.trim();
  if (hint == null || hint.isEmpty) {
    return true;
  }

  final qty = parseProductQtyFromHint(hint);
  final matchHint = stripOrderQtyMultiplier(hint);
  final products = await queryTenantProductRecordOnce(limit: 500);
  final matched = findBestProductMatch(products, matchHint);

  double? unitPrice = parsed.productPrice ?? matched?.price;
  if (unitPrice == null) {
    if (!context.mounted) {
      return false;
    }
    unitPrice = await promptWhatsAppProductPriceDialog(
      context,
      productHint: hint,
    );
    if (unitPrice == null) {
      return false;
    }
  }

  if (matched != null) {
    await addCatalogProductToOrder(
      orderRef: orderRef,
      product: matched,
      qty: qty,
      imageUrl: referencePhotoUrl,
    );
  } else {
    await createCustomProductOrderItem(
      context: context,
      orderRef: orderRef,
      name: hint,
      qty: qty,
      price: unitPrice,
      remark: parsed.cardMessage ?? '',
      imageUrl: referencePhotoUrl,
      itemRef: referencePhotoItemRef,
    );
  }

  final merchandiseSubtotal = unitPrice * qty;
  if (shouldAddWhatsAppDeliveryFee(
    orderType: resolveWhatsAppImportOrderType(parsed.orderType),
    merchandiseSubtotal: merchandiseSubtotal,
  )) {
    await addDeliveryFeeLineItem(orderRef);
  }

  await recalculateOrderTotals(orderRef);
  return true;
}

Future<void> _prepareImportedOrderForDeliveryForm({
  required DocumentReference orderRef,
  required WhatsAppParsedOrderDetails parsed,
}) async {
  final postalCode = parsed.postalCode ?? '';
  final region = parsed.region ??
      (postalCode.isNotEmpty ? functions.newCustomFunction(postalCode) : null);
  final orderId = await OrderIdService.assignDeliveryOrderId(orderRef);
  final orderType = resolveWhatsAppImportOrderType(parsed.orderType);

  await orderRef.update(
    createOrdersRecordData(
      orderId: orderId,
      clientName: parsed.clientName ?? '',
      recipientName: parsed.recipientName ?? '',
      recipientPhoneNumber: parsed.phone ?? '',
      address: parsed.address ?? '',
      postalCode: postalCode,
      region: region ?? '',
      deliveryDate: parsed.deliveryDate,
      deliveryTimeSlot:
          resolveWhatsAppDeliveryTimeSlot(parsed.deliveryTimeSlot),
      cardMessage: parsed.cardMessage ?? '',
      orderType: orderType,
      pickupDelivery: orderType,
      status: OrderStatus.pending,
      orderstatus: legacyOrderStatusLabel(OrderStatus.pending),
    ),
  );
}

Future<bool?> showOrderImportAnalysisDialog(
  BuildContext context,
  WhatsAppParsedOrderDetails parsed,
) {
  final lines = <String>[
    if (parsed.clientName != null && parsed.clientName!.isNotEmpty)
      'Customer: ${parsed.clientName}',
    if (parsed.recipientName != null && parsed.recipientName!.isNotEmpty)
      'Recipient: ${parsed.recipientName}',
    if (parsed.phone != null && parsed.phone!.isNotEmpty) 'Phone: ${parsed.phone}',
    if (parsed.address != null && parsed.address!.isNotEmpty)
      'Address: ${parsed.address}',
    if (parsed.productHint != null && parsed.productHint!.isNotEmpty)
      'Product: ${parsed.productHint}',
    if (parsed.deliveryDate != null)
      'Delivery date: ${dateTimeFormat('yMMMd', parsed.deliveryDate)}',
    if (parsed.deliveryTimeSlot != null &&
        parsed.deliveryTimeSlot!.trim().isNotEmpty)
      'Time slot: ${parsed.deliveryTimeSlot}',
    if (parsed.needsReferencePhoto)
      'Reference photo (如图) can be uploaded next.',
  ];

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Order import analysis'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lines.isEmpty)
              const Text('Parsed order details are ready to review.')
            else
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}

void _openCreateOrderForm(BuildContext context, DocumentReference orderRef) {
  final serialized = serializeParam(
    orderRef,
    ParamType.DocumentReference,
  );
  context.pushNamed(
    CreateOrderFormWidget.routeName,
    queryParameters:
        serialized != null ? <String, String>{'orderRef': serialized} : {},
    extra: <String, dynamic>{'orderRef': orderRef},
  );
}

void _openOrderDetail(BuildContext context, DocumentReference orderRef) {
  final serialized = serializeParam(
    orderRef,
    ParamType.DocumentReference,
  );
  context.pushNamed(
    OrderDetailPageWidget.routeName,
    queryParameters:
        serialized != null ? <String, String>{'orderRef': serialized} : {},
    extra: <String, dynamic>{'orderRef': orderRef},
  );
}

/// Dashboard entry: paste → analysis → delivery detail → payment → order detail.
Future<void> runWhatsAppOrderImportFromDashboard(BuildContext context) async {
  if (!isWhatsAppOrderImportEnabled) {
    return;
  }

  final moduleBlocked = platformModuleWhatsAppImportBlockMessage();
  if (moduleBlocked != null) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(moduleBlocked)),
    );
    return;
  }

  final text = await showWhatsAppOrderPasteDialog(context);
  if (text == null || !context.mounted) {
    return;
  }

  final parsed = await parseOrderImportTextForUi(context, text);
  if (parsed.orderId != null) {
    final order = await findOrderByOrderId(parsed.orderId!);
    if (order != null) {
      if (context.mounted) {
        _openOrderDetail(context, order.reference);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opened order ${parsed.orderId}')),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ID ${parsed.orderId} was not found. Continuing as new order.',
          ),
        ),
      );
    }
  }

  if (!parsed.hasFormFields && parsed.productHint == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read an order from the message. '
            'Paste an order message with customer or product details.',
          ),
        ),
      );
    }
    return;
  }

  final confirmed = await showOrderImportAnalysisDialog(context, parsed);
  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    final orderRef = await createDraftOrderDocument();
    if (!context.mounted) {
      return;
    }

    String? referencePhotoUrl;
    DocumentReference? referencePhotoItemRef;
    final photoUpload = await _maybeUploadReferencePhoto(context, parsed);
    if (photoUpload != null) {
      referencePhotoUrl = photoUpload.url;
      referencePhotoItemRef = photoUpload.itemRef;
    }

    final addedProduct = await _addParsedProductLine(
      context: context,
      orderRef: orderRef,
      parsed: parsed,
      referencePhotoUrl: referencePhotoUrl,
      referencePhotoItemRef: referencePhotoItemRef,
    );
    if (!addedProduct || !context.mounted) {
      return;
    }

    await _prepareImportedOrderForDeliveryForm(
      orderRef: orderRef,
      parsed: parsed,
    );

    final createdOrder = await OrdersRecord.getDocumentOnce(orderRef);
    await auditLogCreateOrder(createdOrder);

    if (!context.mounted) {
      return;
    }

    _openCreateOrderForm(context, orderRef);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Order imported. Review delivery details, then continue to payment.',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(describeFirestoreError(error)),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
