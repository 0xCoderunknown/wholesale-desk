import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/services/scheme_helper.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_card_grid.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_mobile_list.dart';
import 'package:wholesale_desk/views/widgets/scheme_accordion.dart';

void main() {
  final sampleProduct = Product(
    id: 'prod_surf_500gm',
    name: 'Surf Excel Easy Wash Powder 500gm',
    brand: 'Hindustan Unilever',
    mrp: 140.0,
    ptr: 122.0,
    scheme: '10+1 Free',
    moq: 6,
    cartonPack: 24,
    inStock: true,
  );

  Widget buildTestableWidget({
    required Widget child,
    CartProvider? cartProvider,
    Size surfaceSize = const Size(390, 844), // iPhone 14/15/16 portrait
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => cartProvider ?? CartProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Mobile View Layout & Single Item Per Line (<768px)', () {
    testWidgets('CatalogMobileList renders 1 item per row, full title, dual action & accordion',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          child: CatalogMobileList(
            products: [sampleProduct],
            enforceMoq: true,
          ),
        ),
      );

      // Verify the entire product name with 500gm is rendered
      expect(find.text('Surf Excel Easy Wash Powder 500gm'), findsOneWidget);

      // Verify bottom padding is 84px to avoid FAB occlusion
      final listView = tester.widget<ListView>(find.byType(ListView));
      final padding = listView.padding as EdgeInsets;
      expect(padding.bottom, equals(84.0));

      // Verify Dual Action Row: Add to Cart + Buy 1 Box (24)
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy 1 Box (24)'), findsOneWidget);

      // Verify Collapsible Scheme Accordion (Shikhar Style)
      expect(find.byType(SchemeCollapsibleAccordion), findsOneWidget);
      expect(find.textContaining('Scheme: 10+1 Free'), findsOneWidget);

      // Tapping "Buy 1 Box (24)" immediately populates 24 units in cart
      await tester.tap(find.text('Buy 1 Box (24)'));
      await tester.pumpAndSettle();

      expect(cart.getQuantity(sampleProduct.id), equals(24));
      // Dynamic margin recalculation should highlight boosted margin
      expect(find.textContaining('Margin'), findsWidgets);
    });

    testWidgets('CatalogCardGrid adopts single-column on mobile (<768px) and multi-column on desktop',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: CatalogCardGrid(
            products: [sampleProduct],
            enforceMoq: true,
          ),
        ),
      );

      // On mobile (<768px), ListView is used for single-column dynamic height
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Surf Excel Easy Wash Powder 500gm'), findsOneWidget);
      expect(find.text('Buy 1 Box (24)'), findsOneWidget);

      // Now switch to desktop (>768px)
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        buildTestableWidget(
          surfaceSize: const Size(1200, 800),
          child: CatalogCardGrid(
            products: [sampleProduct],
            enforceMoq: true,
          ),
        ),
      );

      // On desktop, GridView is used
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('Dynamic Margin Math & Accordion Breakdown', () {
    test('Calculates max scheme details for 12+1 Free matching specification', () {
      final details = SchemeHelper.getMaxSchemeDetails(
        scheme: '12+1 Free',
        ptr: 285.0,
        mrp: 330.0,
      );

      // Buy 12 units -> Get 1 unit FREE
      expect(details.breakdownCopy, equals('Buy 12 units → Get 1 unit FREE'));
      // Effective PTR = (12 * 285) / 13 = 263.0769
      expect(details.effPtr, closeTo(263.08, 0.02));
      // Effective Margin = ((330 - 263.08) / 330) * 100 = 20.279%
      expect(details.maxMargin, closeTo(20.3, 0.1));
    });

    test('Calculates cash rebate scheme margin for Buy 24 Get ₹100 Off', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: 'Buy 24 Get ₹100 Off',
        currentQuantity: 24,
        ptr: 120.0,
        mrp: 140.0,
      );

      expect(nudge.isQualified, isTrue);
      // Effective PTR = ((24 * 120) - 100) / 24 = 2780 / 24 = 115.833
      expect(nudge.effectivePtr, closeTo(115.83, 0.02));
      expect(nudge.hasBoostedMargin, isTrue);
    });

    test('Calculates percentage scheme margin for 5% Cash Disc', () {
      final nudge = SchemeHelper.calculateNudge(
        scheme: '5% Cash Disc',
        currentQuantity: 10,
        ptr: 100.0,
        mrp: 120.0,
      );

      expect(nudge.isQualified, isTrue);
      // Effective PTR = 100 * 0.95 = 95.0
      expect(nudge.effectivePtr, equals(95.0));
      // Effective Margin = ((120 - 95) / 120) * 100 = 20.83%
      expect(nudge.effectiveMarginPercent, closeTo(20.83, 0.05));
    });
  });
}
