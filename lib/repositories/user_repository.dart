import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../core/constants/app_enums.dart';

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Retorna todos os usuários/operadores do sistema
  Future<List<UserModel>> getUsers({UserRole? roleFilter}) async {
    var query = _supabase.from('profiles').select();
    if (roleFilter != null) {
      query = query.eq('role', roleFilter.dbValue);
    }
    final response = await query.order('full_name', ascending: true);

    return (response as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Atualiza o papel de um usuário (Admin, Supervisor, Operador)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _supabase
        .from('profiles')
        .update({
          'role': newRole.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Calcula métricas reais de produtividade para cada operador a partir do banco
  Future<List<OperatorProductivityModel>> getOperatorProductivityList() async {
    final users = await getUsers(roleFilter: UserRole.operator);
    final productivityList = <OperatorProductivityModel>[];

    for (final op in users) {
      // Leads atribuídos
      final assignedRes = await _supabase
          .from('leads')
          .select('id')
          .eq('assigned_operator_id', op.id);
      final leadsCount = (assignedRes as List).length;

      // Chamadas efetuadas
      final callsRes = await _supabase
          .from('calls')
          .select('id, result')
          .eq('operator_id', op.id);
      final callsList = (callsRes as List);
      final callsCount = callsList.length;

      int callsAnswered = 0;
      int voicemailCount = 0;
      int rejectedCount = 0;

      for (final call in callsList) {
        final resStr = call['result']?.toString();
        if (resStr == 'atendeu' || resStr == 'interessado' || resStr == 'agendamento') {
          callsAnswered++;
        } else if (resStr == 'caixa_postal') {
          voicemailCount++;
        } else if (resStr == 'nao_interessado') {
          rejectedCount++;
        }
      }

      // Agendamentos criados
      final apptRes = await _supabase
          .from('appointments')
          .select('id')
          .eq('operator_id', op.id);
      final apptCount = (apptRes as List).length;

      productivityList.add(OperatorProductivityModel.fromCalculated(
        operatorId: op.id,
        operatorName: op.fullName,
        leadsReceived: leadsCount,
        leadsProcessed: callsCount,
        callsMade: callsCount,
        callsAnswered: callsAnswered,
        voicemailCount: voicemailCount,
        rejectedCount: rejectedCount,
        appointmentsCreated: apptCount,
        isOnline: op.isOnline,
      ));
    }

    // Ordena pelo maior número de agendamentos e chamadas
    productivityList.sort((a, b) => b.appointmentsCreated.compareTo(a.appointmentsCreated));
    return productivityList;
  }
}
