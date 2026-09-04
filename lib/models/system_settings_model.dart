class SystemSettingsModel {
  final int voicemailReturnMinutes;
  final String distributionAlgorithm;
  final int maxDailyLeadsPerOperator;
  final DateTime updatedAt;

  SystemSettingsModel({
    this.voicemailReturnMinutes = 30,
    this.distributionAlgorithm = 'ROUND_ROBIN',
    this.maxDailyLeadsPerOperator = 50,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory SystemSettingsModel.fromMap(Map<String, dynamic> map) {
    return SystemSettingsModel(
      voicemailReturnMinutes: map['voicemail_return_minutes'] is int
          ? map['voicemail_return_minutes'] as int
          : int.tryParse(map['voicemail_return_minutes']?.toString() ?? '30') ?? 30,
      distributionAlgorithm: map['distribution_algorithm']?.toString() ?? 'ROUND_ROBIN',
      maxDailyLeadsPerOperator: map['max_daily_leads_per_operator'] is int
          ? map['max_daily_leads_per_operator'] as int
          : int.tryParse(map['max_daily_leads_per_operator']?.toString() ?? '50') ?? 50,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voicemail_return_minutes': voicemailReturnMinutes,
      'distribution_algorithm': distributionAlgorithm,
      'max_daily_leads_per_operator': maxDailyLeadsPerOperator,
    };
  }

  SystemSettingsModel copyWith({
    int? voicemailReturnMinutes,
    String? distributionAlgorithm,
    int? maxDailyLeadsPerOperator,
  }) {
    return SystemSettingsModel(
      voicemailReturnMinutes: voicemailReturnMinutes ?? this.voicemailReturnMinutes,
      distributionAlgorithm: distributionAlgorithm ?? this.distributionAlgorithm,
      maxDailyLeadsPerOperator: maxDailyLeadsPerOperator ?? this.maxDailyLeadsPerOperator,
      updatedAt: DateTime.now(),
    );
  }
}
