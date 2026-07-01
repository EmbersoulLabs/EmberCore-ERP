import '/platform/platform_module.dart';

/// Placeholder-based templates for scheduled operation reminders (Cloud Functions).
class OperationNoticeTemplates {
  const OperationNoticeTemplates({
    required this.tomorrowPrep,
    required this.tomorrowPrepWeekend,
    required this.todayOps,
  });

  final String tomorrowPrep;
  final String tomorrowPrepWeekend;
  final String todayOps;

  static OperationNoticeTemplates defaults() => const OperationNoticeTemplates(
        tomorrowPrep: '{line1}\n{line2}',
        tomorrowPrepWeekend: '{line1}\n{line2}',
        todayOps:
            'Today ({target_date}): {total_delivery} delivery order(s) ({not_started} not started)',
      );

  OperationNoticeTemplates copyWith({
    String? tomorrowPrep,
    String? tomorrowPrepWeekend,
    String? todayOps,
  }) {
    return OperationNoticeTemplates(
      tomorrowPrep: tomorrowPrep ?? this.tomorrowPrep,
      tomorrowPrepWeekend: tomorrowPrepWeekend ?? this.tomorrowPrepWeekend,
      todayOps: todayOps ?? this.todayOps,
    );
  }

  static OperationNoticeTemplates fromFirestore(
    Map? raw,
    OperationNoticeTemplates fallback,
  ) {
    if (raw == null) {
      return fallback;
    }
    String pick(String key, String base) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return base;
    }

    return OperationNoticeTemplates(
      tomorrowPrep: pick('tomorrow_prep', fallback.tomorrowPrep),
      tomorrowPrepWeekend:
          pick('tomorrow_prep_weekend', fallback.tomorrowPrepWeekend),
      todayOps: pick('today_ops', fallback.todayOps),
    );
  }

  Map<String, String> toFirestore() => {
        'tomorrow_prep': tomorrowPrep,
        'tomorrow_prep_weekend': tomorrowPrepWeekend,
        'today_ops': todayOps,
      };
}

/// Known industry presets. Tenants can use [generic] or override per company in Firestore.
enum IndustryPreset {
  generic,
  florist,
  fieldService,
  transport,
}

String industryPresetKey(IndustryPreset preset) => preset.name;

IndustryPreset parseIndustryPresetKey(String? key) {
  switch (key) {
    case 'florist':
      return IndustryPreset.florist;
    case 'field_service':
    case 'fieldService':
      return IndustryPreset.fieldService;
    case 'transport':
      return IndustryPreset.transport;
    default:
      return IndustryPreset.generic;
  }
}

/// UI / document field labels over generic order & customer data.
enum PlatformFieldKey {
  recipientName,
  recipientPhone,
  serviceNotes,
  scheduledDate,
  timeWindow,
  serviceAddress,
  customerId,
}

/// Per-tenant platform customization loaded from Firestore `tenant_platform_config/{companyId}`.
class TenantPlatformConfig {
  const TenantPlatformConfig({
    required this.industryPreset,
    required this.enabledModules,
    required this.orderTypes,
    required this.orderIdPrefix,
    required this.fieldLabelsEn,
    required this.fieldLabelsZh,
    required this.statusLabelsEn,
    required this.driverRoleLabelEn,
    required this.driverRoleLabelZh,
    required this.operationNoticeTemplates,
  });

  final IndustryPreset industryPreset;
  final Set<PlatformModule> enabledModules;
  final List<String> orderTypes;
  final String orderIdPrefix;
  final Map<PlatformFieldKey, String> fieldLabelsEn;
  final Map<PlatformFieldKey, String> fieldLabelsZh;
  final Map<String, String> statusLabelsEn;
  final String driverRoleLabelEn;
  final String driverRoleLabelZh;
  final OperationNoticeTemplates operationNoticeTemplates;

  bool isModuleEnabled(PlatformModule module) => enabledModules.contains(module);

  String fieldLabel(PlatformFieldKey key, {String locale = 'en'}) {
    final map = locale.startsWith('zh') ? fieldLabelsZh : fieldLabelsEn;
    return map[key] ?? fieldLabelsEn[key] ?? key.name;
  }

  String statusLabel(String statusKey, {String locale = 'en'}) {
    if (locale.startsWith('zh')) {
      return _genericStatusLabelsZh[statusKey] ??
          statusLabelsEn[statusKey] ??
          statusKey;
    }
    return statusLabelsEn[statusKey] ?? statusKey;
  }

