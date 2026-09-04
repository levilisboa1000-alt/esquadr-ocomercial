class TeamModel {
  final String id;
  final String name;
  final String? supervisorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamModel({
    required this.id,
    required this.name,
    this.supervisorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Equipe',
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'supervisor_id': supervisorId,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
