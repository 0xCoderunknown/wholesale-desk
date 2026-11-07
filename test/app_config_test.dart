import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('config.json format and backend toggle flag', () {
    test('Parses active_backend flag with distinct woocommerce and firebase sections', () {
      const configJson = '''
      {
        "active_backend": "woocommerce",
        "store_identity": {
          "store_name": "Test Wholesaler"
        },
        "woocommerce": {
          "site_url": "https://example.com"
        },
        "firebase": {
          "api_key": "AIzaSy...",
          "project_id": "my-firebase-app"
        }
      }
      ''';

      final data = jsonDecode(configJson) as Map<String, dynamic>;
      expect(data['active_backend'], equals('woocommerce'));
      expect((data['store_identity'] as Map)['store_name'], equals('Test Wholesaler'));
      expect((data['woocommerce'] as Map)['site_url'], equals('https://example.com'));
      expect((data['firebase'] as Map)['api_key'], equals('AIzaSy...'));
    });
  });
}
