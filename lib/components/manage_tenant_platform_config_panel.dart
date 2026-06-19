import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/platform/platform_config_service.dart';
import '/platform/platform_module.dart';
import '/platform/tenant_platform_config.dart';

class ManageTenantPlatformConfigPanel extends StatefulWidget {
  const ManageTenantPlatformConfigPanel({super.key});

  @override
  State<ManageTenantPlatformConfigPanel> createState() =>
      _ManageTenantPlatformConfigPanelState();
}

class _ManageTenantPlatformConfigPanelState
    extends State<ManageTenantPlatformConfigPanel> {
  TenantPlatformConfig? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late final TextEditingController _prefixController;
  late final TextEditingController _orderTypesController;
  late final TextEditingController _driverEnController;
  late final TextEditingController _driverZhController;
  final Map<PlatformFieldKey, TextEditingController> _fieldEnControllers = {};
  final Map<PlatformFieldKey, TextEditingController> _fieldZhControllers = {};

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController();
    _orderTypesController = TextEditingController();
    _driverEnController = TextEditingController();
    _driverZhController = TextEditingController();
    for (final key in PlatformFieldKey.values) {
      _fieldEnControllers[key] = TextEditingController();
      _fieldZhControllers[key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _orderTypesController.dispose();
    _driverEnController.dispose();
    _driverZhController.dispose();
    for (final c in _fieldEnControllers.values) {
      c.dispose();
    }
    for (final c in _fieldZhControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PlatformConfigService.instance.loadForActiveCompany();
      if (!mounted) {
        return;
      }
      _applyDraftToControllers(PlatformConfigService.instance.config);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _applyDraftToControllers(TenantPlatformConfig config) {
    _draft = config;
    _prefixController.text = config.orderIdPrefix;
    _orderTypesController.text = config.orderTypes.join(', ');
    _driverEnController.text = config.driverRoleLabelEn;
    _driverZhController.text = config.driverRoleLabelZh;
    for (final key in PlatformFieldKey.values) {
      _fieldEnControllers[key]!.text = config.fieldLabelsEn[key] ?? '';
      _fieldZhControllers[key]!.text = config.fieldLabelsZh[key] ?? '';
    }
  }

  TenantPlatformConfig _readDraftFromControllers() {
    final base = _draft ?? TenantPlatformConfig.genericDefaults();
    final orderTypes = _orderTypesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final labelsEn = {
      for (final key in PlatformFieldKey.values)
        key: _fieldEnControllers[key]!.text.trim(),
    };
    final labelsZh = {
      for (final key in PlatformFieldKey.values)
        key: _fieldZhControllers[key]!.text.trim(),
    };
    return base.copyWith(
      orderIdPrefix: _prefixController.text.trim(),
      orderTypes: orderTypes.isEmpty ? base.orderTypes : orderTypes,
      fieldLabelsEn: labelsEn,
      fieldLabelsZh: labelsZh,
      driverRoleLabelEn: _driverEnController.text.trim(),
      driverRoleLabelZh: _driverZhController.text.trim(),
    );
  }

  void _toggleModule(PlatformModule module, bool enabled) {
    final base = _readDraftFromControllers();
    final modules = Set<PlatformModule>.from(base.enabledModules);
    if (enabled) {
      modules.add(module);
    } else {
      modules.remove(module);
    }
    setState(() {
      _draft = base.copyWith(enabledModules: modules);
    });
  }

  void _setIndustryPreset(IndustryPreset? preset) {
    if (preset == null) {
      return;
    }
    setState(() {
      final template = TenantPlatformConfig.presetTemplate(preset);
      final current = _readDraftFromControllers();
      _draft = template.copyWith(
        industryPreset: preset,
        fieldLabelsEn: current.fieldLabelsEn,
        fieldLabelsZh: current.fieldLabelsZh,
      );
      _applyDraftToControllers(_draft!);
    });
  }

  Future<void> _applyPresetTemplate() async {
    final preset = _draft?.industryPreset ?? IndustryPreset.generic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'admin.industrySettings.applyPresetTitle')),
        content: Text(tr(context, 'admin.industrySettings.applyPresetBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'admin.industrySettings.applyPresetConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _draft = TenantPlatformConfig.presetTemplate(preset);
      _applyDraftToControllers(_draft!);
    });
  }

  Future<void> _save() async {
    if (!ensureActiveCompanyForWrite(context)) {
      return;
    }
    setState(() => _saving = true);
    try {
      final config = _readDraftFromControllers();
      await PlatformConfigService.instance.saveForActiveCompany(config);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'admin.industrySettings.saved'))),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'admin.industrySettings.saveFailed',
                params: {'error': '$error'},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _moduleLabel(BuildContext context, PlatformModule module) {
    return tr(context, 'admin.industrySettings.module.${module.name}');
  }

  String _fieldKeyLabel(BuildContext context, PlatformFieldKey key) {
    return tr(context, 'admin.industrySettings.field.${key.name}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final companyName = TenantContext.instance.activeCompany?.companyName;
    final companyId = TenantContext.instance.writeCompanyId;

    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final draft = _draft ?? TenantPlatformConfig.genericDefaults();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'admin.industrySettings.intro'),
          style: theme.bodyMedium.override(
            font: GoogleFonts.inter(),
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        if (companyName != null && companyName.isNotEmpty)
          Text(
            tr(
              context,
              'admin.industrySettings.companyScope',
              params: {'name': companyName, 'id': companyId},
            ),
            style: theme.titleSmall,
          )
        else
          Text(
            tr(context, 'admin.industrySettings.selectCompanyFirst'),
            style: theme.bodyMedium.override(color: theme.error),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              DropdownButtonFormField<IndustryPreset>(
                value: draft.industryPreset,
                decoration: InputDecoration(
                  labelText: tr(context, 'admin.industrySettings.industryPreset'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: IndustryPreset.values
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset,
                        child: Text(
                          tr(
                            context,
                            'admin.industrySettings.preset.${preset.name}',
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _setIndustryPreset,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _applyPresetTemplate,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    tr(context, 'admin.industrySettings.applyPresetButton'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prefixController,
                decoration: InputDecoration(
                  labelText: tr(context, 'admin.industrySettings.orderIdPrefix'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderTypesController,
                decoration: InputDecoration(
                  labelText: tr(context, 'admin.industrySettings.orderTypes'),
                  helperText: tr(context, 'admin.industrySettings.orderTypesHint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr(context, 'admin.industrySettings.modulesTitle'),
                style: theme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...PlatformModule.values.map(
                (module) => SwitchListTile(
                  title: Text(_moduleLabel(context, module)),
                  value: draft.enabledModules.contains(module),
                  onChanged: (value) => _toggleModule(module, value),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driverEnController,
                decoration: InputDecoration(
                  labelText: tr(context, 'admin.industrySettings.driverLabelEn'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driverZhController,
                decoration: InputDecoration(
                  labelText: tr(context, 'admin.industrySettings.driverLabelZh'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                title: Text(tr(context, 'admin.industrySettings.fieldLabelsTitle')),
                children: [
                  for (final key in PlatformFieldKey.values) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        _fieldKeyLabel(context, key),
                        style: theme.labelMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextFormField(
                        controller: _fieldEnControllers[key],
                        decoration: InputDecoration(
                          labelText: 'EN',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextFormField(
                        controller: _fieldZhControllers[key],
                        decoration: InputDecoration(
                          labelText: '中文',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FFButtonWidget(
          onPressed: _saving ? null : _save,
          text: tr(context, 'admin.industrySettings.save'),
          options: FFButtonOptions(
            width: double.infinity,
            height: 48,
            color: theme.primary,
            textStyle: theme.titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
