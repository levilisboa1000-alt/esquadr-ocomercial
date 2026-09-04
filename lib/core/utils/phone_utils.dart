class PhoneUtils {
  /// Remove qualquer caractere não numérico
  static String cleanDigits(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Converte para o padrão internacional para a URL tel:
  /// Exemplo: "61999998888" -> "+5561999998888"
  static String toTelUri(String phone) {
    String digits = cleanDigits(phone);
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!digits.startsWith('55')) {
      digits = '55$digits';
    }
    return 'tel:+$digits';
  }

  /// Formata visualmente para padrão brasileiro:
  /// (XX) 9XXXX-XXXX ou (XX) XXXX-XXXX
  static String formatDisplay(String phone) {
    final digits = cleanDigits(phone);
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else if (digits.length == 13 && digits.startsWith('55')) {
      final local = digits.substring(2);
      return formatDisplay(local);
    }
    return phone;
  }

  /// Validação básica de telefone brasileiro
  static bool isValidBrazilianPhone(String phone) {
    final digits = cleanDigits(phone);
    if (digits.startsWith('55') && digits.length >= 12) {
      final without55 = digits.substring(2);
      return without55.length == 10 || without55.length == 11;
    }
    return digits.length == 10 || digits.length == 11;
  }
}
