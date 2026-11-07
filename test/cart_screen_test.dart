import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/config/theme.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/services/whatsapp_service.dart';
import 'package:wholesale_desk/state/auth_provider.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/state/desk_provider.dart';
import 'package:wholesale_desk/views/retailer/retailer_cart_screen.dart';

Widget buildTestableWidget({
  required Widget child,
  CartProvider? cartProvider,
  AuthProvider? authProvider,
  DeskProvider? deskProvider,
  Size surfaceSize = const Size(1280, 800),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider ?? AuthProvider()),
      ChangeNotifierProvider<CartProvider>.value(value: cartProvider ?? CartProvider()),
      ChangeNotifierProvider<DeskProvider>.value(value: deskProvider ?? DeskProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: child,
      ),
    ),
  );
}

void main() {
  final retailer = Retailer(
    id: 'ret_101',
    storeName: 'Guwahati Supermart',
    mobile: '9876543210',
    pin: '1234',
    route: 'Central Market',
    status: 'active',
  );

  final productBox = Product(
    id: 'p1',
    name: 'Surf Excel Detergent Powder 1kg',
    brand: 'Hindustan Unilever',
    ptr: 150.0,
    mrp: 180.0,
    moq: 6,
    cartonPack: 24,
    scheme: '10+1 Free',
    inStock: true,
  );

  final productLoose = Product(
    id: 'p2',
    name: 'Dove Moisture Shampoo 180ml',
    brand: 'Hindustan Unilever',
    ptr: 120.0,
    mrp: 145.0,
    moq: 4,
    cartonPack: 12,
    scheme: '',
    inStock: true,
  );

  group('CartProvider Wholesale & Packaging Domain Getters', () {
    test('Calculates cartons, loose units, earned free goods, and near-scheme items', () {
      final cart = CartProvider();

      // Add 26 units of productBox (cartonPack: 24, scheme: 10+1 Free)
      cart.addItem(productBox);
      cart.updateQuantity(productBox.id, 26);

      // Add 5 units of productLoose (cartonPack: 12)
      cart.addItem(productLoose);
      cart.updateQuantity(productLoose.id, 5);

      // Total boxes = (26 ~/ 24) + (5 ~/ 12) = 1 + 0 = 1
      expect(cart.totalBoxes, equals(1));

      // Loose units = (26 % 24) + (5 % 12) = 2 + 5 = 7
      expect(cart.totalLooseUnits, equals(7));

      // 26 units with 10+1 Free -> 2 full sets of 10 -> 2 free units
      expect(cart.totalEarnedFreeUnits, equals(2));
      expect(cart.totalFreeGoodsValue, equals(2 * 150.0));

      // Now set productBox quantity to 9 (threshold 10, diff = 1) -> should be near scheme!
      cart.updateQuantity(productBox.id, 9);
      expect(cart.itemsNearScheme.length, equals(1));
      expect(cart.itemsNearScheme.first.product.id, equals(productBox.id));
    });
  });

  group('WhatsApp Service Order Message with Notes & Packaging', () {
    test('Includes packaging breakdown and delivery notes in formatted WhatsApp message', () {
      final cart = CartProvider();
      cart.addItem(productBox);
      cart.updateQuantity(productBox.id, 48); // 2 full boxes

      final message = WhatsAppService.buildOrderMessage(
        storeName: 'Test Distributor',
        retailer: retailer,
        items: cart.items,
        totalPtr: cart.subtotalPtr,
        totalMrp: cart.totalMrp,
        orderNotes: 'Deliver by 10 AM sharp via tempo',
      );

      expect(message, contains('Guwahati Supermart'));
      expect(message, contains('Central Market'));
      expect(message, contains('Packaging Breakdown:* 2 Cartons + 0 Loose Units'));
      expect(message, contains('Retailer Remarks / Instructions:'));
      expect(message, contains('Deliver by 10 AM sharp via tempo'));
      expect(message, contains('🎁 *Bonus Free Goods:*'));
    });
  });

  group('RetailerCartScreen Desktop & Mobile Experience', () {
    testWidgets('Desktop view (1280px) renders Proforma Invoice Table and Summary Dock',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      cart.addItem(productBox);
      cart.updateQuantity(productBox.id, 9); // near scheme threshold 10

      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          surfaceSize: const Size(1280, 800),
          child: RetailerCartScreen(retailer: retailer),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar title & counter badge
      expect(find.text('Wholesale Order Desk'), findsOneWidget);
      expect(find.text('1 items • 9u'), findsOneWidget);

      // Scheme Maximizer Alert Strip is visible because 9 units is near 10
      expect(find.textContaining('within reach of Free Bonus Units'), findsOneWidget);

      // Proforma Invoice Table Headers
      expect(find.text('#'), findsOneWidget);
      expect(find.text('Product & Specification'), findsOneWidget);
      expect(find.text('Wholesale Rate'), findsOneWidget);
      expect(find.text('Billed Qty'), findsOneWidget);
      expect(find.text('Line Total (PTR)'), findsOneWidget);

      // Table line item content
      expect(find.text(productBox.name), findsOneWidget);
      expect(find.text(productBox.brand), findsOneWidget);
      expect(find.text('Box: 24'), findsOneWidget);

      // Right-hand Summary Dock
      expect(find.text('Order Valuation Summary'), findsOneWidget);
      expect(find.text('Packaging Estimate:'), findsOneWidget);
      expect(find.text('Send Order on WhatsApp'), findsOneWidget);
      expect(find.text('Delivery Instructions / Remarks (Optional):'), findsOneWidget);

      // In-cart instant search filters table
      await tester.enterText(find.byType(TextField).first, 'Dove');
      await tester.pumpAndSettle();
      expect(find.text('No items match "Dove"'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Surf');
      await tester.pumpAndSettle();
      expect(find.text(productBox.name), findsOneWidget);
    });

    testWidgets('Mobile view (<768px) renders high-density cards and sticky bottom dock',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844)); // iPhone size
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      cart.addItem(productBox);
      cart.updateQuantity(productBox.id, 24);

      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          surfaceSize: const Size(390, 844),
          child: RetailerCartScreen(retailer: retailer),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile card displays product and carton equivalence
      expect(find.text(productBox.name), findsOneWidget);
      expect(find.text('≈ 1 Box(es)'), findsOneWidget);

      // Sticky bottom action dock is visible
      expect(find.text('Send Order on WhatsApp'), findsOneWidget);
      expect(find.textContaining('Total: 1 items (24u)'), findsOneWidget);
    });
  });
}
