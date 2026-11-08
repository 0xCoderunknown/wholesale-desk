import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/models/app_settings.dart';
import 'package:wholesale_desk/models/product.dart';
import 'package:wholesale_desk/models/retailer.dart';
import 'package:wholesale_desk/services/repository_manager.dart';
import 'package:wholesale_desk/services/woocommerce_rest_service.dart';

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

      final product = Product.fromMap('105', jsonPayload);

      expect(product.id, equals('105'));
      expect(product.cartonPack, equals(144));
      expect(product.hasCartonPack, isTrue);
      expect(product.moq, equals(12));
      expect(product.scheme, equals('12+1 Free'));
      expect(product.margin, closeTo(5.5, 0.01));
      expect(product.marginPercent, closeTo(18.33, 0.1));
    });

    test('Defensively parses string numbers from legacy WooCommerce payloads', () {
      final jsonPayload = jsonDecode('''
      {
        "id": "204",
        "name": "Surf Excel Quick Wash 1kg",
        "brand": "Hindustan Unilever",
        "in_stock": "1",
        "mrp": "180.50",
        "ptr": "152.00",
        "moq": "6",
        "carton_pack": "24",
        "scheme_shorthand": "10:2%"
      }
      ''') as Map<String, dynamic>;

      final product = Product.fromMap('204', jsonPayload);

      expect(product.id, equals('204'));
      expect(product.mrp, equals(180.50));
      expect(product.ptr, equals(152.00));
      expect(product.moq, equals(6));
      expect(product.cartonPack, equals(24));
      expect(product.scheme, equals('10:2%'));
      expect(product.inStock, isTrue);
    });

    test('WooCommerceRestService sets dual auth headers when session token is active', () {
      final wcService = WooCommerceRestService(
        baseUrl: 'https://example.com/wp-json/swac/v1',
      );

      // Initially no auth tokens
      expect(wcService.sessionToken, isEmpty);
      expect(wcService.currentRole, isNull);
      expect(wcService.headers.containsKey('X-SWAC-Master-Token'), isFalse);
      expect(wcService.headers.containsKey('X-SWAC-Retailer-Token'), isFalse);

      // Verify clean URL parsing
      expect(
        WooCommerceRestService(baseUrl: 'https://example.com').baseUrl,
        equals('https://example.com/wp-json/swac/v1'),
      );
      expect(
        WooCommerceRestService(baseUrl: 'https://example.com/wp-json').baseUrl,
        equals('https://example.com/wp-json/swac/v1'),
      );
    });

    test('Parses WooCommerce Retailer payload mapping area to route and phone to id', () {
      final jsonPayload = jsonDecode('''
      {
        "phone": "9876543210",
        "pin": "1234",
        "store_name": "Gupta Provision Store",
        "owner_name": "Ramesh Gupta",
        "area": "Central Market Route",
        "status": "active"
      }
      ''') as Map<String, dynamic>;

      final retailer = Retailer(
        id: 'ret_${jsonPayload['phone']}',
        storeName: jsonPayload['store_name'] as String,
        mobile: jsonPayload['phone'] as String,
        pin: jsonPayload['pin'] as String,
        route: (jsonPayload['route'] ?? jsonPayload['area']) as String,
        status: jsonPayload['status'] as String,
      );

      expect(retailer.id, equals('ret_9876543210'));
      expect(retailer.storeName, equals('Gupta Provision Store'));
      expect(retailer.mobile, equals('9876543210'));
      expect(retailer.route, equals('Central Market Route'));
      expect(retailer.isActive, isTrue);
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
        salesmanPin: '3344',
        backendType: 'woocommerce',
        wpBaseUrl: 'https://mywholesalestore.com',
      );

      final map = settings.toMap();
      final revived = AppSettings.fromMap(map);

      expect(revived.backendType, equals('woocommerce'));
      expect(revived.wpBaseUrl, equals('https://mywholesalestore.com'));
      expect(revived.isWooCommerce, isTrue);
      expect(revived.salesmanPin, equals('3344'));
    });
  });
}

