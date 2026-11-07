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
    try {
      final jsonString = await rootBundle.loadString('config.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      _settings = AppSettings(
        storeName: data['store_name']?.toString() ?? 'Apex Wholesale Distributors',
        whatsappPhone: data['whatsapp_phone']?.toString() ?? '917002796068',
        masterPin: data['master_pin']?.toString() ?? '5075',
        staffPin: data['staff_pin']?.toString() ?? '1122',
        backendType: data['backend_type']?.toString() ?? 'firebase',
        wpBaseUrl: data['woocommerce_base_url']?.toString() ?? '',
      );

      final fb = data['firebase'] as Map<String, dynamic>?;
      if (fb != null && fb['api_key'] != null && fb['project_id'] != null) {
        _firebaseOptions = FirebaseOptions(
          apiKey: fb['api_key']?.toString() ?? 'demo-api-key',
          appId: fb['app_id']?.toString() ?? '1:1234567890:web:abcdef',
          messagingSenderId: fb['messaging_sender_id']?.toString() ?? '1234567890',
          projectId: fb['project_id']?.toString() ?? 'wholesale-desk-demo',
          authDomain: fb['auth_domain']?.toString() ?? 'wholesale-desk-demo.firebaseapp.com',
          storageBucket: fb['storage_bucket']?.toString() ?? 'wholesale-desk-demo.appspot.com',
        );
      }

      _isLoaded = true;
      debugPrint('AppConfig loaded from config.json: ${_settings.storeName} (${_settings.backendType})');
    } catch (e) {
      debugPrint('Notice: Root config.json not loaded or invalid ($e). Using built-in defaults.');
    }
  }
}

