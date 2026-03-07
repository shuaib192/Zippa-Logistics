import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
    locale: 'en_NG',
  );

  static String format(dynamic amount) {
    double value = 0.0;
    if (amount is double) {
      value = amount;
    } else if (amount is int) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }
    return _nairaFormat.format(value);
  }

  static String formatWithComma(dynamic amount) {
    if (amount == null) return '₦0.00';
    
    double value = 0.0;
    if (amount is double) {
      value = amount;
    } else if (amount is int) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    // This uses the default locale configuration for comma separation
    final formatter = NumberFormat("#,##0.00", "en_US");
    return '₦${formatter.format(value)}';
  }
}
