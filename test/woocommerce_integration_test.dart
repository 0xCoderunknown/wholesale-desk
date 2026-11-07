import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/models/app_settings.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/services/repository_manager.dart';

void main() {
  group('WooCommerce Data Parsing and Dual-Backend Switcher', () {
    test('Parses WooCommerce REST product payload with carton_pack and scheme', () {
      final jsonPayload = jsonDecode('''
      {
        "id": 105,
        "name": "Rin Detergent Bar 250g",
        "brand": "Hindustan Unilever",
        "in_stock": true,
        "mrp": 30.0,
        "ptr": 24.5,
        "moq": 12,
        "carton_pack": 144,
        "scheme_type": "free_goods",
        "scheme_shorthand": "12+1 Free",
        "scheme_badge": "12+1 Free"
      }
      ''') as Map<String, dynamic>;

      final product = Product(
        id: jsonPayload['id'].toString(),
        name: jsonPayload['name'] as String,
        brand: jsonPayload['brand'] as String,
        mrp: (jsonPayload['mrp'] as num).toDouble(),
        ptr: (jsonPayload['ptr'] as num).toDouble(),
        scheme: jsonPayload['scheme_shorthand'] as String,
        moq: jsonPayload['moq'] as int,
        cartonPack: jsonPayload['carton_pack'] as int,
        inStock: jsonPayload['in_stock'] as bool,
      );

      expect(product.id, equals('105'));
      expect(product.cartonPack, equals(144));
      expect(product.hasCartonPack, isTrue);
      expect(product.moq, equals(12));
      expect(product.scheme, equals('12+1 Free'));
      expect(product.margin, closeTo(5.5, 0.01));
      expect(product.marginPercent, closeTo(18.33, 0.1));
    });

    test('RepositoryManager switches backend cleanly between Firebase and WooCommerce', () {
      final repoManager = RepositoryManager.instance;
      expect(repoManager.isWooCommerce, isFalse);

      repoManager.switchBackend(
        backendType: 'woocommerce',
        wpBaseUrl: 'https://example.com/wp-json/swac/v1',
      );
      expect(repoManager.isWooCommerce, isTrue);

      repoManager.switchBackend(
        backendType: 'firebase',
        wpBaseUrl: '',
      );
      expect(repoManager.isWooCommerce, isFalse);
    });

    test('AppSettings preserves backend configuration', () {
      const settings = AppSettings(
        whatsappPhone: '917002796068',
        storeName: 'Apex Wholesale',
        masterPin: '5075',
        staffPin: '1122',
        backendType: 'woocommerce',
        wpBaseUrl: 'https://mywholesalestore.com',
      );

      final map = settings.toMap();
      final revived = AppSettings.fromMap(map);

      expect(revived.backendType, equals('woocommerce'));
      expect(revived.wpBaseUrl, equals('https://mywholesalestore.com'));
      expect(revived.isWooCommerce, isTrue);
    });
  });
}

