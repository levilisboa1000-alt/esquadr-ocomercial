import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyBrl = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatCurrency(num value) {
    return _currencyBrl.format(value);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date.toLocal());
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date.toLocal());
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date.toLocal());
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      final pastDiff = difference.abs();
      if (pastDiff.inMinutes < 1) return 'agora';
      if (pastDiff.inMinutes < 60) return 'há ${pastDiff.inMinutes}m';
      if (pastDiff.inHours < 24) return 'há ${pastDiff.inHours}h';
      return 'há ${pastDiff.inDays}d';
    } else {
      if (difference.inMinutes < 1) return 'em instantes';
      if (difference.inMinutes < 60) return 'em ${difference.inMinutes}m';
      if (difference.inHours < 24) return 'em ${difference.inHours}h';
      return 'em ${difference.inDays}d';
    }
  }
}
