import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_settings.dart';
import '../models/product.dart';
import '../models/retailer.dart';
import 'wholesale_repository.dart';

class DatabaseService implements WholesaleRepository {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  bool get isLiveFirebase => _isFirebaseAvailable;

  // In-memory fallback state for offline / initial testing without Firebase credentials
  AppSettings _fallbackSettings = AppSettings.defaults();
  final List<Retailer> _fallbackRetailers = [];
  final List<Product> _fallbackProducts = [];

  final _settingsController = StreamController<AppSettings>.broadcast();
  final _retailersController = StreamController<List<Retailer>>.broadcast();
  final _productsController = StreamController<List<Product>>.broadcast();

  Future<void> initialize({AppSettings? initialSettings}) async {
    if (initialSettings != null) {
      _fallbackSettings = initialSettings;
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
      }
    } catch (e) {
      _isFirebaseAvailable = false;
    }

    // Initialize sample fallback data in case Firestore is not connected or empty
    _initFallbackData(initialSettings: initialSettings);
  }

  void _initFallbackData({AppSettings? initialSettings}) {
    _fallbackSettings = initialSettings ?? AppSettings.defaults();
    _fallbackRetailers.clear();
    _fallbackRetailers.addAll([
      const Retailer(
        id: 'ret_1',
        storeName: 'Gupta Provision Store',
        mobile: '9876543210',
        pin: '1234',
        route: 'Central Market Route',
        status: 'active',
      ),
      const Retailer(
        id: 'ret_2',
        storeName: 'New Bharat Traders',
        mobile: '9876500001',
        pin: '4321',
        route: 'Station Road Route',
        status: 'active',
      ),
      const Retailer(
        id: 'ret_3',
        storeName: 'City Medical & General',
        mobile: '9876500002',
        pin: '9999',
        route: 'Highway Bypass Route',
        status: 'active',
      ),
    ]);

    _fallbackProducts.clear();
    _fallbackProducts.addAll([
      Product(
        id: 'prod_1',
        name: 'Dettol Antiseptic Liquid 500ml',
        brand: 'Reckitt',
        mrp: 330.0,
        ptr: 285.0,
        scheme: '12+1 Free',
        moq: 12,
        cartonPack: 24,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_2',
        name: 'Parle-G Gold Biscuits 1kg (Box of 12)',
        brand: 'Parle',
        mrp: 1440.0,
        ptr: 1220.0,
        scheme: '5% Cash Disc',
        moq: 5,
        cartonPack: 12,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_3',
        name: 'Colgate MaxFresh Blue Gel 150g',
        brand: 'Colgate',
        mrp: 135.0,
        ptr: 112.0,
        scheme: '10+1 Free',
        moq: 20,
        cartonPack: 72,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_4',
        name: 'Surf Excel Quick Wash 1kg Pouch',
        brand: 'Hindustan Unilever',
        mrp: 165.0,
        ptr: 142.0,
        scheme: 'Buy 24 Get ₹100 Off',
        moq: 10,
        cartonPack: 24,
        inStock: false,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_5',
        name: 'Tata Tea Gold Leaf 500g',
        brand: 'Tata Consumer',
        mrp: 310.0,
        ptr: 268.0,
        scheme: '10+1 Free',
        moq: 10,
        cartonPack: 20,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_6',
        name: 'Cadbury Dairy Milk Silk 60g (Pack of 24)',
        brand: 'Mondelez',
        mrp: 1920.0,
        ptr: 1650.0,
        scheme: '3% Special Scheme',
        moq: 2,
        cartonPack: 8,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_7',
        name: 'Fortune Sunlite Sunflower Oil 1L Pouch',
        brand: 'Adani Wilmar',
        mrp: 145.0,
        ptr: 128.0,
        scheme: 'Net Rate',
        moq: 15,
        cartonPack: 15,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_8',
        name: 'Aashirvaad Shudh Chakki Atta 10kg',
        brand: 'ITC',
        mrp: 475.0,
        ptr: 415.0,
        scheme: '20 Bags + 1 Free',
        moq: 5,
        cartonPack: 5,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_9',
        name: 'Good Knight Gold Flash Machine + Refill',
        brand: 'Godrej',
        mrp: 115.0,
        ptr: 96.0,
        scheme: '12+1 Free',
        moq: 12,
        cartonPack: 48,
        inStock: false,
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_10',
        name: 'Sensodyne Fresh Mint Toothpaste 100g',
        brand: 'Haleon',
        mrp: 175.0,
        ptr: 148.0,
        scheme: '5% Scheme',
        moq: 10,
        cartonPack: 36,
        inStock: true,
        updatedAt: DateTime.now(),
      ),
    ]);

    _settingsController.add(_fallbackSettings);
    _retailersController.add(List.unmodifiable(_fallbackRetailers));
    _productsController.add(List.unmodifiable(_fallbackProducts));
  }

  // ================= SETTINGS =================

  @override
  Stream<AppSettings> getSettingsStream() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!
          .collection('settings')
          .doc('general')
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final settings = AppSettings.fromMap(snapshot.data()!);
          _fallbackSettings = settings;
          return settings;
        }
        return _fallbackSettings;
      });
    }
    return _settingsController.stream;
  }

  @override
  Future<AppSettings> getSettings() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final doc = await _firestore!.collection('settings').doc('general').get();
        if (doc.exists && doc.data() != null) {
          return AppSettings.fromMap(doc.data()!);
        }
      } catch (_) {}
    }
    return _fallbackSettings;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _fallbackSettings = settings;
    _settingsController.add(_fallbackSettings);

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('settings').doc('general').set(
              settings.toMap(),
              SetOptions(merge: true),
            );
      } catch (_) {}
    }
  }

  // ================= RETAILERS =================

  @override
  Stream<List<Retailer>> getRetailersStream() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('retailers').snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Retailer.fromMap(doc.id, doc.data()))
            .toList();
        if (list.isNotEmpty) {
          _fallbackRetailers.clear();
          _fallbackRetailers.addAll(list);
          return list;
        }
        return _fallbackRetailers;
      });
    }
    return _buildRetailersStream();
  }

  Stream<List<Retailer>> _buildRetailersStream() async* {
    yield List<Retailer>.unmodifiable(_fallbackRetailers);
    yield* _retailersController.stream;
  }

  @override
  Future<List<Retailer>> getRetailers() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snap = await _firestore!.collection('retailers').get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((doc) => Retailer.fromMap(doc.id, doc.data()))
              .toList();
          _fallbackRetailers.clear();
          _fallbackRetailers.addAll(list);
          return list;
        }
      } catch (_) {}
    }
    return _fallbackRetailers;
  }

  @override
  Future<void> saveRetailer(Retailer retailer) async {
    final index = _fallbackRetailers.indexWhere((r) => r.id == retailer.id);
    if (index >= 0) {
      _fallbackRetailers[index] = retailer;
    } else {
      _fallbackRetailers.add(retailer);
    }
    _retailersController.add(List.unmodifiable(_fallbackRetailers));

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final ref = _firestore!.collection('retailers').doc(retailer.id);
        await ref.set(retailer.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteRetailer(String id) async {
    _fallbackRetailers.removeWhere((r) => r.id == id);
    _retailersController.add(List.unmodifiable(_fallbackRetailers));

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('retailers').doc(id).delete();
      } catch (_) {}
    }
  }

  // ================= PRODUCTS =================

  @override
  Stream<List<Product>> getProductsStream() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('products').snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList();
        if (list.isNotEmpty) {
          _fallbackProducts.clear();
          _fallbackProducts.addAll(list);
          return list;
        }
        return _fallbackProducts;
      });
    }
    return _productsController.stream;
  }

  @override
  Future<List<Product>> getProducts() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snap = await _firestore!.collection('products').get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((doc) => Product.fromMap(doc.id, doc.data()))
              .toList();
          _fallbackProducts.clear();
          _fallbackProducts.addAll(list);
          return list;
        }
      } catch (_) {}
    }
    return _fallbackProducts;
  }

  /// In-place toggle for stock status (binary stock model)
  @override
  Future<void> toggleStock(String productId, bool inStock) async {
    final index = _fallbackProducts.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _fallbackProducts[index] = _fallbackProducts[index].copyWith(
        inStock: inStock,
        updatedAt: DateTime.now(),
      );
      _productsController.add(List.unmodifiable(_fallbackProducts));
    }

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('products').doc(productId).update({
          'in_stock': inStock,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> saveProduct(Product product) async {
    final index = _fallbackProducts.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _fallbackProducts[index] = product;
    } else {
      _fallbackProducts.add(product);
    }
    _productsController.add(List.unmodifiable(_fallbackProducts));

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final data = product.toMap();
        data['updated_at'] = FieldValue.serverTimestamp();
        await _firestore!
            .collection('products')
            .doc(product.id)
            .set(data, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    _fallbackProducts.removeWhere((p) => p.id == id);
    _productsController.add(List.unmodifiable(_fallbackProducts));

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('products').doc(id).delete();
      } catch (_) {}
    }
  }

  /// One-click cloud seed to populate Firestore with sample data
  @override
  Future<void> seedInitialData() async {
    if (_isFirebaseAvailable && _firestore != null) {
      // 1. Settings
      await _firestore!
          .collection('settings')
          .doc('general')
          .set(_fallbackSettings.toMap());

      // 2. Retailers
      for (final r in _fallbackRetailers) {
        await _firestore!.collection('retailers').doc(r.id).set(r.toMap());
      }

      // 3. Products
      for (final p in _fallbackProducts) {
        await _firestore!.collection('products').doc(p.id).set(p.toMap());
      }
    }
  }
}
