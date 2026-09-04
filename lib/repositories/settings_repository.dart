import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/system_settings_model.dart';

class SettingsRepository {
  final SupabaseClient _supabase;

  SettingsRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Carrega as configurações globais da tabela system_settings
  Future<SystemSettingsModel> getSettings() async {
    try {
      final response = await _supabase.from('system_settings').select();
      final map = <String, dynamic>{};

      for (final row in (response as List)) {
        final key = row['key'] as String;
        final value = row['value'];
        map[key] = value;
      }

      return SystemSettingsModel.fromMap(map);
    } catch (e) {
      print('Aviso: usando configurações padrão de fallback: $e');
      return SystemSettingsModel();
    }
  }

  /// Salva ou atualiza uma configuração específica
  Future<void> updateSetting(String key, dynamic value) async {
    await _supabase.from('system_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
