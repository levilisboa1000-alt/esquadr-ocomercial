import 'package:flutter/material.dart';
import '../../../core/config/env_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../services/auth/supabase_auth_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_text_field.dart';

class LoginScreen extends StatefulWidget {
  final SupabaseAuthService authService;
  final Function(UserModel user) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.operator;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final user = await widget.authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: _selectedRole,
        );
        widget.onLoginSuccess(user);
      } else {
        final user = await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        widget.onLoginSuccess(user);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordModal() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundStart,
        title: const Text("Recuperar Senha", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Informe seu e-mail para receber as instruções de recuperação:",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            GlassTextField(
              controller: emailCtrl,
              hint: "exemplo@empresa.com",
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await widget.authService.sendPasswordReset(email);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.actionRight,
                    content: Text('E-mail de recuperação enviado com sucesso!'),
                  ),
                );
              }
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              borderRadius: 32,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.actionUp.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.actionUp.withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, color: AppColors.actionUp, size: 42),
                    ),
                    const SizedBox(height: 18),

                    // Logotipo
                    const Text(
                      "ESQUADRÃO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Text(
                      "COMERCIAL",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Plataforma Operacional de Telemarketing",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),

                    // Aviso de Configuração se .env não estiver preenchido
                    if (!EnvConfig.isSupabaseConfigured) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.actionLeft.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.actionLeft.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.actionLeft, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Configure seu SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env para autenticação em produção.",
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Erro
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.actionDown.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.actionDown.withOpacity(0.4)),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.actionDown, fontSize: 12),
                        ),
                      ),
                    ],

                    // Campos
                    if (_isSignUp) ...[
                      GlassTextField(
                        controller: _fullNameController,
                        label: "Nome Completo",
                        hint: "Ex: Carlos Oliveira",
                        prefixIcon: Icons.person_outline,
                        validator: Validators.requiredField,
                      ),
                      const SizedBox(height: 14),
                      // Seletor de Role
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Função", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.glassBackgroundLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<UserRole>(
                                value: _selectedRole,
                                isExpanded: true,
                                dropdownColor: AppColors.backgroundStart,
                                style: const TextStyle(color: Colors.white),
                                items: UserRole.values.map((r) {
                                  return DropdownMenuItem(value: r, child: Text(r.label));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    GlassTextField(
                      controller: _emailController,
                      label: "E-mail Corporativo",
                      hint: "operador@empresa.com",
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),

                    GlassTextField(
                      controller: _passwordController,
                      label: "Senha de Acesso",
                      hint: "••••••••",
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: Validators.password,
                    ),

                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordModal,
                          child: const Text(
                            "Esqueci minha senha",
                            style: TextStyle(color: AppColors.actionUp, fontSize: 12),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 16),

                    const SizedBox(height: 12),

                    // Botão Principal
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isSignUp ? "Criar Conta Operacional" : "Entrar no Sistema",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alternar entre Login e Cadastro
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? "Já possui uma conta? Entrar"
                            : "Não tem acesso? Criar nova conta",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
