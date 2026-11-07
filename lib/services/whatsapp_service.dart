import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_item.dart';
import '../models/retailer.dart';

class WhatsAppService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Generates the itemized B2B wholesale order text and launches WhatsApp
  static Future<bool> sendWholesaleOrder({
    required String targetPhone,
    required String storeName,
    required Retailer retailer,
    required List<CartItem> items,
    required double totalPtr,
    required double totalMrp,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    final totalUnits = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalSavings = totalMrp - totalPtr;

    final buffer = StringBuffer();
    buffer.writeln('🛒 *WHOLESALE ORDER - $storeName*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🏪 *Retailer:* ${retailer.storeName}');
    buffer.writeln('📱 *Mobile:* ${retailer.mobile}');
    if (retailer.route.isNotEmpty) {
      buffer.writeln('📍 *Route:* ${retailer.route}');
    }
    buffer.writeln('📅 *Time:* $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*ORDER ITEMS (${items.length}):*');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final p = item.product;
      final lineTotal = _currencyFormat.format(item.lineTotalPtr);
      final rate = _currencyFormat.format(p.ptr);

      buffer.writeln('${i + 1}. *${p.name}*');
      buffer.write('   • Qty: *${item.quantity}* units (MOQ: ${p.moq}');
      if (p.hasCartonPack) {
        final boxes = (item.quantity / p.cartonPack).toStringAsFixed(1).replaceAll('.0', '');
        buffer.write(' | Box: ${p.cartonPack}u ≈ ${boxes}b');
      }
      buffer.write(')');
      if (item.hasScheme) {
        buffer.write(' | Scheme: *${p.scheme}*');
      }
      buffer.writeln();
      buffer.writeln('   • Rate: $rate | Total: *$lineTotal*');
      if (i < items.length - 1) {
        buffer.writeln();
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 *Total Lines:* ${items.length} ($totalUnits units)');
    buffer.writeln('💰 *Total Order Value (PTR):* *${_currencyFormat.format(totalPtr)}*');
    buffer.writeln('🏷️ *Total MRP Value:* ${_currencyFormat.format(totalMrp)}');
    if (totalSavings > 0) {
      buffer.writeln('🎉 *Retailer Margin/Savings:* *${_currencyFormat.format(totalSavings)}*');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('_Order generated via Wholesale Desk Portal_');

    // Clean phone number: remove any non-digit chars
    final cleanPhone = targetPhone.replaceAll(RegExp(r'\D'), '');
    final encodedText = Uri.encodeComponent(buffer.toString());
    final urlString = 'https://wa.me/$cleanPhone?text=$encodedText';

    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      return false;
    }
  }
}
