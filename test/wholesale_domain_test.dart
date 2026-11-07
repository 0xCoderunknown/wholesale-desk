import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/models/cart_item.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/models/app_settings.dart';

void main() {
  group('Product and CartItem Invariants', () {
    test('Calculates line totals and savings accurately', () {
      final product = Product(
        id: 'p1',
        name: 'Dettol 500ml',
        brand: 'Reckitt',
        mrp: 330.0,
        ptr: 285.0,
        scheme: '12+1 Free',
        moq: 12,
        inStock: true,
      );

      final item = CartItem(product: product, quantity: 24);

      expect(item.lineTotalPtr, equals(6840.0));
      expect(item.lineTotalMrp, equals(7920.0));
      expect(item.lineSavings, equals(1080.0));
      expect(item.hasScheme, isTrue);
    });

    test('Binary stock status toggling preserves rates and MOQ', () {
      final product = Product(
        id: 'p2',
        name: 'Horlicks 1kg',
        brand: 'HUL',
        mrp: 550.0,
        ptr: 490.0,
        scheme: '',
        moq: 6,
        inStock: true,
      );

      final toggled = product.copyWith(inStock: false);

      expect(toggled.inStock, isFalse);
      expect(toggled.ptr, equals(490.0));
      expect(toggled.mrp, equals(550.0));
      expect(toggled.moq, equals(6));
    });

    test('AppSettings serialization fidelity', () {
      final settings = AppSettings(
        storeName: 'Test Wholesale Depot',
        whatsappPhone: '919876543210',
        masterPin: '5075',
        staffPin: '1122',
      );

      final map = settings.toMap();
      final restored = AppSettings.fromMap(map);

      expect(restored.storeName, equals(settings.storeName));
      expect(restored.whatsappPhone, equals(settings.whatsappPhone));
      expect(restored.masterPin, equals(settings.masterPin));
      expect(restored.staffPin, equals(settings.staffPin));
    });

    test('Retailer validation checks', () {
      final retailer = Retailer(
        id: 'r1',
        storeName: 'Kishore General Stores',
        mobile: '9876543210',
        pin: '1234',
        route: 'Paltan Bazar Route',
        status: 'active',
      );

      expect(retailer.isActive, isTrue);
      expect(retailer.pin == '1234', isTrue);
      expect(retailer.pin == '0000', isFalse);
    });
  });
}
