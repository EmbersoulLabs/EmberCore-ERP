import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

/// Ordered stop list + open-in-maps action for driver delivery pages.
class DriverSuggestedRouteSection extends StatelessWidget {
  const DriverSuggestedRouteSection({
    super.key,
    required this.routeOrders,
    required this.onOpenMaps,
    this.locale,
  });

  final List<OrdersRecord> routeOrders;
  final VoidCallback onOpenMaps;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final stops = routeOrders
        .where((order) => order.address.trim().isNotEmpty)
        .toList();

    if (stops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: EmberBrand.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: EmberBrand.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(context, 'order.driver.suggestedRoute'),
                  style: GoogleFonts.interTight(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: EmberBrand.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < stops.length; i++)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openOrderDetail(context, stops[i].reference),
                borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: EmberBrand.navy,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderListOrderId(stops[i]),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: EmberBrand.textPrimary,
                              ),
                            ),
                            if (stops[i].clientName.isNotEmpty)
                              Text(
                                stops[i].clientName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: EmberBrand.textPrimary,
                                ),
                              ),
                            Text(
                              stops[i].address.trim(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: EmberBrand.textSecondary,
                              ),
                            ),
                            Text(
                              '${orderListDeliveryDateOnly(stops[i], locale: locale)} · '
                              '${orderListDeliveryTimeSlot(stops[i])}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: EmberBrand.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: EmberBrand.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(Icons.map_outlined, size: 20),
              label: Text(
                tr(context, 'order.driver.openInMaps'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: EmberBrand.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
