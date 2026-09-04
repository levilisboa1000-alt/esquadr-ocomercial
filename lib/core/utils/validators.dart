import 'phone_utils.dart';

class Validators {
  static String? requiredField(String? value, [String message = 'Campo obrigatório']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'A senha deve conter no mínimo 6 caracteres';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o telefone';
    }
    if (!PhoneUtils.isValidBrazilianPhone(value)) {
      return 'Telefone inválido (deve conter DDD + 8 ou 9 dígitos)';
    }
    return null;
  }
}
