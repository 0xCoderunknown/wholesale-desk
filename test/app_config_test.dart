import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig & Root config.json', () {
    test('Default fallback settings match expected constants', () {
      final s = AppConfig.initialSettings;
      expect(s.storeName, isNotEmpty);
      expect(s.whatsappPhone, isNotEmpty);
      expect(s.masterPin, equals('5075'));
      expect(s.staffPin, equals('1122'));
    });

    test('Loads config values from JSON string with Firebase credentials', () {
      const mockJson = '''
      {
        "store_name": "Custom Test Wholesaler",
        "whatsapp_phone": "919988776655",
        "master_pin": "9999",
        "staff_pin": "8888",
        "backend_type": "woocommerce",
        "woocommerce_base_url": "https://teststore.com",
        "firebase": {
          "api_key": "custom-key-123",
          "project_id": "custom-project",
          "app_id": "1:999:web:xyz",
          "messaging_sender_id": "999",
          "auth_domain": "custom.firebaseapp.com",
          "storage_bucket": "custom.appspot.com"
        }
      }
      ''';

      final data = jsonDecode(mockJson) as Map<String, dynamic>;
      expect(data['store_name'], equals('Custom Test Wholesaler'));
      expect(data['whatsapp_phone'], equals('919988776655'));
      expect(data['backend_type'], equals('woocommerce'));
      expect(data['firebase']['api_key'], equals('custom-key-123'));
    });
  });
}

