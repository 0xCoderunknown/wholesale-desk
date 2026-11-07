import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import 'firebase_options.dart';

class AppConfig {
  static AppSettings _settings = AppSettings.defaults();
  static FirebaseOptions? _firebaseOptions;
  static bool _isLoaded = false;

  static AppSettings get initialSettings => _settings;
  static FirebaseOptions get firebaseOptions =>
      _firebaseOptions ?? DefaultFirebaseOptions.currentPlatform;
  static bool get isLoaded => _isLoaded;

  /// Loads `config.json` from root assets on app startup
  static Future<void> load() async {
    Map<String, dynamic>? data;

    // 1. Try to load root config.json
    try {
      final jsonString = await rootBundle.loadString('config.json');
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Notice: Root config.json not loaded ($e). Using defaults.');
    }

    if (data != null) {
      // Resolve active backend flag
      final activeBackend = (data['active_backend'] ?? data['backend_type'] ?? 'firebase')
          .toString()
          .toLowerCase();

      // Resolve WooCommerce section
      String wcUrl = '';
      if (data['woocommerce'] is Map) {
        final wc = data['woocommerce'] as Map<String, dynamic>;
        wcUrl = wc['site_url']?.toString() ?? '';
      } else {
        wcUrl = data['woocommerce_base_url']?.toString() ?? '';
      }

      // Resolve Store Identity (bootstrap values before live database sync)
      String storeName = 'Apex Wholesale Distributors';
      String phone = '917002796068';
      String masterPin = '5075';
      String staffPin = '1122';

      if (data['store_identity'] is Map) {
        final identity = data['store_identity'] as Map<String, dynamic>;
        storeName = identity['store_name']?.toString() ?? storeName;
        phone = identity['whatsapp_phone']?.toString() ?? phone;
        masterPin = identity['master_pin']?.toString() ?? masterPin;
        staffPin = identity['staff_pin']?.toString() ?? staffPin;
      } else {
        storeName = data['store_name']?.toString() ?? storeName;
        phone = data['whatsapp_phone']?.toString() ?? phone;
        masterPin = data['master_pin']?.toString() ?? masterPin;
        staffPin = data['staff_pin']?.toString() ?? staffPin;
      }

      _settings = AppSettings(
        storeName: storeName,
        whatsappPhone: phone,
        masterPin: masterPin,
        staffPin: staffPin,
        backendType: activeBackend,
        wpBaseUrl: wcUrl,
      );

      // Resolve Firebase section from config.json
      if (data['firebase'] is Map) {
        final fb = data['firebase'] as Map<String, dynamic>;
        if (fb['api_key'] != null && fb['api_key'] != 'YOUR_FIREBASE_API_KEY') {
          _firebaseOptions = FirebaseOptions(
            apiKey: fb['api_key']?.toString() ?? 'demo-api-key',
            appId: fb['app_id']?.toString() ?? '1:1234567890:web:abcdef',
            messagingSenderId: fb['messaging_sender_id']?.toString() ?? '1234567890',
            projectId: fb['project_id']?.toString() ?? 'wholesale-desk-demo',
            authDomain: fb['auth_domain']?.toString() ?? '',
            storageBucket: fb['storage_bucket']?.toString() ?? '',
          );
        }
      }
    }

    // 2. Check if a dedicated 'firebase-config.json' was registered in assets
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetList = manifest.listAssets();
      final hasFbConfig = assetList.any((a) => a.endsWith('firebase-config.json'));
      if (hasFbConfig) {
        final fbPath = assetList.firstWhere((a) => a.endsWith('firebase-config.json'));
        final fbString = await rootBundle.loadString(fbPath);
        final fbData = jsonDecode(fbString) as Map<String, dynamic>;
        if (fbData['apiKey'] != null || fbData['api_key'] != null) {
          _firebaseOptions = FirebaseOptions(
            apiKey: (fbData['apiKey'] ?? fbData['api_key'])?.toString() ?? '',
            appId: (fbData['appId'] ?? fbData['app_id'])?.toString() ?? '',
            messagingSenderId: (fbData['messagingSenderId'] ?? fbData['messaging_sender_id'])?.toString() ?? '',
            projectId: (fbData['projectId'] ?? fbData['project_id'])?.toString() ?? '',
            authDomain: (fbData['authDomain'] ?? fbData['auth_domain'])?.toString() ?? '',
            storageBucket: (fbData['storageBucket'] ?? fbData['storage_bucket'])?.toString() ?? '',
          );
          debugPrint('Loaded dedicated Firebase credentials from $fbPath!');
        }
      }
    } catch (_) {
      // Asset manifest check or parsing fallback
    }

    _isLoaded = true;
    debugPrint('AppConfig active backend: ${_settings.backendType}');
  }
}
