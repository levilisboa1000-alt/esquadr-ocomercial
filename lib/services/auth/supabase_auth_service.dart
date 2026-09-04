import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_enums.dart';
import '../../models/user_model.dart';
import '../audit/audit_service.dart';

class SupabaseAuthService {
  final SupabaseClient _client;
  final AuditService _auditService;

  UserModel? _currentUser;
  final _userController = StreamController<UserModel?>.broadcast();

  SupabaseAuthService({
    required SupabaseClient client,
    required AuditService auditService,
  })  : _client = client,
        _auditService = auditService {
    _initAuthListener();
  }

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get userStream => _userController.stream;
  bool get isAuthenticated => _currentUser != null;

  void _initAuthListener() {
    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await refreshProfile();
      } else {
        _currentUser = null;
        _userController.add(null);
      }
    });
  }

  /// Carrega ou atualiza os dados do perfil logado a partir da tabela profiles
  Future<UserModel?> refreshProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _currentUser = null;
      _userController.add(null);
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
      } else {
        // Se o perfil ainda não existe (gatilho de banco pendente), cria inicial
        _currentUser = UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String? ?? 'Usuário',
          role: UserRole.fromString(user.userMetadata?['role'] as String?),
        );
      }
      _userController.add(_currentUser);
      return _currentUser;
    } catch (e) {
      print('Erro ao carregar perfil: $e');
      return null;
    }
  }

  /// Login com e-mail e senha
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('Falha ao autenticar usuário');
    }

    final profile = await refreshProfile();
    if (profile == null) {
      throw Exception('Perfil de usuário não encontrado');
    }

    // Marca como online se for operador
    await setOnlineStatus(true);

    // Registra auditoria
    await _auditService.log(
      action: 'LOGIN',
      entityType: 'auth',
      entityId: profile.id,
      notes: 'Usuário ${profile.fullName} conectou-se ao sistema',
    );

    return profile;
  }

  /// Cadastro de novo usuário com papel (Admin, Supervisor ou Operador)
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'role': role.dbValue,
        'phone': phone,
      },
    );

    if (response.user == null) {
      throw Exception('Não foi possível criar o usuário');
    }

    final profile = await refreshProfile();
    return profile ??
        UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          role: role,
          phone: phone,
        );
  }

  /// Envia e-mail de redefinição de senha
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Altera o status online do operador
  Future<void> setOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;
    try {
      await _client
          .from('profiles')
          .update({'is_online': isOnline, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', _currentUser!.id);

      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      _userController.add(_currentUser);
    } catch (e) {
      print('Erro ao atualizar status online: $e');
    }
  }

  /// Logout seguro
  Future<void> signOut() async {
    if (_currentUser != null) {
      await setOnlineStatus(false);
      await _auditService.log(
        action: 'LOGOUT',
        entityType: 'auth',
        entityId: _currentUser!.id,
        notes: 'Usuário ${_currentUser!.fullName} desconectou-se',
      );
    }
    await _client.auth.signOut();
    _currentUser = null;
    _userController.add(null);
  }

  void dispose() {
    _userController.close();
  }
}
