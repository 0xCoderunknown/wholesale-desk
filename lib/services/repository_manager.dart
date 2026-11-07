import 'dart:async';
import '../config/app_config.dart';
import '../models/app_settings.dart';
import '../models/product.dart';
import '../models/retailer.dart';
import 'database_service.dart';
import 'wholesale_repository.dart';
import 'woocommerce_rest_service.dart';

class RepositoryManager implements WholesaleRepository {
  static final RepositoryManager instance = RepositoryManager._internal();
  RepositoryManager._internal();

  AppSettings _settings = AppSettings.defaults();
  WooCommerceRestService? _wcService;

  AppSettings get currentSettings => _settings;
  bool get isWooCommerce => _settings.isWooCommerce && _settings.wpBaseUrl.isNotEmpty;

  WholesaleRepository get _activeRepo {
    if (isWooCommerce) {
      _wcService ??= WooCommerceRestService(
        baseUrl: _settings.wpBaseUrl,
        initialSettings: _settings,
      );
      return _wcService!;
    }
    return DatabaseService.instance;
  }

  Future<void> initialize() async {
    _settings = AppConfig.initialSettings;
    await DatabaseService.instance.initialize(initialSettings: _settings);
    final stored = await DatabaseService.instance.getSettings();
    if (stored.storeName.isNotEmpty) {
      _settings = stored;
    }

    if (_settings.isWooCommerce && _settings.wpBaseUrl.isNotEmpty) {
      _wcService = WooCommerceRestService(
        baseUrl: _settings.wpBaseUrl,
        initialSettings: _settings,
      );
    }
  }

  void switchBackend({required String backendType, required String wpBaseUrl}) {
    _settings = _settings.copyWith(
      backendType: backendType,
      wpBaseUrl: wpBaseUrl,
    );

    if (backendType == 'woocommerce' && wpBaseUrl.isNotEmpty) {
      _wcService = WooCommerceRestService(
        baseUrl: wpBaseUrl,
        initialSettings: _settings,
      );
    }
  }

  // ================= AUTHENTICATION HELPERS =================

  Future<Map<String, dynamic>> verifyDeskPin(String pin) async {
    if (isWooCommerce && _wcService != null) {
      return await _wcService!.loginDesk(pin);
    }

    // Firebase / In-Memory PIN verification
    final trimmedPin = pin.trim();
    if (trimmedPin == _settings.masterPin.trim()) {
      return {'success': true, 'role': 'owner'};
    } else if (trimmedPin == _settings.staffPin.trim()) {
      return {'success': true, 'role': 'staff'};
    } else {
      return {'success': false, 'message': 'Invalid 4-digit Desk PIN'};
    }
  }

  Future<Map<String, dynamic>> verifyRetailer({
    required String mobile,
    required String pin,
  }) async {
    if (isWooCommerce && _wcService != null) {
      return await _wcService!.loginRetailer(mobile: mobile, pin: pin);
    }

    // Firebase / In-Memory Retailer verification
    final retailers = await getRetailers();
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '').trim();
    final cleanPin = pin.trim();

    try {
      final matching = retailers.firstWhere(
        (r) =>
            r.mobile.replaceAll(RegExp(r'\D'), '').trim() == cleanMobile &&
            r.pin.trim() == cleanPin,
      );

      if (!matching.isActive) {
        return {
          'success': false,
          'message': 'Retailer account suspended. Please contact distributor.',
        };
      }

      return {'success': true, 'retailer': matching};
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid Mobile Number or 4-digit PIN',
      };
    }
  }

  // ================= WHOLESALE REPOSITORY DELEGATION =================

  @override
  Stream<AppSettings> getSettingsStream() => _activeRepo.getSettingsStream();

  @override
  Future<AppSettings> getSettings() async {
    final s = await _activeRepo.getSettings();
    _settings = s;
    return s;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    // Always persist to local DB / Firestore
    await DatabaseService.instance.updateSettings(settings);
    if (isWooCommerce && _wcService != null) {
      await _wcService!.updateSettings(settings);
    }
  }

  @override
  Stream<List<Product>> getProductsStream() => _activeRepo.getProductsStream();

  @override
  Future<List<Product>> getProducts() => _activeRepo.getProducts();

  @override
  Future<void> toggleStock(String productId, bool inStock) =>
      _activeRepo.toggleStock(productId, inStock);

  @override
  Future<void> saveProduct(Product product) => _activeRepo.saveProduct(product);

  @override
  Future<void> deleteProduct(String id) => _activeRepo.deleteProduct(id);

  @override
  Stream<List<Retailer>> getRetailersStream() => _activeRepo.getRetailersStream();

  @override
  Future<List<Retailer>> getRetailers() => _activeRepo.getRetailers();

  @override
  Future<void> saveRetailer(Retailer retailer) => _activeRepo.saveRetailer(retailer);

  @override
  Future<void> deleteRetailer(String id) => _activeRepo.deleteRetailer(id);

  @override
  Future<void> seedInitialData() => _activeRepo.seedInitialData();
}
