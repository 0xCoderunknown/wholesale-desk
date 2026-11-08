import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/config/theme.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/services/whatsapp_service.dart';
import 'package:wholesale_desk/state/auth_provider.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/state/desk_provider.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_data_table.dart';
import 'package:wholesale_desk/views/retailer/retailer_cart_screen.dart';
import 'package:wholesale_desk/views/widgets/catalog_quantity_stepper.dart';

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
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        }
        return null;
      },
    );
  });

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
    test('Includes compact format and delivery notes in formatted WhatsApp message', () {
      final cart = CartProvider();
      cart.addItem(productBox);
      cart.updateQuantity(productBox.id, 48); // 4 full scheme cycles (10+1 -> +4 free)

      final message = WhatsAppService.buildOrderMessage(
        storeName: 'Test Distributor',
        retailer: retailer,
        items: cart.items,
        totalPtr: cart.subtotalPtr,
        totalMrp: cart.totalMrp,
        orderNotes: 'Deliver by 10 AM sharp via tempo',
      );

      expect(message, contains('*ORDER: Guwahati Supermart (Central Market)*'));
      expect(message, contains('Ref: #'));
      expect(message, contains('Reg: 9876543210'));
      expect(message, contains('--------------------------------'));
      expect(message, contains('1. Surf Excel Detergent Powder 1kg'));
      expect(message, contains('48 pcs (+4 Free) @ ₹150.00 = ₹7,200.00'));
      expect(message, contains('*Total: ₹7,200.00 (48 units)*'));
      expect(message, contains('Note: Deliver by 10 AM sharp via tempo'));
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

      // Top bar title & single identity header & clear action
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Cart (1)'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Ordering for: Guwahati Supermart · Central Market'), findsOneWidget);

      // Scheme Maximizer Alert Strip is visible because 9 units is near 10
      expect(find.textContaining('within reach of Free Bonus Units'), findsOneWidget);

      // Proforma Invoice Table Headers
      expect(find.text('#'), findsOneWidget);
      expect(find.text('Product & Brand'), findsOneWidget);
      expect(find.text('PTR Rate'), findsOneWidget);
      expect(find.text('Order Quantity & Scheme'), findsOneWidget);
      expect(find.text('Line Total'), findsOneWidget);

      // Table line item content (prefixes removed)
      expect(find.textContaining(productBox.name), findsOneWidget);
      expect(find.text('₹150.00'), findsOneWidget);
      expect(find.text('₹1,350.00'), findsWidgets);

      // Right-hand Summary Dock
      expect(find.text('Order Valuation Summary'), findsOneWidget);
      expect(find.text('Total Items:'), findsOneWidget);
      expect(find.text('1 (9 billed)'), findsOneWidget);
      expect(find.text('Total Payable (PTR):'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Send Order on WhatsApp'), findsOneWidget);

      // Verify Copy Order fallback button copies and shows snackbar
      await tester.tap(find.text('Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Order text copied to clipboard!'), findsOneWidget);
      await tester.pumpAndSettle(); // Settle remaining snackbar animations

      // Verify Clear Cart confirmation dialog
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Clear Cart?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Clear Cart?'), findsNothing);
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

      // Mobile card displays product name, brand, PTR, and total price
      expect(find.textContaining(productBox.name), findsOneWidget);
      expect(find.text('PTR: ₹150.00'), findsOneWidget);
      expect(find.text('₹3,600.00'), findsWidgets);

      // Sticky bottom action dock has Copy fallback and WhatsApp CTA
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Send on WhatsApp'), findsOneWidget);
      expect(find.text('Send Order on WhatsApp'), findsNothing);
      expect(find.text('Total Payable'), findsWidgets);

      // Verify Copy on mobile triggers clipboard copy and snackbar
      await tester.tap(find.text('Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Order text copied to clipboard!'), findsOneWidget);
      await tester.pumpAndSettle();

      // Verify ListView bottom padding is 90px for scroll safety above sticky bottom bar
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect((listView.padding as EdgeInsets).bottom, equals(90.0));
    });

    testWidgets('CatalogDataTable on Desktop: hitting Add to Cart brings [-]MOQ[+][dustbin], hitting scheme brings [-]scheme_val[+][dustbin]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          surfaceSize: const Size(1280, 800),
          child: Scaffold(
            body: CatalogDataTable(
              products: [productBox], // moq: 6, scheme: '10+1 Free'
              enforceMoq: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows 'Add to Cart' button
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byType(CatalogQuantityStepper), findsNothing);
      expect(find.text('1 Box (24)'), findsOneWidget); // 1-Tap carton box bulk buy button

      // Hit '1 Box (24)' -> immediately sets cart quantity to 24 (1 box) and switches to stepper
      await tester.ensureVisible(find.text('1 Box (24)'));
      await tester.tap(find.text('1 Box (24)'));
      await tester.pumpAndSettle();

      expect(cart.getQuantity(productBox.id), equals(24));
      expect(find.byType(CatalogQuantityStepper), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('REMOVE'), findsOneWidget); // 24 >= 10 scheme threshold

      // Clear cart using Dustbin -> restores initial state
      await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded));
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(cart.getQuantity(productBox.id), equals(0));
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);

      // Hit 'Add to Cart' -> immediately switches to Stepper with MOQ (6) and dustbin
      await tester.ensureVisible(find.text('Add to Cart'));
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Cart'), findsNothing);
      expect(find.byType(CatalogQuantityStepper), findsOneWidget);
      expect(find.text('6'), findsOneWidget); // MOQ value
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget); // Dustbin icon

      // Hit Scheme 'APPLY' -> updates quantity to scheme threshold (10) in the stepper, and button changes to 'REMOVE'
      expect(find.text('APPLY'), findsOneWidget);
      await tester.ensureVisible(find.text('APPLY'));
      await tester.tap(find.text('APPLY'));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogQuantityStepper), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Scheme threshold value
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('REMOVE'), findsOneWidget); // Scheme pill changes to REMOVE

      // Hit 'REMOVE' on scheme pill -> undoes scheme / removes the whole lot, returns to 'Add to Cart'
      await tester.ensureVisible(find.text('REMOVE'));
      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byType(CatalogQuantityStepper), findsNothing);
      expect(find.text('APPLY'), findsOneWidget);
    });
  });
}
