import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/state/cart_provider.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_card_grid.dart';
import 'package:wholesale_desk/views/retailer/components/catalog_mobile_list.dart';

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
    Size surfaceSize = const Size(390, 844), // iPhone 14/15/16 portrait
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Mobile View Layout & Single Item Per Line', () {
    testWidgets('CatalogMobileList renders 1 item per row and full product name with size',
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

      // Verify the entire product name with 500gm is rendered
      expect(find.text('Surf Excel Easy Wash Powder 500gm'), findsOneWidget);

      // Verify bottom padding is 84px to avoid FAB occlusion
      final listView = tester.widget<ListView>(find.byType(ListView));
      final padding = listView.padding as EdgeInsets;
      expect(padding.bottom, equals(84.0));
    });

    testWidgets('CatalogCardGrid enforces strictly 1 card per line (single column) on mobile (<600px)',
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

      // Verify GridView crossAxisCount is 1 on mobile
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(1));

      // Verify bottom padding is 84px to avoid FAB occlusion
      final padding = gridView.padding as EdgeInsets;
      expect(padding.bottom, equals(84.0));

      // Verify full product name including size is rendered
      expect(find.text('Surf Excel Easy Wash Powder 500gm'), findsOneWidget);
    });
  });
}

