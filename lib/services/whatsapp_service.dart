import 'package:url_launcher/url_launcher.dart';
import '../config/formatters.dart';
import '../models/cart_item.dart';
import '../models/retailer.dart';
import 'scheme_helper.dart';

class WhatsAppService {
  /// Builds the formatted B2B order message string
  static String buildOrderMessage({
    required String storeName,
    required Retailer retailer,
    required List<CartItem> items,
    required double totalPtr,
    required double totalMrp,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final dateStr = AppFormatters.formatIndianDateTime(now);
    final totalUnits = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalSavings = totalMrp - totalPtr;

    final buffer = StringBuffer();
    buffer.writeln('🛒 *WHOLESALE ORDER - $storeName*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🏪 *Retailer:* ${retailer.storeName}');
    buffer.writeln('📱 *Mobile:* ${AppFormatters.formatIndianMobile(retailer.mobile)}');
    if (retailer.route.isNotEmpty) {
      buffer.writeln('📍 *Route:* ${retailer.route}');
    }
    buffer.writeln('📅 *Date & Time (IST):* $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*ORDER ITEMS (${items.length}):*');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final p = item.product;
      final lineTotal = AppFormatters.formatCurrency(item.lineTotalPtr);
      final rate = AppFormatters.formatCurrency(p.ptr);
      final nudge = SchemeHelper.calculateNudge(
        scheme: p.scheme,
        currentQuantity: item.quantity,
        ptr: p.ptr,
        mrp: p.mrp,
      );

      buffer.writeln('${i + 1}. *${p.name}*');
      buffer.write('   • Billed Qty: *${item.quantity}* units');

      if (p.hasCartonPack) {
        final boxes = (item.quantity / p.cartonPack).toStringAsFixed(1).replaceAll('.0', '');
        buffer.write(' (Box: ${p.cartonPack}u ≈ ${boxes}b)');
      }

      if (nudge.earnedFreeUnits > 0) {
        buffer.write(' | 🎁 Bonus: *+${nudge.earnedFreeUnits} Free Units* (Total: ${item.quantity + nudge.earnedFreeUnits}u)');
      } else if (item.hasScheme) {
        buffer.write(' | Scheme: *${p.scheme}*');
      }
      buffer.writeln();

      if (nudge.hasBoostedMargin) {
        buffer.writeln('   • Rate: $rate | Eff. Rate: *${AppFormatters.formatCurrency(nudge.effectivePtr)}* | Line Total: *$lineTotal*');
      } else {
        buffer.writeln('   • Rate: $rate | Line Total: *$lineTotal*');
      }

      if (i < items.length - 1) {
        buffer.writeln();
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 *Total Lines:* ${items.length} ($totalUnits units)');
    buffer.writeln('💰 *Total Order Value (PTR):* *${AppFormatters.formatCurrency(totalPtr)}*');
    buffer.writeln('🏷️ *Total MRP Value:* ${AppFormatters.formatCurrency(totalMrp)}');
    if (totalSavings > 0) {
      buffer.writeln('🎉 *Retailer Margin/Savings:* *${AppFormatters.formatCurrency(totalSavings)}*');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('_Order generated via Wholesale Desk Portal_');

    return buffer.toString();
  }

  /// Generates the itemized B2B wholesale order text and launches WhatsApp
  static Future<bool> sendWholesaleOrder({
    required String targetPhone,
    required String storeName,
    required Retailer retailer,
    required List<CartItem> items,
    required double totalPtr,
    required double totalMrp,
  }) async {
    final message = buildOrderMessage(
      storeName: storeName,
      retailer: retailer,
      items: items,
      totalPtr: totalPtr,
      totalMrp: totalMrp,
    );

    // Clean phone number: remove any non-digit chars
    final cleanPhone = targetPhone.replaceAll(RegExp(r'\D'), '');
    final encodedText = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$cleanPhone?text=$encodedText';

    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      return false;
    }
  }
}
