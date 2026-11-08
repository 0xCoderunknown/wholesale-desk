import 'package:url_launcher/url_launcher.dart';
import '../config/formatters.dart';
import '../models/cart_item.dart';
import '../models/retailer.dart';
import 'scheme_helper.dart';

class WhatsAppService {
  /// Builds the ultra-compact B2B order message string designed for wholesale billing clerks
  static String buildOrderMessage({
    required String storeName,
    required Retailer retailer,
    required List<CartItem> items,
    required double totalPtr,
    required double totalMrp,
    String? orderNotes,
    DateTime? timestamp,
  }) {
    final totalUnits = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final buffer = StringBuffer();

    final routePart = retailer.route.isNotEmpty ? ' (${retailer.route})' : '';
    final ts = timestamp ?? DateTime.now();
    final rawRadix = ts.millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final shortRefId = rawRadix.length >= 4
        ? rawRadix.substring(rawRadix.length - 4)
        : rawRadix.padLeft(4, '0');

    // Compressed 2-Line Identity Header (No heavy emojis for URL safety & ERP compatibility)
    buffer.writeln('*ORDER: ${retailer.storeName}$routePart*');
    buffer.writeln('Ref: #$shortRefId | Reg: ${retailer.phone}');
    buffer.writeln('--------------------------------');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final p = item.product;
      final nudge = SchemeHelper.calculateNudge(
        scheme: p.scheme,
        currentQuantity: item.quantity,
        ptr: p.ptr,
        mrp: p.mrp,
      );

      final schemeBonusText = nudge.earnedFreeUnits > 0
          ? '(+${nudge.earnedFreeUnits} Free) '
          : '';

      buffer.writeln('${i + 1}. ${p.name}');
      buffer.writeln('   ${item.quantity} pcs $schemeBonusText@ ${AppFormatters.formatCurrency(p.ptr)} = ${AppFormatters.formatCurrency(item.lineTotalPtr)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('*Total: ${AppFormatters.formatCurrency(totalPtr)} ($totalUnits units)*');

    if (orderNotes != null && orderNotes.trim().isNotEmpty) {
      buffer.writeln('Note: ${orderNotes.trim()}');
    }

    return buffer.toString().trim();
  }

  /// Alias for buildOrderMessage
  static String generateWhatsAppMessage({
    required String storeName,
    required Retailer retailer,
    required List<CartItem> items,
    required double totalPtr,
    required double totalMrp,
    String? orderNotes,
    DateTime? timestamp,
  }) {
    return buildOrderMessage(
      storeName: storeName,
      retailer: retailer,
      items: items,
      totalPtr: totalPtr,
      totalMrp: totalMrp,
      orderNotes: orderNotes,
      timestamp: timestamp,
    );
  }

  /// Generates the itemized B2B wholesale order text and launches WhatsApp
  static Future<bool> sendWholesaleOrder({
    required String targetPhone,
    required String storeName,
    required Retailer retailer,
    required List<CartItem> items,
    required double totalPtr,
    required double totalMrp,
    String? orderNotes,
  }) async {
    final message = buildOrderMessage(
      storeName: storeName,
      retailer: retailer,
      items: items,
      totalPtr: totalPtr,
      totalMrp: totalMrp,
      orderNotes: orderNotes,
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
