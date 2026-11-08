import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/config/theme.dart';
import 'package:wholesale_desk/models/app_settings.dart';
import 'package:wholesale_desk/models/cart_item.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/services/repository_manager.dart';
import 'package:wholesale_desk/services/whatsapp_service.dart';
import 'package:wholesale_desk/state/auth_provider.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/state/desk_provider.dart';
import 'package:wholesale_desk/views/retailer/retailer_catalog_screen.dart';
import 'package:wholesale_desk/views/salesman/salesman_route_bar.dart';

void main() {
  final sampleProduct = Product(
    id: 'prod_surf_1kg',
    name: 'Surf Excel Quick Wash 1kg',
    brand: 'Hindustan Unilever',
    mrp: 180.0,
    ptr: 150.0,
    scheme: '10+1 Free',
    moq: 6,
    cartonPack: 24,
    inStock: true,
  );

  final retailerA = Retailer(
    id: 'ret_1',
    storeName: 'Gupta Provision Store',
    mobile: '9876543210',
    pin: '1234',
    route: 'Central Market Route',
    status: 'active',
  );

  final retailerB = Retailer(
    id: 'ret_2',
    storeName: 'New Bharat Traders',
    mobile: '9876500001',
    pin: '4321',
    route: 'Station Road Route',
    status: 'active',
  );

  Widget buildTestableWidget({
    required Widget child,
    CartProvider? cartProvider,
    AuthProvider? authProvider,
    DeskProvider? deskProvider,
    Size surfaceSize = const Size(390, 844),
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

  setUp(() async {
    await RepositoryManager.instance.initialize();
  });

  group('Field Salesman Authentication & Settings Domain', () {
    test('AppSettings has default salesmanPin of 3344 and serializes correctly', () {
      final settings = AppSettings.defaults();
      expect(settings.salesmanPin, equals('3344'));

      final map = settings.toMap();
      expect(map['salesman_pin'], equals('3344'));

      final parsed = AppSettings.fromMap(map);
      expect(parsed.salesmanPin, equals('3344'));
    });

    test('RepositoryManager recognizes salesmanPin 3344 and returns salesman role', () async {
      final result = await RepositoryManager.instance.verifyDeskPin('3344');
      expect(result['success'], isTrue);
      expect(result['role'], equals('salesman'));
    });

    test('AuthProvider logs in as UserRole.salesman with activeSalesmanName and switches retailer', () async {
      final auth = AuthProvider();
      final success = await auth.loginWithPin('3344');

      expect(success, isTrue);
      expect(auth.isSalesman, isTrue);
      expect(auth.role, equals(UserRole.salesman));
      expect(auth.activeSalesmanName, equals('Salesman'));

      // Switch retailer
      auth.switchSalesmanRetailer(retailerB);
      expect(auth.currentRetailer?.id, equals('ret_2'));
      expect(auth.currentRetailer?.storeName, equals('New Bharat Traders'));

      // Set custom salesman name
      auth.setSalesmanName('Ramesh Kumar');
      expect(auth.activeSalesmanName, equals('Ramesh Kumar'));

      // Logout resets salesman fields
      auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.isSalesman, isFalse);
      expect(auth.activeSalesmanName, isNull);
    });
  });

  group('WhatsApp Payload Watermark with Booked By', () {
    test('Includes Booked by watermark line in WhatsApp order string when provided', () {
      final message = WhatsAppService.buildOrderMessage(
        storeName: 'Apex Wholesale',
        retailer: retailerA,
        items: [CartItem(product: sampleProduct, quantity: 12)],
        totalPtr: 1800.0,
        totalMrp: 2160.0,
        bookedBy: 'Ramesh Kumar (Salesman)',
      );

      expect(message, contains('*ORDER: Gupta Provision Store (Central Market Route)*'));
      expect(message, contains('Ref: #'));
      expect(message, contains('Reg: 9876543210'));
      expect(message, contains('Booked by: Ramesh Kumar (Salesman)'));
      expect(message, contains('--------------------------------'));
      expect(message, contains('*Total: ₹1,800.00 (12 units)*'));
    });

    test('Omits Booked by line when bookedBy is null (direct retailer self-checkout)', () {
      final message = WhatsAppService.buildOrderMessage(
        storeName: 'Apex Wholesale',
        retailer: retailerA,
        items: [CartItem(product: sampleProduct, quantity: 6)],
        totalPtr: 900.0,
        totalMrp: 1080.0,
      );

      expect(message, contains('*ORDER: Gupta Provision Store (Central Market Route)*'));
      expect(message, isNot(contains('Booked by:')));
    });
  });

  group('SalesmanRouteBar & Cart Isolation Guard', () {
    testWidgets('SalesmanRouteBar renders in Salesman Mode and switches retailer immediately when cart is empty',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      await auth.loginWithPin('3344');
      auth.switchSalesmanRetailer(retailerA);

      final cart = CartProvider();
      final desk = DeskProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          cartProvider: cart,
          deskProvider: desk,
          child: RetailerCatalogScreen(retailer: retailerA),
        ),
      );
      await tester.pumpAndSettle();

      // SalesmanRouteBar is visible
      expect(find.byType(SalesmanRouteBar), findsOneWidget);
      expect(find.textContaining('Gupta Provision Store'), findsWidgets);

      // Open shop picker bottom sheet
      await tester.tap(find.textContaining('Shop: Gupta Provision Store'));
      await tester.pumpAndSettle();

      expect(find.text('Select Retailer on Beat'), findsOneWidget);

      // Tap New Bharat Traders
      await tester.tap(find.text('New Bharat Traders'));
      await tester.pumpAndSettle();

      // Successfully switched shop immediately (0 items in cart, no confirmation prompt)
      expect(find.text('Switch Active Shop?'), findsNothing);
      expect(auth.currentRetailer?.id, equals('ret_2'));
      expect(find.textContaining('New Bharat Traders'), findsWidgets);
    });

    testWidgets('Cart Isolation Guard prompts confirmation when switching shops with active cart items',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      await auth.loginWithPin('3344');
      auth.switchSalesmanRetailer(retailerA);

      final cart = CartProvider();
      cart.addItem(sampleProduct); // 6 units added to cart for Shop A
      expect(cart.itemCount, equals(1));

      final desk = DeskProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          cartProvider: cart,
          deskProvider: desk,
          child: RetailerCatalogScreen(retailer: retailerA),
        ),
      );
      await tester.pumpAndSettle();

      // Open shop picker
      await tester.tap(find.textContaining('Shop: Gupta Provision Store'));
      await tester.pumpAndSettle();

      // Tap New Bharat Traders
      await tester.tap(find.text('New Bharat Traders'));
      await tester.pumpAndSettle();

      // Cart Isolation Guard prompt appears
      expect(find.text('Switch Active Shop?'), findsOneWidget);
      expect(find.textContaining('Active Cart has 1 item(s) for Gupta Provision Store'), findsOneWidget);
      expect(find.text('Keep Cart'), findsOneWidget);
      expect(find.text('Clear & Switch'), findsOneWidget);

      // Tap 'Keep Cart' cancels switch
      await tester.tap(find.text('Keep Cart'));
      await tester.pumpAndSettle();

      expect(auth.currentRetailer?.id, equals('ret_1')); // Shop A retained
      expect(cart.itemCount, equals(1)); // Items kept

      // Open shop picker again and choose 'Clear & Switch'
      await tester.tap(find.textContaining('Shop: Gupta Provision Store'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Bharat Traders'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Active Shop?'), findsOneWidget);
      await tester.tap(find.text('Clear & Switch'));
      await tester.pumpAndSettle();

      // Switched to Shop B and Cart was cleared
      expect(auth.currentRetailer?.id, equals('ret_2'));
      expect(cart.itemCount, equals(0));
    });
  });
}
