import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/dashboard_order_stats_helpers.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

class EmberOrderFlowPipeline extends StatelessWidget {
  const EmberOrderFlowPipeline({
    super.key,
    required this.pipeline,
  });

  final DashboardOrderPipeline pipeline;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(
        label: tr(context, 'dashboard.pipeline.pending'),
        count: pipeline.pending,
        color: EmberBrand.amber,
      ),
      _Step(
        label: tr(context, 'dashboard.pipeline.processing'),
        count: pipeline.processing,
        color: EmberBrand.electricBlue,
      ),
      _Step(
        label: tr(context, 'dashboard.pipeline.ready'),
        count: pipeline.ready,
        color: EmberBrand.teal,
      ),
      _Step(
        label: tr(context, 'dashboard.pipeline.outForDelivery'),
        count: pipeline.outForDelivery,
        color: EmberBrand.electricBlue,
      ),
      _Step(
        label: tr(context, 'dashboard.pipeline.completed'),
        count: pipeline.completed,
        color: EmberBrand.teal,
      ),
    ];

    return Container(
      decoration: EmberBrand.cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'dashboard.orderFlow'),
            style: GoogleFonts.interTight(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EmberBrand.navy,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              if (compact) {
                return Column(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      _PipelineStepRow(step: steps[i]),
                      if (i < steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Icon(
                            Icons.arrow_downward,
                            size: 16,
                            color: EmberBrand.border,
                          ),
                        ),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    Expanded(child: _PipelineStepColumn(step: steps[i])),
                    if (i < steps.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: EmberBrand.border,
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _PipelineStepColumn extends StatelessWidget {
  const _PipelineStepColumn({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: step.color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${step.count}',
            style: GoogleFonts.interTight(
              fontWeight: FontWeight.w700,
              color: step.color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: EmberBrand.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PipelineStepRow extends StatelessWidget {
  const _PipelineStepRow({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${step.count}',
            style: GoogleFonts.interTight(
              fontWeight: FontWeight.w700,
              color: step.color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            step.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: EmberBrand.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class EmberActionRequiredCard extends StatelessWidget {
  const EmberActionRequiredCard({
    super.key,
    required this.actionRequired,
    this.onItemTap,
  });

  final DashboardActionRequired actionRequired;
  final void Function(String actionKey)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionItem>[
      _ActionItem(
        key: 'missingPayment',
        label: tr(context, 'dashboard.action.missingPayment'),
        count: actionRequired.missingPayment,
        icon: Icons.payments_outlined,
        color: EmberBrand.amber,
      ),
      _ActionItem(
        key: 'unassignedDriver',
        label: tr(context, 'dashboard.action.unassignedDriver'),
        count: actionRequired.unassignedDriver,
        icon: Icons.local_shipping_outlined,
        color: EmberBrand.electricBlue,
      ),
      _ActionItem(
        key: 'incompleteCustomer',
        label: tr(context, 'dashboard.action.incompleteCustomer'),
        count: actionRequired.incompleteCustomer,
        icon: Icons.person_outline,
        color: EmberBrand.electricBlue,
      ),
      _ActionItem(
        key: 'urgentDelivery',
        label: tr(context, 'dashboard.action.urgentDelivery'),
        count: actionRequired.urgentDelivery,
        icon: Icons.warning_amber_rounded,
        color: EmberBrand.amber,
      ),
    ].where((item) => item.count > 0).toList();

    if (items.isEmpty) {
      return Container(
        decoration: EmberBrand.cardDecoration(),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: EmberBrand.teal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(context, 'dashboard.pipeline.completed'),
                style: GoogleFonts.inter(
                  color: EmberBrand.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: EmberBrand.cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'dashboard.actionRequired'),
            style: GoogleFonts.interTight(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EmberBrand.navy,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items)
            _ActionRow(
              item: item,
              onTap: onItemTap == null ? null : () => onItemTap!(item.key),
            ),
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.item,
    this.onTap,
  });

  final _ActionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: item.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: EmberBrand.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.count}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: item.color,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
