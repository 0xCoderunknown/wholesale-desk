import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/services/scheme_helper.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/state/desk_provider.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_card_grid.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_filter_toolbar.dart';
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

    testWidgets('CatalogFilterToolbar strictly hides view switcher on mobile (<768px) and shows on desktop',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mobile (<768px)
      await tester.pumpWidget(
        buildTestableWidget(
          child: CatalogFilterToolbar(
            searchController: TextEditingController(),
            searchFocus: FocusNode(),
            isGridView: false,
            isDesktop: false,
            brands: const ['All Brands'],
            selectedBrand: 'All Brands',
            stockFilter: StockFilterType.all,
            onSearchChanged: (_) {},
            onClearSearch: () {},
            onToggleViewMode: () {},
            onBrandSelected: (_) {},
            onStockFilterSelected: (_) {},
          ),
        ),
      );

      // On mobile, view switcher button is strictly absent
      expect(find.text('Cards'), findsNothing);
      expect(find.text('List'), findsNothing);
      expect(find.text('Switch to Cards'), findsNothing);
      expect(find.text('Switch to List'), findsNothing);

      // Desktop (>=768px)
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        buildTestableWidget(
          surfaceSize: const Size(1200, 800),
          child: CatalogFilterToolbar(
            searchController: TextEditingController(),
            searchFocus: FocusNode(),
            isGridView: false,
            isDesktop: true,
            brands: const ['All Brands'],
            selectedBrand: 'All Brands',
            stockFilter: StockFilterType.all,
            onSearchChanged: (_) {},
            onClearSearch: () {},
            onToggleViewMode: () {},
            onBrandSelected: (_) {},
            onStockFilterSelected: (_) {},
          ),
        ),
      );

      // On desktop, view switcher is present
      expect(find.text('Cards'), findsOneWidget);
    });
    testWidgets('Header bar (<768px) places search input and stock filter in single horizontal row',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: CatalogFilterToolbar(
            searchController: TextEditingController(),
            searchFocus: FocusNode(),
            isGridView: false,
            isDesktop: false,
            brands: const ['All Brands'],
            selectedBrand: 'All Brands',
            stockFilter: StockFilterType.all,
            onSearchChanged: (_) {},
            onClearSearch: () {},
            onToggleViewMode: () {},
            onBrandSelected: (_) {},
            onStockFilterSelected: (_) {},
          ),
        ),
      );

      // Verify TextField and DropdownButton are present in the same Row
      final textFieldFinder = find.byType(TextField);
      final dropdownFinder = find.byType(DropdownButton<StockFilterType>);
      expect(textFieldFinder, findsOneWidget);
      expect(dropdownFinder, findsOneWidget);

      // Both should be children of a single Row in mobile mode
      final rows = find.byType(Row);
      bool foundTogether = false;
      for (final element in rows.evaluate()) {
        final rowWidget = element.widget as Row;
        // Check if row has children containing both or descendant widgets
        final textInRow = find.descendant(of: find.byWidget(rowWidget), matching: textFieldFinder);
        final dropdownInRow = find.descendant(of: find.byWidget(rowWidget), matching: dropdownFinder);
        if (textInRow.evaluate().isNotEmpty && dropdownInRow.evaluate().isNotEmpty) {
          foundTogether = true;
          break;
        }
      }
      expect(foundTogether, isTrue);
    });

    testWidgets('Accordion gating: static flat badge for percentage scheme vs expandable drawer for tiered',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final percentProduct = Product(
        id: 'prod_parle',
        name: 'Parle-G 250g',
        brand: 'Parle',
        mrp: 30.0,
        ptr: 25.0,
        scheme: '5% Cash Disc',
        moq: 10,
        cartonPack: 60,
        inStock: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: SchemeCollapsibleAccordion(
            product: percentProduct,
            inStock: true,
            isAlreadyActive: false,
            onApplyScheme: () {},
          ),
        ),
      );

      // Percentage scheme: flat static amber badge with no expansion arrow (Icons.keyboard_arrow_down)
      expect(find.text('5% Cash Disc auto-applied at checkout'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);

      // Tiered scheme: expandable accordion
      await tester.pumpWidget(
        buildTestableWidget(
          child: SchemeCollapsibleAccordion(
            product: sampleProduct, // '10+1 Free'
            inStock: true,
            isAlreadyActive: false,
            onApplyScheme: () {},
          ),
        ),
      );

      // Tiered scheme shows expandable header and arrow
      expect(find.textContaining('Scheme: 10+1 Free'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap to expand drawer
      await tester.tap(find.textContaining('Scheme: 10+1 Free'));
      await tester.pumpAndSettle();

      // Drawer is expanded with compact 1-line breakdown
      expect(find.textContaining('Buy 10 units → Get 1 unit FREE'), findsOneWidget);
      expect(find.textContaining('Effective PTR:'), findsOneWidget);
      // Single lightning sign via Icon(Icons.bolt_rounded) without duplicate emoji in label
      expect(find.text('Apply Scheme (+10 Units)'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets('In-place action replacement replaces Add to Cart with Stepper keeping Buy 1 Box adjacent',
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

      // Before adding: Add to Cart button is visible
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy 1 Box (24)'), findsOneWidget);

      // Tap Add to Cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // After adding: Add to Cart is replaced in-place by Stepper; Buy 1 Box remains adjacent
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      // At minBound (MOQ 6), left icon shows delete_outline_rounded
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Buy 1 Box (24)'), findsOneWidget);
      expect(find.text('${sampleProduct.moq}'), findsOneWidget); // MOQ = 6

      // Increment above MOQ -> left icon changes to remove_rounded
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('Unified Price & Margin Bar renders [₹MRP_VALUE  [MARGIN: XYZ%]  ₹PTR_VALUE]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: CatalogMobileList(
            products: [sampleProduct],
            enforceMoq: true,
          ),
        ),
      );

      // Verify MRP (₹140.00), Margin badge ('MARGIN: 12.9%'), and PTR (₹122.00) are rendered
      expect(find.text('₹140.00'), findsOneWidget);
      expect(find.text('MARGIN: 12.9%'), findsOneWidget);
      expect(find.text('₹122.00'), findsOneWidget);
    });

    testWidgets('When scheme matches, PTR & Margin show boosted values with strikethrough and scheme button appears pressed',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          child: CatalogMobileList(
            products: [sampleProduct], // scheme: '10+1 Free', ptr: 122.0, mrp: 140.0, moq: 6
            enforceMoq: true,
          ),
        ),
      );

      // Add to cart sets MOQ = 6 (scheme not matched yet)
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Before scheme matches: baseline PTR (₹122.00) and base margin (12.9%)
      expect(find.text('MARGIN: 12.9%'), findsOneWidget);
      expect(find.text('₹122.00'), findsOneWidget);

      // Manually increment quantity to 10 (matching 10+1 threshold)
      for (int i = 6; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
      }

      // Quantity is now 10: scheme threshold is satisfied!
      // 1. Margin badge shows boosted margin: MARGIN: 20.8% with base 12.9% struck-through
      expect(find.text('MARGIN: 20.8%'), findsOneWidget);
      expect(find.text('12.9%'), findsOneWidget);

      // 2. PTR shows effective discounted rate: (10 * 122) / 11 = ₹110.91, with base ₹122.00 struck-through
      expect(find.text('₹110.91'), findsOneWidget);
      expect(find.text('₹122.00'), findsOneWidget);

      // 3. Scheme accordion header turns green with active text
      expect(find.textContaining('Scheme Active: 10+1 Free'), findsOneWidget);

      // Expand accordion to verify button state
      await tester.tap(find.textContaining('Scheme Active: 10+1 Free'));
      await tester.pumpAndSettle();

      // Button appears pressed: solid green with checkmark
      expect(find.text('✓ Scheme Applied (+10 Units)'), findsOneWidget);
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
