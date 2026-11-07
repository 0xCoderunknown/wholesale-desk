import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';

enum StockFilterType { all, inStock, outOfStock }

class DeskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Product> _products = [];
  String _searchQuery = '';
  String _selectedBrand = 'All';
  StockFilterType _stockFilter = StockFilterType.all;
  bool _isLoading = true;

  List<Product> get allProducts => _products;
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  StockFilterType get stockFilter => _stockFilter;
  bool get isLoading => _isLoading;

  int get totalCount => _products.length;
  int get inStockCount => _products.where((p) => p.inStock).length;
  int get outOfStockCount => _products.where((p) => !p.inStock).length;

  List<String> get brands {
    final set = <String>{'All'};
    for (final p in _products) {
      if (p.brand.trim().isNotEmpty) {
        set.add(p.brand.trim());
      }
    }
    return set.toList();
  }

  /// In-memory instant client-side search (filters on keystroke with 0 network latency)
  List<Product> get filteredProducts {
    return _products.where((p) {
      // Stock filter
      if (_stockFilter == StockFilterType.inStock && !p.inStock) {
        return false;
      }
      if (_stockFilter == StockFilterType.outOfStock && p.inStock) {
        return false;
      }

      // Brand filter
      if (_selectedBrand != 'All' &&
          p.brand.toLowerCase() != _selectedBrand.toLowerCase()) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty && !p.matchesQuery(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();
  }

  DeskProvider() {
    _init();
  }

  void _init() {
    _db.getProductsStream().listen((list) {
      _products = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void setStockFilter(StockFilterType filter) {
    _stockFilter = filter;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedBrand = 'All';
    _stockFilter = StockFilterType.all;
    notifyListeners();
  }

  /// In-place instant toggle for stock (Optimistic UI update + Cloud sync)
  Future<void> toggleStock(String productId, bool newStatus) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _products[index] = _products[index].copyWith(inStock: newStatus);
      notifyListeners();
    }
    await _db.toggleStock(productId, newStatus);
  }

  Future<void> saveProduct(Product product) async {
    await _db.saveProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
  }

  Future<void> seedInitialData() async {
    await _db.seedInitialData();
  }
}

