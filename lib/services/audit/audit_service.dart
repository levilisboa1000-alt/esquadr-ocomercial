import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/audit_log_model.dart';

class AuditService {
  final SupabaseClient _client;

  AuditService({required SupabaseClient client}) : _client = client;

  /// Registra uma ação sensível no banco de dados de auditoria
  Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? notes,
  }) async {
    try {
      final user = _client.auth.currentUser;
      final userName = user?.userMetadata?['full_name'] as String? ?? user?.email ?? 'Sistema';
      final roleStr = user?.userMetadata?['role'] as String?;

      await _client.from('audit_logs').insert({
        'user_id': user?.id,
        'user_name': userName,
        'role': roleStr,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_value': oldValue,
        'new_value': newValue ?? (notes != null ? {'notes': notes} : null),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Falha silenciosa no log de auditoria para não travar a experiência do usuário
      print('Erro ao registrar log de auditoria: $e');
    }
  }

  /// Recupera logs de auditoria recentes com paginação
  Future<List<AuditLogModel>> getRecentLogs({int limit = 50}) async {
    try {
      final response = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => AuditLogModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar logs de auditoria: $e');
      return [];
    }
  }
}
