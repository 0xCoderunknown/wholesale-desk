import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/config/theme.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/views/distributor/product_edit_dialog.dart';
import 'package:wholesale_desk/views/widgets/stock_toggle_pill.dart';

void main() {
  Widget buildTestableDialog({
    Product? product,
    Size surfaceSize = const Size(800, 800),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Scaffold(body: ProductEditDialog(product: product)),
      ),
    );
  }

  group('ProductEditDialog Commercial Pricing & Margin Strip', () {
    testWidgets(
      'Calculates and displays green retailer margin pill when PTR <= MRP',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableDialog());
        await tester.pumpAndSettle();

        // Enter MRP 320 and PTR 285
        final mrpFinder = find.widgetWithText(TextFormField, '0.00').first;
        final ptrFinder = find.widgetWithText(TextFormField, '0.00').last;

        await tester.enterText(mrpFinder, '320');
        await tester.enterText(ptrFinder, '285');
        await tester.pumpAndSettle();

        // Margin = 320 - 285 = 35 (10.9%)
        expect(
          find.textContaining('📈 Retailer Margin: ₹35.00 (10.9%)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Displays bold red alert pill when PTR > MRP', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableDialog());
      await tester.pumpAndSettle();

      final mrpFinder = find.widgetWithText(TextFormField, '0.00').first;
      final ptrFinder = find.widgetWithText(TextFormField, '0.00').last;

      await tester.enterText(mrpFinder, '100');
      await tester.enterText(ptrFinder, '120');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('⚠️ Illegal Pricing: PTR exceeds MRP by ₹20.00'),
        findsOneWidget,
      );
    });

    testWidgets('Fails validation when PTR exceeds MRP', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Product? savedProduct;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                savedProduct = await showDialog<Product>(
                  context: context,
                  builder: (_) => const ProductEditDialog(),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fill in Name and Brand
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g., Dettol Antiseptic Liquid 500ml',
        ),
        'Soap',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Reckitt, Parle, ITC'),
        'HUL',
      );

      // Fill in MRP 100, PTR 120
      final mrpFinder = find.widgetWithText(TextFormField, '0.00').first;
      final ptrFinder = find.widgetWithText(TextFormField, '0.00').last;
      await tester.enterText(mrpFinder, '100');
      await tester.enterText(ptrFinder, '120');
      await tester.pumpAndSettle();

      // Attempt Save
      final saveBtn = find.text('Add to Catalog');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('PTR cannot exceed MRP'), findsOneWidget);
      expect(savedProduct, isNull);
    });

    testWidgets('Fails validation when MRP or PTR are <= 0, or MOQ < 1', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableDialog());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g., Dettol Antiseptic Liquid 500ml',
        ),
        'Soap',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Reckitt, Parle, ITC'),
        'HUL',
      );

      final mrpFinder = find.widgetWithText(TextFormField, '0.00').first;
      final ptrFinder = find.widgetWithText(TextFormField, '0.00').last;
      final moqFinder = find.widgetWithText(TextFormField, '1');

      await tester.enterText(mrpFinder, '0');
      await tester.enterText(ptrFinder, '0');
      await tester.enterText(moqFinder, '0');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Add to Catalog');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Must be > 0'), findsNWidgets(2)); // MRP and PTR
      expect(find.text('Must be ≥ 1'), findsOneWidget); // MOQ
    });
  });

  group('ProductEditDialog Scheme Preview & High-Speed Ergonomics', () {
    testWidgets(
      'Live syntax preview updates when typing volume, discount, or info schemes',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableDialog());
        await tester.pumpAndSettle();

        final schemeFinder = find.widgetWithText(
          TextFormField,
          'e.g., 10+1 Free, 5% CD',
        );

        // Test Free Goods with 'plus'
        await tester.enterText(schemeFinder, '10 plus 1');
        await tester.pumpAndSettle();
        expect(
          find.text('🎁 Free Goods: Earn 1 free for every 10 billed'),
          findsOneWidget,
        );

        // Test Percentage Discount and MOQ tip
        await tester.enterText(schemeFinder, '5% CD');
        await tester.pumpAndSettle();
        expect(
          find.text('🏷️ Percentage: 5% deducted from unit PTR on apply'),
          findsOneWidget,
        );
        expect(
          find.text('Tip: Set MOQ to enforce minimum order quantity for this % discount.'),
          findsOneWidget,
        );

        // Test Informational Text
        await tester.enterText(schemeFinder, 'Diwali Special Pack');
        await tester.pumpAndSettle();
        expect(
          find.text('ℹ️ Note: Shown as informational badge (no automated cart math)'),
          findsOneWidget,
        );
        // MOQ tip should be gone for info note
        expect(
          find.text('Tip: Set MOQ to enforce minimum order quantity for this % discount.'),
          findsNothing,
        );

        // Test Empty hides badge
        await tester.enterText(schemeFinder, '');
        await tester.pumpAndSettle();
        expect(find.textContaining('Note: Shown as informational'), findsNothing);
      },
    );

    testWidgets(
      'Displays warning banner for unusually large free goods (9999999+1) and extreme percentages (900% / 99%)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableDialog());
        await tester.pumpAndSettle();

        final schemeFinder = find.widgetWithText(
          TextFormField,
          'e.g., 10+1 Free, 5% CD',
        );

        // Test huge free goods threshold
        await tester.enterText(schemeFinder, '9999999+1');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('⚠️ Unusually large scheme (9999999+1). Verify before saving.'),
          findsOneWidget,
        );

        // Test extreme percentage (>= 100%)
        await tester.enterText(schemeFinder, '900%');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('⚠️ Extreme discount: 900% is 100% or greater! Product rate will become ₹0.'),
          findsOneWidget,
        );

        // Test high percentage (> 50%)
        await tester.enterText(schemeFinder, '99%');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('⚠️ High discount: 99% exceeds 50%. Verify distributor margins.'),
          findsOneWidget,
        );

        // Normal percentage should not show warning
        await tester.enterText(schemeFinder, '5%');
        await tester.pumpAndSettle();
        expect(find.textContaining('⚠️'), findsNothing);
      },
    );

    testWidgets(
      'Press here to help with scheme opens guide and selects template chip',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableDialog());
        await tester.pumpAndSettle();

        // Verify helper link is present
        final helpLink = find.text('Press here to help with scheme');
        expect(helpLink, findsOneWidget);

        // Tap helper link
        await tester.tap(helpLink);
        await tester.pumpAndSettle();

        // Verify guide dialog is open
        expect(find.text('Wholesale Scheme Guide'), findsOneWidget);
        expect(find.text('Free Goods Scheme (X+Y)'), findsOneWidget);
        expect(find.text('Percentage Discount (N%)'), findsOneWidget);

        // Tap template chip '10+1'
        final chip10Plus1 = find.widgetWithText(InkWell, '10+1');
        expect(chip10Plus1, findsOneWidget);
        await tester.tap(chip10Plus1);
        await tester.pumpAndSettle();

        // Guide should be dismissed and scheme field populated with '10+1'
        expect(find.text('Wholesale Scheme Guide'), findsNothing);
        expect(find.text('10+1'), findsOneWidget);
        expect(
          find.text('🎁 Free Goods: Earn 1 free for every 10 billed'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Toggles stock state using StockTogglePill', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableDialog());
      await tester.pumpAndSettle();

      expect(find.text('Current Status: IN STOCK'), findsOneWidget);
      expect(find.byType(StockTogglePill), findsOneWidget);

      // Tap StockTogglePill to toggle to OUT OF STOCK
      await tester.tap(find.byType(StockTogglePill));
      await tester.pumpAndSettle();

      expect(find.text('Current Status: OUT OF STOCK'), findsOneWidget);
    });

    testWidgets('Submits valid form cleanly on Add to Catalog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Product? savedProduct;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                savedProduct = await showDialog<Product>(
                  context: context,
                  builder: (_) => const ProductEditDialog(),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g., Dettol Antiseptic Liquid 500ml',
        ),
        'Tata Tea Gold 500g',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Reckitt, Parle, ITC'),
        'Tata Consumer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., 10+1 Free, 5% CD'),
        '10 plus 1 free',
      );

      final mrpFinder = find.widgetWithText(TextFormField, '0.00').first;
      final ptrFinder = find.widgetWithText(TextFormField, '0.00').last;
      await tester.enterText(mrpFinder, '300.00');
      await tester.enterText(ptrFinder, '250.00');

      final cartonFinder = find.widgetWithText(
        TextFormField,
        'Optional (e.g. 24)',
      );
      await tester.enterText(cartonFinder, '24');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Add to Catalog');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedProduct, isNotNull);
      expect(savedProduct!.name, equals('Tata Tea Gold 500g'));
      expect(savedProduct!.brand, equals('Tata Consumer'));
      expect(savedProduct!.mrp, equals(300.0));
      expect(savedProduct!.ptr, equals(250.0));
      expect(savedProduct!.scheme, equals('10 plus 1 free'));
      expect(savedProduct!.cartonPack, equals(24));
      expect(savedProduct!.inStock, isTrue);
    });
  });
}
