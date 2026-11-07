import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/config/formatters.dart';
import 'package:wholesale_desk/models/cart_item.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/services/scheme_helper.dart';
import 'package:wholesale_desk/services/whatsapp_service.dart';
import 'package:wholesale_desk/state/cart_provider.dart';

void main() {
  group('SchemeHelper Parsing & Progressive Micro-Copy', () {
    test('parseThreshold extracts volume thresholds and ignores cash/percent/net-rate schemes', () {
      // Free Goods / Volume Tier Schemes -> Parsed
      expect(SchemeHelper.parseThreshold('20+1'), equals(20));
      expect(SchemeHelper.parseThreshold('20 Bags + 1 Free'), equals(20));
      expect(SchemeHelper.parseThreshold('12+1 Free'), equals(12));
      expect(SchemeHelper.parseThreshold('Buy 24 Get ₹100 Off'), equals(24));
      expect(SchemeHelper.parseThreshold('12+2 Special Scheme'), equals(12));

      // Cash Discounts, Percentages, and Net Rates -> Strictly 0 (No Apply Button)
      expect(SchemeHelper.parseThreshold('5% Cash Disc'), equals(0));
      expect(SchemeHelper.parseThreshold('3% Special Scheme'), equals(0));
      expect(SchemeHelper.parseThreshold('5% Scheme'), equals(0));
      expect(SchemeHelper.parseThreshold('Net Rate'), equals(0));
      expect(SchemeHelper.parseThreshold(''), equals(0));
    });

    test('Micro-copy is completely hidden at qty == 0', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: '10+1 Free',
        currentQuantity: 0,
        ptr: 400.0,
        mrp: 500.0,
      );

      expect(nudge.message, isEmpty);
      expect(nudge.hasScheme, isFalse);
    });

    test('Micro-copy is completely hidden for non-tiered schemes (e.g. 5% Cash Disc, Net Rate)', () {
      final nudgeDisc = SchemeHelper.calculateNudge(
        scheme: '5% Cash Disc',
        currentQuantity: 10,
        ptr: 400.0,
        mrp: 500.0,
      );
      expect(nudgeDisc.message, isEmpty);

      final nudgeNet = SchemeHelper.calculateNudge(
        scheme: 'Net Rate',
        currentQuantity: 10,
        ptr: 400.0,
        mrp: 500.0,
      );
      expect(nudgeNet.message, isEmpty);
    });

    test('Progressive micro-copy: Below qualifying tier (10+1, qty=7)', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: '10+1 Free',
        currentQuantity: 7,
        ptr: 400.0,
        mrp: 500.0,
      );

      expect(nudge.hasScheme, isTrue);
      expect(nudge.isQualified, isFalse);
      expect(nudge.unitsNeededForNext, equals(3));
      expect(nudge.nextFreeUnits, equals(1));
      expect(nudge.message, equals('Add 3 more to unlock +1 Free Unit'));
      expect(nudge.hasBoostedMargin, isFalse);
    });

    test('Progressive micro-copy: Exact threshold reached (10+1, qty=10)', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: '10+1 Free',
        currentQuantity: 10,
        ptr: 400.0,
        mrp: 500.0,
      );

      expect(nudge.hasScheme, isTrue);
      expect(nudge.isQualified, isTrue);
      expect(nudge.earnedFreeUnits, equals(1));
      expect(nudge.message, equals('✓ Scheme Unlocked: 1 Free Unit Applied'));
    });

    test('Progressive micro-copy: Multiples calculation (10+1, qty=20)', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: '10+1',
        currentQuantity: 20,
        ptr: 400.0,
        mrp: 500.0,
      );

      expect(nudge.hasScheme, isTrue);
      expect(nudge.isQualified, isTrue);
      expect(nudge.earnedFreeUnits, equals(2));
      expect(nudge.message, equals('✓ Scheme Unlocked: 2 Free Units Applied'));
    });
  });

  group('Dynamic Margin & Effective Unit Rate Math', () {
    test('Calculates base vs boosted margin when scheme is active', () {
      // Base: MRP = 500, PTR = 400. Base Margin = (500 - 400)/500 = 20.0%
      // Scheme: 10+1 Free. When qty = 10:
      // Total units received = 10 + 1 = 11.
      // Total billed cost = 10 * 400 = 4000.
      // Effective PTR = 4000 / 11 = 363.636...
      // Effective Margin = (500 - 363.636...) / 500 = 27.2727...%
      final nudge = SchemeHelper.calculateNudge(
        scheme: '10+1',
        currentQuantity: 10,
        ptr: 400.0,
        mrp: 500.0,
      );

      expect(nudge.baseMarginPercent, closeTo(20.0, 0.01));
      expect(nudge.effectivePtr, closeTo(363.64, 0.05));
      expect(nudge.effectiveMarginPercent, closeTo(27.27, 0.05));
      expect(nudge.hasBoostedMargin, isTrue);
    });

    test('No boosted margin when below scheme threshold', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: '10+1',
        currentQuantity: 5,
        ptr: 400.0,
        mrp: 500.0,
      );

      expect(nudge.effectivePtr, equals(400.0));
      expect(nudge.effectiveMarginPercent, equals(20.0));
      expect(nudge.hasBoostedMargin, isFalse);
    });
  });

  group('CartProvider 1-Tap Auto-Fill & Direct Zero-Reset', () {
    final testProduct = Product(
      id: 'p-sugar-50kg',
      name: 'Refined Sugar 50kg Bag',
      brand: 'Madhur',
      scheme: '20+1 Free',
      moq: 5,
      ptr: 1800.0,
      mrp: 2000.0,
      inStock: true,
    );

    test('1-Tap Scheme Direct Auto-Fill sets exact qualifying slab', () {
      final cart = CartProvider();
      expect(cart.isInCart(testProduct.id), isFalse);

      // 1-Tap Auto-Fill: threshold is 20
      cart.applyScheme(testProduct, 20);

      expect(cart.isInCart(testProduct.id), isTrue);
      expect(cart.getQuantity(testProduct.id), equals(20));
      expect(cart.subtotalPtr, equals(20 * 1800.0));
    });

    test('1-Tap Scheme Auto-Fill increments by slab if already at or above threshold', () {
      final cart = CartProvider();
      cart.applyScheme(testProduct, 20);
      expect(cart.getQuantity(testProduct.id), equals(20));

      // Second tap increments by another slab of 20
      cart.applyScheme(testProduct, 20);
      expect(cart.getQuantity(testProduct.id), equals(40));
    });

    test('Direct Item Deletion & Zero-Reset clears 50 units in exactly 1 tap', () {
      final cart = CartProvider();
      cart.addItem(testProduct);
      cart.updateQuantity(testProduct.id, 50);
      expect(cart.getQuantity(testProduct.id), equals(50));

      // Direct 1-tap delete
      cart.removeItem(testProduct.id);

      expect(cart.isInCart(testProduct.id), isFalse);
      expect(cart.getQuantity(testProduct.id), equals(0));
      expect(cart.itemCount, equals(0));
      expect(cart.subtotalPtr, equals(0.0));
    });

    test('When enforceMoq is true, decrementing below MOQ removes item', () {
      final cart = CartProvider();
      cart.addItem(testProduct, enforceMoq: true); // qty = 5
      cart.decrement(testProduct.id, enforceMoq: true); // drops below 5 -> removes

      expect(cart.isInCart(testProduct.id), isFalse);
    });

    test('When enforceMoq is false, decrementing allows units down to 1 before removal', () {
      final cart = CartProvider();
      cart.addItem(testProduct, enforceMoq: false); // qty = 1
      cart.increment(testProduct.id); // qty = 2
      expect(cart.getQuantity(testProduct.id), equals(2));

      cart.decrement(testProduct.id, enforceMoq: false); // drops to 1
      expect(cart.getQuantity(testProduct.id), equals(1));

      cart.decrement(testProduct.id, enforceMoq: false); // drops below 1 -> removes
      expect(cart.isInCart(testProduct.id), isFalse);
    });
  });

  group('WhatsApp B2B Serialization with Bonus Units & Eff. Rates', () {
    test('Builds order string detailing billed units, bonus free units, and agreed PTR', () {
      final retailer = Retailer(
        id: 'ret-101',
        storeName: 'Guwahati Kirana Store',
        mobile: '9876543210',
        pin: '1234',
        route: 'Fancy Bazaar',
      );

      final product = Product(
        id: 'p-tea-1',
        name: 'Tata Tea Gold 500g',
        brand: 'Tata',
        scheme: '10+1',
        moq: 5,
        cartonPack: 20,
        ptr: 250.0,
        mrp: 300.0,
        inStock: true,
      );

      final item = CartItem(product: product, quantity: 20); // 20 units -> 2 Free units
      final items = [item];
      final totalPtr = item.lineTotalPtr; // 20 * 250 = 5000.0
      final totalMrp = item.lineTotalMrp; // 20 * 300 = 6000.0

      final message = WhatsAppService.buildOrderMessage(
        storeName: 'Apex Wholesale Guwahati',
        retailer: retailer,
        items: items,
        totalPtr: totalPtr,
        totalMrp: totalMrp,
        timestamp: DateTime(2026, 11, 7, 18, 30),
      );

      // Verify Billed Quantity
      expect(message, contains('Billed Qty: *20* units'));
      // Verify Carton Pack breakdown
      expect(message, contains('(Box: 20u ≈ 1b)'));
      // Verify Free Scheme Bonus Units
      expect(message, contains('🎁 Bonus: *+2 Free Units* (Total: 22u)'));
      // Verify Effective Rate
      expect(message, contains('Eff. Rate:'));
      // Verify Line Total and Agreed PTR
      expect(message, contains('Line Total: *₹5,000.00*'));
      expect(message, contains('Total Order Value (PTR):* *₹5,000.00*'));
      expect(message, contains('Guwahati Kirana Store'));
      expect(message, contains('Fancy Bazaar'));
      // Verify Indian Date & Time (DD/MM/YYYY) and Mobile (+91)
      expect(message, contains('📅 *Date & Time (IST):* 07/11/2026, 06:30 PM'));
      expect(message, contains('📱 *Mobile:* +91 98765 43210'));
    });
  });

  group('Indian Business Formatting Standards (AppFormatters)', () {
    test('Formats Indian Rupee with Lakhs and Crores grouping', () {
      expect(AppFormatters.formatCurrency(100000.0), equals('₹1,00,000.00'));
      expect(AppFormatters.formatCurrency(1250.50), equals('₹1,250.50'));
    });

    test('Formats Indian standard date as DD/MM/YYYY', () {
      final date = DateTime(2026, 11, 7, 18, 58);
      expect(AppFormatters.formatIndianDate(date), equals('07/11/2026'));
      expect(AppFormatters.formatIndianDateTime(date), equals('07/11/2026, 06:58 PM'));
    });

    test('Formats 10-digit Indian mobile numbers with +91 and 5-5 split', () {
      expect(AppFormatters.formatIndianMobile('9876543210'), equals('+91 98765 43210'));
      expect(AppFormatters.formatIndianMobile('919876543210'), equals('+91 98765 43210'));
    });
  });
}