  TenantPlatformConfig copyWith({
    IndustryPreset? industryPreset,
    Set<PlatformModule>? enabledModules,
    List<String>? orderTypes,
    String? orderIdPrefix,
    Map<PlatformFieldKey, String>? fieldLabelsEn,
    Map<PlatformFieldKey, String>? fieldLabelsZh,
    Map<String, String>? statusLabelsEn,
    String? driverRoleLabelEn,
    String? driverRoleLabelZh,
    OperationNoticeTemplates? operationNoticeTemplates,
  }) {
    return TenantPlatformConfig(
      industryPreset: industryPreset ?? this.industryPreset,
      enabledModules: enabledModules ?? this.enabledModules,
      orderTypes: orderTypes ?? this.orderTypes,
      orderIdPrefix: orderIdPrefix ?? this.orderIdPrefix,
      fieldLabelsEn: fieldLabelsEn ?? this.fieldLabelsEn,
      fieldLabelsZh: fieldLabelsZh ?? this.fieldLabelsZh,
      statusLabelsEn: statusLabelsEn ?? this.statusLabelsEn,
      driverRoleLabelEn: driverRoleLabelEn ?? this.driverRoleLabelEn,
      driverRoleLabelZh: driverRoleLabelZh ?? this.driverRoleLabelZh,
      operationNoticeTemplates:
          operationNoticeTemplates ?? this.operationNoticeTemplates,
    );
  }

  static TenantPlatformConfig presetTemplate(IndustryPreset preset) {
    return switch (preset) {
      IndustryPreset.florist => TenantPlatformConfig.floristLegacy(),
      IndustryPreset.fieldService ||
      IndustryPreset.transport ||
      IndustryPreset.generic =>
        TenantPlatformConfig.genericDefaults(),
    };
  }

  /// Neutral defaults for new SaaS tenants (appointment + field service + transport ready).
  factory TenantPlatformConfig.genericDefaults() {
    return TenantPlatformConfig(
      industryPreset: IndustryPreset.generic,
      enabledModules: {
        PlatformModule.orders,
        PlatformModule.pos,
        PlatformModule.fieldService,
        PlatformModule.drivers,
        PlatformModule.customers,
        PlatformModule.invoices,
        PlatformModule.products,
        PlatformModule.reports,
        PlatformModule.customerBroadcast,
      },
      orderTypes: const ['OnSite', 'WalkIn', 'Remote'],
      orderIdPrefix: 'EC',
      fieldLabelsEn: Map<PlatformFieldKey, String>.from(_genericFieldLabelsEn),
      fieldLabelsZh: Map<PlatformFieldKey, String>.from(_genericFieldLabelsZh),
      statusLabelsEn: Map<String, String>.from(_genericStatusLabelsEn),
      driverRoleLabelEn: 'Field staff',
      driverRoleLabelZh: '外勤人员',
      operationNoticeTemplates: OperationNoticeTemplates.defaults(),
    );
  }

  /// Matches legacy florist behaviour until tenant migrates UI to [PlatformConfigService].
  factory TenantPlatformConfig.floristLegacy() {
    return TenantPlatformConfig(
      industryPreset: IndustryPreset.florist,
      enabledModules: Set<PlatformModule>.from(PlatformModule.values)
        ..remove(PlatformModule.appointments),
      orderTypes: const ['Delivery', 'Retail', 'PickUp'],
      orderIdPrefix: 'TFG',
      fieldLabelsEn: {
        PlatformFieldKey.recipientName: 'Recipient',
        PlatformFieldKey.recipientPhone: 'Recipient phone',
        PlatformFieldKey.serviceNotes: 'Card message',
        PlatformFieldKey.scheduledDate: 'Delivery date',
        PlatformFieldKey.timeWindow: 'Delivery time slot',
        PlatformFieldKey.serviceAddress: 'Delivery address',
        PlatformFieldKey.customerId: 'Customer ID',
      },
      fieldLabelsZh: {
        PlatformFieldKey.recipientName: '收花人',
        PlatformFieldKey.recipientPhone: '收花人电话',
        PlatformFieldKey.serviceNotes: '贺卡留言',
        PlatformFieldKey.scheduledDate: '配送日期',
        PlatformFieldKey.timeWindow: '配送时段',
        PlatformFieldKey.serviceAddress: '配送地址',
        PlatformFieldKey.customerId: '客户编号',
      },
      statusLabelsEn: Map<String, String>.from(_genericStatusLabelsEn),
      driverRoleLabelEn: 'Driver',
      driverRoleLabelZh: '司机',
      operationNoticeTemplates: OperationNoticeTemplates.defaults(),
    );
  }

  static const _collection = 'tenant_platform_config';

  static String documentId(String companyId) => companyId;

  static TenantPlatformConfig fromFirestore(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return TenantPlatformConfig.genericDefaults();
    }

    final preset = parseIndustryPresetKey(data['industry_key'] as String?);
    final base = switch (preset) {
      IndustryPreset.florist => TenantPlatformConfig.floristLegacy(),
      IndustryPreset.fieldService ||
      IndustryPreset.transport ||
      IndustryPreset.generic =>
        TenantPlatformConfig.genericDefaults(),
    };

    final modulesRaw = data['enabled_modules'];
    Set<PlatformModule>? modules;
    if (modulesRaw is List) {
      modules = modulesRaw
          .map((e) => parsePlatformModuleKey(e?.toString()))
          .whereType<PlatformModule>()
          .toSet();
    }

