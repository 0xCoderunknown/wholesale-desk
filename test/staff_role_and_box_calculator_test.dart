import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/config/theme.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/state/auth_provider.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/state/desk_provider.dart';
import 'package:wholesale_desk/views/distributor/box_breakdown_dialog.dart';
import 'package:wholesale_desk/views/distributor/distributor_desk_screen.dart';
import 'package:wholesale_desk/views/widgets/stock_toggle_pill.dart';

void main() {
  final sampleProduct1 = Product(
    id: 'prod_1',
    name: 'Dettol Antiseptic Liquid 500ml',
    brand: 'Reckitt',
    mrp: 320.0,
    ptr: 285.0,
    scheme: '12+1 Free',
    moq: 6,
    cartonPack: 24,
    inStock: true,
  );

  final sampleProduct2 = Product(
    id: 'prod_2',
    name: 'Surf Excel Easy Wash 1kg',
    brand: 'Hindustan Unilever',
    mrp: 145.0,
    ptr: 124.0,
    scheme: '',
    moq: 12,
    cartonPack: 12,
    inStock: false,
  );

  Widget buildTestableWidget({
    required Widget child,
    required AuthProvider authProvider,
    required DeskProvider deskProvider,
    Size surfaceSize = const Size(1280, 800),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DeskProvider>.value(value: deskProvider),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
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

  group('Staff Role Guardrails & Rate Shielding', () {
    testWidgets('Staff PIN on Desktop completely hides PTR, Margin, MRP, Schemes, and Settings',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      auth.setRoleForTesting(UserRole.staff);

      final desk = DeskProvider();
      desk.setProductsForTesting([sampleProduct1, sampleProduct2]);

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          deskProvider: desk,
          surfaceSize: const Size(1280, 800),
          child: const DistributorDeskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar verification: Staff badge shown, Admin settings hidden
      expect(find.text('STAFF COUNTER (RESTRICTED)'), findsOneWidget);
      expect(find.text('• Stock Toggle Only'), findsOneWidget);
      expect(find.byTooltip('Store & PIN Settings'), findsNothing);
      expect(find.byTooltip('Reset Demo Catalog (10 Products & 3 Stores)'), findsNothing);
      expect(find.text('Retailer PIN Accounts'), findsNothing);

      // Warehouse Box Calculator action button MUST be present
      expect(find.byTooltip('Dispatch Box Breakdown Calculator'), findsOneWidget);

      // Desktop Table Column Guardrail Checks
      expect(find.text('PRODUCT / BRAND'), findsOneWidget);
      expect(find.text('BOX / CASE PACK'), findsOneWidget);
      expect(find.text('STOCK AVAILABILITY (CLICK TO TOGGLE)'), findsOneWidget);

      // Sensitive pricing & margin columns must NOT be present
      expect(find.text('PTR (RATE)'), findsNothing);
      expect(find.text('MARGIN %'), findsNothing);
      expect(find.text('MRP'), findsNothing);
      expect(find.text('SCHEME CONFIG'), findsNothing);
      expect(find.text('₹285.00'), findsNothing);
      expect(find.text('₹320.00'), findsNothing);

      // Product and Box badges are visible
      expect(find.text('Dettol Antiseptic Liquid 500ml'), findsOneWidget);
      expect(find.text('📦 Box of 24'), findsOneWidget);
      expect(find.text('📦 Box of 12'), findsOneWidget);

      // Staff can toggle stock via StockTogglePill
      expect(find.byType(StockTogglePill), findsNWidgets(2));
    });

    testWidgets('Admin PIN on Desktop retains all pricing, margins, schemes, and settings',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      auth.setRoleForTesting(UserRole.admin);

      final desk = DeskProvider();
      desk.setProductsForTesting([sampleProduct1, sampleProduct2]);

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          deskProvider: desk,
          surfaceSize: const Size(1280, 800),
          child: const DistributorDeskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar verification: Admin badge and tools shown
      expect(find.text('ADMIN DESK (MASTER)'), findsOneWidget);
      expect(find.byTooltip('Store & PIN Settings'), findsOneWidget);
      expect(find.text('Retailer PIN Accounts'), findsOneWidget);

      // Pricing, schemes, and margin columns must be visible
      expect(find.text('PTR (RATE)'), findsOneWidget);
      expect(find.text('MARGIN'), findsOneWidget);
      expect(find.text('MRP'), findsOneWidget);
      expect(find.text('SCHEME'), findsOneWidget);
      expect(find.text('₹285.00'), findsOneWidget);
      expect(find.text('₹320.00'), findsOneWidget);
    });

    testWidgets('Staff PIN on Mobile (<768px) displays high-density cards with stock toggle and box badge',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      auth.setRoleForTesting(UserRole.staff);

      final desk = DeskProvider();
      desk.setProductsForTesting([sampleProduct1]);

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          deskProvider: desk,
          surfaceSize: const Size(390, 844),
          child: const DistributorDeskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Product name & Box pack badge are present
      expect(find.text('Dettol Antiseptic Liquid 500ml'), findsOneWidget);
      expect(find.text('📦 Box of 24'), findsOneWidget);

      // Sensitive pricing & edit buttons must NOT be present
      expect(find.textContaining('PTR:'), findsNothing);
      expect(find.textContaining('MRP:'), findsNothing);
      expect(find.byTooltip('Edit Product'), findsNothing);
      expect(find.byTooltip('Delete Product'), findsNothing);

      // Full-width stock toggle button is present
      expect(find.byType(StockTogglePill), findsOneWidget);

      // Tapping the Box of 24 badge opens the BoxBreakdownDialog prefilled with the product
      await tester.tap(find.text('📦 Box of 24'));
      await tester.pumpAndSettle();

      expect(find.text('Box Breakdown Calculator'), findsOneWidget);
      expect(find.text('Dettol Antiseptic Liquid 500ml'), findsWidgets);
    });
  });

  group('Box Breakdown Calculator Math & UX', () {
    testWidgets('Calculates full cartons and loose units accurately for 52 pcs in Box 24',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BoxBreakdownDialog(
              products: [sampleProduct1, sampleProduct2],
              initialProduct: sampleProduct1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter quantity 52 in the quantity text field
      final qtyFinder = find.widgetWithText(TextField, 'Enter quantity...');
      expect(qtyFinder, findsOneWidget);

      await tester.enterText(qtyFinder, '52');
      await tester.pumpAndSettle();

      // Math verification: 52 / 24 = 2 boxes (48 pcs) + 4 loose
      expect(find.text('📦 2 Full Boxes (48 pcs)'), findsOneWidget);
      expect(find.text('🧴 4 Loose Pieces'), findsOneWidget);
      expect(find.text('52 pcs'), findsOneWidget);

      // Tap '+1 Box (24)' quick adder (+24 units) -> Total becomes 76
      await tester.tap(find.textContaining('+1 Box'));
      await tester.pumpAndSettle();

      // 76 / 24 = 3 boxes (72 pcs) + 4 loose
      expect(find.text('📦 3 Full Boxes (72 pcs)'), findsOneWidget);
      expect(find.text('🧴 4 Loose Pieces'), findsOneWidget);
      expect(find.text('76 pcs'), findsOneWidget);

      // Switch Box Pack chip to '12'
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      // 76 / 12 = 6 boxes (72 pcs) + 4 loose
      expect(find.text('📦 6 Full Boxes (72 pcs)'), findsOneWidget);
      expect(find.text('🧴 4 Loose Pieces'), findsOneWidget);

      // Tap 'Clear' quick adder
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Enter quantity to calculate cartons & loose units'), findsOneWidget);
    });
  });
}
