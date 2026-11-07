import '../models/app_settings.dart';
import '../models/product.dart';
import '../models/retailer.dart';

abstract class WholesaleRepository {
  // Settings
  Stream<AppSettings> getSettingsStream();
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);

  // Products
  Stream<List<Product>> getProductsStream();
  Future<List<Product>> getProducts();
  Future<void> toggleStock(String productId, bool inStock);
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String id);

  // Retailers
  Stream<List<Retailer>> getRetailersStream();
  Future<List<Retailer>> getRetailers();
  Future<void> saveRetailer(Retailer retailer);
  Future<void> deleteRetailer(String id);

  // Utility
  Future<void> seedInitialData();
}