    final orderTypesRaw = data['order_types'];
    List<String>? orderTypes;
    if (orderTypesRaw is List) {
      orderTypes = orderTypesRaw.map((e) => e.toString()).toList();
    }

    final labelsEn = _parseFieldLabels(
      data['field_labels_en'] as Map?,
      base.fieldLabelsEn,
    );
    final labelsZh = _parseFieldLabels(
      data['field_labels_zh'] as Map?,
      base.fieldLabelsZh,
    );

    final statusEn = _parseStringMap(
      data['status_labels_en'] as Map?,
      base.statusLabelsEn,
    );

    return TenantPlatformConfig(
      industryPreset: preset,
      enabledModules: modules ?? base.enabledModules,
      orderTypes: orderTypes ?? base.orderTypes,
      orderIdPrefix: (data['order_id_prefix'] as String?)?.trim().isNotEmpty ==
              true
          ? (data['order_id_prefix'] as String).trim()
          : base.orderIdPrefix,
      fieldLabelsEn: labelsEn,
      fieldLabelsZh: labelsZh,
      statusLabelsEn: statusEn,
      driverRoleLabelEn:
          (data['driver_role_label_en'] as String?) ?? base.driverRoleLabelEn,
      driverRoleLabelZh:
          (data['driver_role_label_zh'] as String?) ?? base.driverRoleLabelZh,
      operationNoticeTemplates: OperationNoticeTemplates.fromFirestore(
        data['operation_notice_templates'] as Map?,
        base.operationNoticeTemplates,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'industry_key': industryPresetKey(industryPreset),
        'enabled_modules':
            enabledModules.map(platformModuleKey).toList()..sort(),
        'order_types': orderTypes,
        'order_id_prefix': orderIdPrefix,
        'field_labels_en': {
          for (final e in fieldLabelsEn.entries) _fieldKeyName(e.key): e.value,
        },
        'field_labels_zh': {
          for (final e in fieldLabelsZh.entries) _fieldKeyName(e.key): e.value,
        },
        'status_labels_en': statusLabelsEn,
        'driver_role_label_en': driverRoleLabelEn,
        'driver_role_label_zh': driverRoleLabelZh,
        'operation_notice_templates': operationNoticeTemplates.toFirestore(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  static Map<PlatformFieldKey, String> _parseFieldLabels(
    Map? raw,
    Map<PlatformFieldKey, String> fallback,
  ) {
    if (raw == null) {
      return fallback;
    }
    final merged = Map<PlatformFieldKey, String>.from(fallback);
    raw.forEach((key, value) {
      final field = _parseFieldKey(key?.toString());
      if (field != null && value is String && value.trim().isNotEmpty) {
        merged[field] = value.trim();
      }
    });
    return merged;
  }

  static Map<String, String> _parseStringMap(
    Map? raw,
    Map<String, String> fallback,
  ) {
    if (raw == null) {
      return fallback;
    }
    final merged = Map<String, String>.from(fallback);
    raw.forEach((key, value) {
      if (key is String && value is String && value.trim().isNotEmpty) {
        merged[key] = value.trim();
      }
    });
    return merged;
  }

  static PlatformFieldKey? _parseFieldKey(String? key) {
    if (key == null) {
      return null;
    }
    for (final field in PlatformFieldKey.values) {
      if (field.name == key || _fieldKeyName(field) == key) {
        return field;
      }
    }
    return null;
  }

  static String _fieldKeyName(PlatformFieldKey key) => key.name;

  static const _genericFieldLabelsEn = {
    PlatformFieldKey.recipientName: 'Site contact',
    PlatformFieldKey.recipientPhone: 'Contact phone',
    PlatformFieldKey.serviceNotes: 'Service notes',
    PlatformFieldKey.scheduledDate: 'Scheduled date',
    PlatformFieldKey.timeWindow: 'Time window',
    PlatformFieldKey.serviceAddress: 'Service address',
    PlatformFieldKey.customerId: 'Customer ID',
  };

  static const _genericFieldLabelsZh = {
    PlatformFieldKey.recipientName: '现场联系人',
    PlatformFieldKey.recipientPhone: '联系人电话',
    PlatformFieldKey.serviceNotes: '服务备注',
    PlatformFieldKey.scheduledDate: '预约日期',
    PlatformFieldKey.timeWindow: '时段',
    PlatformFieldKey.serviceAddress: '服务地址',
    PlatformFieldKey.customerId: '客户编号',
  };

  static const _genericStatusLabelsEn = {
    'pending': 'Pending',
    'processing': 'In progress',
    'ready_to_delivery': 'Ready',
    'out_of_delivery': 'En route',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const _genericStatusLabelsZh = {
    'pending': '待处理',
    'processing': '进行中',
    'ready_to_delivery': '待出发',
    'out_of_delivery': '外勤中',
    'completed': '已完成',
    'cancelled': '已取消',
  };
}
