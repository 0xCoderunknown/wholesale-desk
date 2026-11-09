import 'package:intl/intl.dart';

/// Centralized Indian business formatting standards across the application:
/// - Currency (₹ / en_IN lakh-crore system)
/// - Universal Indian Date Formats (DD/MM/YYYY)
/// - Indian 10-Digit Mobile format (+91 XXXXX XXXXX)
/// - B2B Case/Carton packing representations
class AppFormatters {
  // 1. Indian Currency Formatter (₹) with Lakhs & Crores grouping (#,##,##0.00)
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat compactCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String formatCurrency(double value) => currency.format(value);

  static String formatRate(double value) => currency.format(value);

  static String formatPercent(double value, {int decimals = 1}) =>
      '+${value.toStringAsFixed(decimals)}%';

  // 2. Indian Date & Time Formats (Strict Indian DD-MM-YYYY / DD-MM-YY / DD/MM/YYYY standards)
  static final DateFormat indianDateHyphen = DateFormat('dd-MM-yyyy');
  static final DateFormat indianDateShort = DateFormat('dd-MM-yy');
  static final DateFormat indianDate = DateFormat('dd/MM/yyyy');
  static final DateFormat indianDateTime = DateFormat('dd-MM-yyyy, hh:mm a');
  static final DateFormat indianDateLong = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatIndianDate(DateTime? date, {bool hyphen = false}) {
    if (date == null) return '-';
    return hyphen ? indianDateHyphen.format(date) : indianDate.format(date);
  }

  static String formatIndianDateShort(DateTime? date) {
    if (date == null) return '-';
    return indianDateShort.format(date);
  }

  static String formatIndianDateTime(DateTime? date) {
    if (date == null) return '-';
    return indianDateTime.format(date);
  }

  static String formatIndianDateLong(DateTime? date) {
    if (date == null) return '-';
    return indianDateLong.format(date);
  }

  // 3. Indian Mobile Number Formatter (+91 XXXXX XXXXX)
  static String formatIndianMobile(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    } else if (clean.length == 12 && clean.startsWith('91')) {
      return '+91 ${clean.substring(2, 7)} ${clean.substring(7)}';
    }
    return mobile;
  }

  // 4. Case/Carton packing representation in Indian wholesale
  static String formatCarton(int quantity, int cartonPack) {
    if (cartonPack <= 0) return '';
    final boxes = (quantity / cartonPack).toStringAsFixed(1).replaceAll('.0', '');
    return 'Box: ${cartonPack}u ≈ ${boxes}b';
  }
}
