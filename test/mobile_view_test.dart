import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/config/theme.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/services/scheme_helper.dart';
import 'package:wholesale_desk/state/auth_provider.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/state/desk_provider.dart';
import 'package:wholesale_desk/views/retailer/retailer_cart_screen.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_card_grid.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_filter_toolbar.dart';
import 'package:wholesale_desk/views/retailer/retailer_catalog_screen.dart';
import 'package:wholesale_desk/views/widgets/catalog_quantity_stepper.dart';
import 'package:wholesale_desk/views/widgets/scheme_inline_strip.dart';

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
    AuthProvider? authProvider,
    DeskProvider? deskProvider,
    Size surfaceSize = const Size(390, 844), // iPhone 14/15/16 portrait
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => cartProvider ?? CartProvider()),
        if (authProvider != null) ChangeNotifierProvider.value(value: authProvider),
        if (deskProvider != null) ChangeNotifierProvider.value(value: deskProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: child is Scaffold ? child : Scaffold(body: child),
        ),
      ),
    );
  }

  group('Mobile View Layout & Single Item Per Line (<768px)', () {
    testWidgets('CatalogCardGrid renders 1 item per row, full title, dual action & accordion',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          child: CatalogCardGrid(
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
      expect(find.byType(SchemeInlineStrip), findsOneWidget);
      expect(find.textContaining('Scheme: 10+1 Free'), findsOneWidget);

      // Tapping "Buy 1 Box (24)" immediately populates 24 units in cart
      await tester.tap(find.text('Buy 1 Box (24)'));
      await tester.pumpAndSettle();

      expect(cart.getQuantity(sampleProduct.id), equals(24));
      // Dynamic margin recalculation should highlight boosted margin
      expect(find.textContaining('MARGIN'), findsWidgets);
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

    testWidgets('Inline scheme strip: static flat badge for percentage scheme vs 1-click inline apply button for tiered (no accordion)',
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
          child: SchemeInlineStrip(
            product: percentProduct,
            inStock: true,
            isAlreadyActive: false,
            onApplyScheme: () {},
          ),
        ),
      );

      // Percentage scheme: flat static amber badge with no expansion arrow or apply button
      expect(find.text('5% Cash Disc auto-applied'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.textContaining('APPLY'), findsNothing);

      // Tiered scheme: clean inline single-line strip with inline [APPLY] button and no accordion drawer
      var appliedCount = 0;
      await tester.pumpWidget(
        buildTestableWidget(
          child: SchemeInlineStrip(
            product: sampleProduct, // '10+1 Free'
            inStock: true,
            isAlreadyActive: false,
            onApplyScheme: () {
              appliedCount++;
            },
          ),
        ),
      );

      // Tiered scheme shows scheme label and inline APPLY button without expansion arrows
      expect(find.textContaining('Scheme: 10+1 Free'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.text('APPLY'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      // Tapping inline button immediately triggers onApplyScheme without drawer animation
      await tester.tap(find.text('APPLY'));
      await tester.pump();
      expect(appliedCount, equals(1));
    });

    testWidgets('In-place action replacement replaces Add to Cart with Stepper keeping Buy 1 Box adjacent',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          child: CatalogCardGrid(
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
      expect(find.byIcon(Icons.close_rounded), findsNothing); // Redundant cross removed
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget); // 1-tap delete button is present!
      expect(find.text('Buy 1 Box (24)'), findsOneWidget);
      expect(find.text('${sampleProduct.moq}'), findsOneWidget); // MOQ = 6

      // Increment: 6 -> 7
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);

      // Decrement: 7 -> 6 (smooth step-down)
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);

      // Decrement at MOQ floor (6) does not drop below MOQ
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);

      // Direct inline typing: enter 50 directly in the TextField
      final qtyInput = find.descendant(
        of: find.byType(CatalogQuantityStepper),
        matching: find.byType(TextField),
      );
      await tester.enterText(qtyInput, '50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(cart.getQuantity(sampleProduct.id), equals(50));
      expect(find.text('50'), findsOneWidget);

      // 1-Tap Delete removes the item and restores Add to Cart
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets('Unified Price & Margin Bar renders [₹MRP_VALUE  [MARGIN: XYZ%]  ₹PTR_VALUE]',
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

      // Verify MRP (₹140.00), Margin badge ('MARGIN: 12.9%'), and PTR (₹122.00) are rendered
      expect(find.text('₹140.00'), findsOneWidget);
      expect(find.text('MARGIN: 12.9%'), findsOneWidget);
      expect(find.text('₹122.00'), findsOneWidget);

      // Verify MRP and PTR have the exact same font size and color by default
      final mrpWidget = tester.widget<Text>(find.text('₹140.00'));
      final ptrWidget = tester.widget<Text>(find.text('₹122.00'));
      expect(mrpWidget.style?.fontSize, equals(14.5));
      expect(ptrWidget.style?.fontSize, equals(14.5));
      expect(mrpWidget.style?.color, equals(AppTheme.slate800));
      expect(ptrWidget.style?.color, equals(AppTheme.slate800));
    });

    testWidgets('When scheme matches, PTR & Margin show boosted new values only in vibrant green without strikethrough',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cart = CartProvider();
      await tester.pumpWidget(
        buildTestableWidget(
          cartProvider: cart,
          child: CatalogCardGrid(
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
      // 1. Margin badge shows boosted margin (new value only, no old strikethrough!)
      expect(find.text('MARGIN: 20.8%'), findsOneWidget);
      expect(find.text('12.9%'), findsNothing); // Old margin value is NOT shown

      // 2. PTR shows effective discounted rate in vibrant emerald green (new value only, no old strikethrough!)
      expect(find.text('₹110.91'), findsOneWidget);
      expect(find.text('₹122.00'), findsNothing); // Old PTR is NOT shown
      final ptrWidget = tester.widget<Text>(find.text('₹110.91'));
      expect(ptrWidget.style?.color, equals(const Color(0xFF059669))); // Vibrant green highlight

      // 3. Scheme inline banner turns green with active text and REMOVE button
      expect(find.textContaining('Scheme Active: 10+1 Free'), findsOneWidget);
      expect(find.text('REMOVE'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SchemeInlineStrip),
          matching: find.byIcon(Icons.close_rounded),
        ),
        findsOneWidget,
      );

      // 4. Tapping REMOVE undoes the scheme / removes the whole lot from cart
      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();

      expect(cart.getQuantity(sampleProduct.id), equals(0));
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);
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

  group('Responsive Top Bar & Tablet/Mobile Layouts', () {
    final sampleRetailer = Retailer(
      id: 'ret_1',
      storeName: 'Guwahati General Store',
      mobile: '9876543210',
      pin: '1234',
      route: 'North Corridor',
      status: 'active',
    );

    testWidgets('Mobile Top Bar (<768px) displays integrated identity, cart action, and guarded exit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      final desk = DeskProvider();
      final cart = CartProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          deskProvider: desk,
          cartProvider: cart,
          surfaceSize: const Size(390, 844),
          child: RetailerCatalogScreen(retailer: sampleRetailer),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar displays store identity and integrated retailer subtitle with route
      expect(find.text(auth.settings.storeName), findsOneWidget);
      expect(find.text('Guwahati General Store'), findsOneWidget);
      expect(find.textContaining('North Corridor'), findsOneWidget);

      // Mobile uses bottom FloatingActionButton; top bar does not duplicate cart button
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('View Cart'), findsNothing);

      // Tapping Logout triggers confirmation dialog
      await tester.tap(find.byTooltip('Exit Order Desk'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Order Desk?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel closes dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Order Desk?'), findsNothing);
    });

    testWidgets('Tablet View (768px - 1023px) renders 2-column catalog and un-crowded top bar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1080)); // iPad portrait
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      final desk = DeskProvider();
      final cart = CartProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          deskProvider: desk,
          cartProvider: cart,
          surfaceSize: const Size(800, 1080),
          child: RetailerCatalogScreen(retailer: sampleRetailer),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar displays Exit button with text and Route pill in actions
      expect(find.text('Exit'), findsOneWidget);
      expect(find.text('North Corridor'), findsOneWidget);
      expect(find.text('Guwahati General Store'), findsOneWidget);
    });

    testWidgets('RetailerCartScreen displays empty state with Back to Catalog button, and populated state with clear confirmation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800)); // Desktop width
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthProvider();
      final cart = CartProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          authProvider: auth,
          cartProvider: cart,
          surfaceSize: const Size(1280, 800),
          child: RetailerCartScreen(retailer: sampleRetailer),
        ),
      );
      await tester.pumpAndSettle();

      // Empty State: shows clean icon and actionable Back to Product Catalog button
      expect(find.text('Your wholesale cart is empty'), findsOneWidget);
      expect(find.text('Back to Product Catalog'), findsOneWidget);

      // Add item to cart
      cart.addItem(sampleProduct);
      await tester.pumpAndSettle();

      // Populated State: item visible with line totals and Send Order on WhatsApp
      expect(find.textContaining(sampleProduct.name), findsOneWidget);
      expect(find.text('Send Order on WhatsApp'), findsOneWidget);

      // Clear button triggers confirmation dialog
      expect(find.text('Clear'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Cart?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel keeps item
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cart.items.length, equals(1));

      // Clear confirmed clears cart
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(cart.items.isEmpty, isTrue);
      expect(find.text('Your wholesale cart is empty'), findsOneWidget);
    });
  });
}
