import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';
import '../models/product.dart';
import '../models/retailer.dart';
import 'wholesale_repository.dart';

class WooCommerceRestService implements WholesaleRepository {
  String _baseUrl;
  String _sessionToken = '';
  String? _currentRole; // 'owner' | 'staff'

  final StreamController<AppSettings> _settingsController = StreamController<AppSettings>.broadcast();
  final StreamController<List<Product>> _productsController = StreamController<List<Product>>.broadcast();
  final StreamController<List<Retailer>> _retailersController = StreamController<List<Retailer>>.broadcast();

  List<Product> _cachedProducts = [];
  List<Retailer> _cachedRetailers = [];
  AppSettings _cachedSettings;

  WooCommerceRestService({
    required String baseUrl,
    AppSettings? initialSettings,
  })  : _baseUrl = _cleanBaseUrl(baseUrl),
        _cachedSettings = initialSettings ?? AppSettings.defaults();

  static String _cleanBaseUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    // If user provided root site URL without /wp-json/swac/v1, append it
    if (!cleaned.contains('/wp-json/swac/v1')) {
      if (cleaned.contains('/wp-json')) {
        cleaned = '$cleaned/swac/v1';
      } else {
        cleaned = '$cleaned/wp-json/swac/v1';
      }
    }
    return cleaned;
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = _cleanBaseUrl(newUrl);
  }

  String get baseUrl => _baseUrl;
  String get sessionToken => _sessionToken;
  String? get currentRole => _currentRole;
  Map<String, String> get headers => _headers;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_sessionToken.isNotEmpty) ...{
          'X-SWAC-Master-Token': _sessionToken,
          'X-SWAC-Retailer-Token': _sessionToken,
        },
      };

  // ================= AUTHENTICATION =================

  /// Authenticates with WordPress backend using 4-digit PIN (Master, Staff, or Salesman)
  Future<Map<String, dynamic>> loginDesk(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/desk/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin.trim()}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        _sessionToken = data['token']?.toString() ?? '';
        _currentRole = data['role']?.toString() ?? 'owner';
        // Refresh products upon login
        await getProducts();
        // Role-guard getSettings: only owner/admin has permission to read settings
        if (_currentRole == 'owner' || _currentRole == 'admin') {
          await getSettings();
        }
        return {'success': true, 'role': _currentRole};
      } else {
        return {
          'success': false,
          'message': data['message']?.toString() ?? 'Authentication failed',
        };
      }
    } catch (e) {
      debugPrint('WooCommerce loginDesk error: $e');
      return {'success': false, 'message': 'Could not connect to WordPress: $e'};
    }
  }

  /// Authenticates Retailer via WordPress REST API
  Future<Map<String, dynamic>> loginRetailer({
    required String mobile,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/retailer-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': mobile.replaceAll(RegExp(r'\D'), '').trim(),
          'pin': pin.trim(),
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        final retData = data['retailer'] as Map<String, dynamic>?;
        final token = retData?['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          _sessionToken = token;
          _currentRole = 'retailer';
          // Refresh products using retailer token
          await getProducts();
        }
        return {
          'success': true,
          'retailer': Retailer(
            id: 'ret_${retData?['phone'] ?? mobile}',
            storeName: retData?['store_name']?.toString() ?? 'Retailer $mobile',
            mobile: retData?['phone']?.toString() ?? mobile,
            pin: pin,
            route: retData?['area']?.toString() ?? '',
            status: 'active',
          ),
        };
      } else {
        return {
          'success': false,
          'message': data['message']?.toString() ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      debugPrint('WooCommerce loginRetailer error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ================= SETTINGS =================

  @override
  Stream<AppSettings> getSettingsStream() {
    return _settingsController.stream;
  }

  @override
  Future<AppSettings> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/desk/settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['settings'] is Map) {
          final s = data['settings'] as Map<String, dynamic>;
          _cachedSettings = _cachedSettings.copyWith(
            whatsappPhone: s['phone_number']?.toString() ?? _cachedSettings.whatsappPhone,
            storeName: s['store_name']?.toString() ?? _cachedSettings.storeName,
            masterPin: (s['master_pin'] != null && s['master_pin'].toString().isNotEmpty)
                ? s['master_pin'].toString()
                : _cachedSettings.masterPin,
            staffPin: (s['staff_pin'] != null && s['staff_pin'].toString().isNotEmpty)
                ? s['staff_pin'].toString()
                : _cachedSettings.staffPin,
            salesmanPin: (s['salesman_pin'] != null && s['salesman_pin'].toString().isNotEmpty)
                ? s['salesman_pin'].toString()
                : _cachedSettings.salesmanPin,
          );
          _settingsController.add(_cachedSettings);
        }
      }
    } catch (e) {
      debugPrint('WooCommerce getSettings error: $e');
    }
    return _cachedSettings;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _cachedSettings = settings;
    _settingsController.add(_cachedSettings);

    try {
      await http.post(
        Uri.parse('$_baseUrl/desk/settings'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': settings.whatsappPhone,
          'store_name': settings.storeName,
          if (settings.masterPin.isNotEmpty) 'master_pin': settings.masterPin,
          if (settings.staffPin.isNotEmpty) 'staff_pin': settings.staffPin,
          if (settings.salesmanPin.isNotEmpty) 'salesman_pin': settings.salesmanPin,
        }),
      );
    } catch (e) {
      debugPrint('WooCommerce updateSettings error: $e');
    }
  }

  // ================= PRODUCTS =================

  @override
  Stream<List<Product>> getProductsStream() {
    return _productsController.stream;
  }

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/desk/products'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['products'] is List) {
          final list = (data['products'] as List).map((item) {
            final m = item as Map<String, dynamic>;
            return Product(
              id: m['id']?.toString() ?? '0',
              name: m['name']?.toString() ?? '',
              brand: m['brand']?.toString() ?? '',
              mrp: (m['mrp'] is num) ? (m['mrp'] as num).toDouble() : double.tryParse(m['mrp']?.toString() ?? '0') ?? 0.0,
              ptr: (m['ptr'] is num) ? (m['ptr'] as num).toDouble() : double.tryParse(m['ptr']?.toString() ?? '0') ?? 0.0,
              scheme: m['scheme_shorthand']?.toString() ?? m['scheme_badge']?.toString() ?? '',
              moq: (m['moq'] is num) ? (m['moq'] as num).toInt() : int.tryParse(m['moq']?.toString() ?? '1') ?? 1,
              cartonPack: (m['carton_pack'] is num) ? (m['carton_pack'] as num).toInt() : int.tryParse(m['carton_pack']?.toString() ?? '0') ?? 0,
              inStock: m['in_stock'] is bool ? m['in_stock'] as bool : true,
              imageUrl: '', // Binary zero-bloat
              updatedAt: DateTime.now(),
            );
          }).toList();

          _cachedProducts = list;
          _productsController.add(List.unmodifiable(_cachedProducts));
          return list;
        }
      }
    } catch (e) {
      debugPrint('WooCommerce getProducts error: $e');
    }
    return _cachedProducts;
  }

  /// High-speed in-place row update (<100ms) for stock toggle and rate updates
  @override
  Future<void> toggleStock(String productId, bool inStock) async {
    // 1. Optimistic UI update
    final index = _cachedProducts.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _cachedProducts[index] = _cachedProducts[index].copyWith(inStock: inStock);
      _productsController.add(List.unmodifiable(_cachedProducts));
    }

    // 2. Call /desk/fast-row-update endpoint
    try {
      await http.post(
        Uri.parse('$_baseUrl/desk/fast-row-update'),
        headers: _headers,
        body: jsonEncode({
          'id': int.tryParse(productId) ?? productId,
          'in_stock': inStock,
        }),
      );
    } catch (e) {
      debugPrint('WooCommerce fast-row-update stock error: $e');
    }
  }

  @override
  Future<void> saveProduct(Product product) async {
    // 1. Optimistic local cache update
    final index = _cachedProducts.indexWhere((p) => p.id == product.id);
    final isNew = index < 0 || product.id.startsWith('prod_');

    if (isNew) {
      _cachedProducts.add(product);
    } else {
      _cachedProducts[index] = product;
    }
    _productsController.add(List.unmodifiable(_cachedProducts));

    try {
      if (isNew) {
        // Create product
        final response = await http.post(
          Uri.parse('$_baseUrl/desk/create-product'),
          headers: _headers,
          body: jsonEncode({
            'name': product.name,
            'brand': product.brand,
            'mrp': product.mrp,
            'ptr': product.ptr,
            'moq': product.moq,
            'carton_pack': product.cartonPack,
            'scheme_shorthand': product.scheme,
            'in_stock': product.inStock,
          }),
        );
        if (response.statusCode == 200) {
          await getProducts(); // Refresh with real WooCommerce product ID
        }
      } else {
        // In-place fast row update
        await http.post(
          Uri.parse('$_baseUrl/desk/fast-row-update'),
          headers: _headers,
          body: jsonEncode({
            'id': int.tryParse(product.id) ?? product.id,
            'ptr': product.ptr,
            'mrp': product.mrp,
            'moq': product.moq,
            'carton_pack': product.cartonPack,
            'scheme_shorthand': product.scheme,
            'in_stock': product.inStock,
          }),
        );
      }
    } catch (e) {
      debugPrint('WooCommerce saveProduct error: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    _cachedProducts.removeWhere((p) => p.id == id);
    _productsController.add(List.unmodifiable(_cachedProducts));

    // WooCommerce fast toggle to outofstock or delete if supported
    try {
      await http.post(
        Uri.parse('$_baseUrl/desk/fast-row-update'),
        headers: _headers,
        body: jsonEncode({
          'id': int.tryParse(id) ?? id,
          'in_stock': false,
        }),
      );
    } catch (e) {
      debugPrint('WooCommerce deleteProduct error: $e');
    }
  }

  // ================= RETAILERS =================

  @override
  Stream<List<Retailer>> getRetailersStream() {
    return _retailersController.stream;
  }

  @override
  Future<List<Retailer>> getRetailers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/desk/retailers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['retailers'] is List) {
          final list = (data['retailers'] as List).map((item) {
            final m = item as Map<String, dynamic>;
            final phone = m['phone']?.toString() ?? '';
            return Retailer(
              id: 'ret_$phone',
              storeName: m['store_name']?.toString() ?? '',
              mobile: phone,
              pin: m['pin']?.toString() ?? '',
              route: m['route']?.toString() ?? m['area']?.toString() ?? '',
              status: m['status']?.toString() ?? 'active',
            );
          }).toList();

          _cachedRetailers = list;
          _retailersController.add(List.unmodifiable(_cachedRetailers));
          return list;
        }
      }
    } catch (e) {
      debugPrint('WooCommerce getRetailers error: $e');
    }
    return _cachedRetailers;
  }

  @override
  Future<void> saveRetailer(Retailer retailer) async {
    final index = _cachedRetailers.indexWhere((r) => r.mobile == retailer.mobile);
    if (index >= 0) {
      _cachedRetailers[index] = retailer;
    } else {
      _cachedRetailers.add(retailer);
    }
    _retailersController.add(List.unmodifiable(_cachedRetailers));

    try {
      await http.post(
        Uri.parse('$_baseUrl/desk/save-retailer'),
        headers: _headers,
        body: jsonEncode({
          'phone': retailer.mobile,
          'pin': retailer.pin,
          'store_name': retailer.storeName,
          'area': retailer.route,
          'status': retailer.status,
        }),
      );
    } catch (e) {
      debugPrint('WooCommerce saveRetailer error: $e');
    }
  }

  @override
  Future<void> deleteRetailer(String id) async {
    final retailer = _cachedRetailers.firstWhere((r) => r.id == id, orElse: () => Retailer(id: id, storeName: '', mobile: id, pin: '', route: ''));
    _cachedRetailers.removeWhere((r) => r.id == id);
    _retailersController.add(List.unmodifiable(_cachedRetailers));

    try {
      await http.post(
        Uri.parse('$_baseUrl/desk/delete-retailer'),
        headers: _headers,
        body: jsonEncode({'phone': retailer.mobile}),
      );
    } catch (e) {
      debugPrint('WooCommerce deleteRetailer error: $e');
    }
  }

  @override
  Future<void> seedInitialData() async {
    // Refresh catalog from WordPress
    await getProducts();
    await getRetailers();
    await getSettings();
  }
}

