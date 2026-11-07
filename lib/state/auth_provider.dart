import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/retailer.dart';
import '../services/database_service.dart';

enum UserRole {
  unauthenticated,
  admin,
  staff,
  retailer,
}

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  UserRole _role = UserRole.unauthenticated;
  Retailer? _currentRetailer;
  AppSettings _settings = AppSettings.defaults();
  String? _errorMessage;
  bool _isLoading = false;

  UserRole get role => _role;
  Retailer? get currentRetailer => _currentRetailer;
  AppSettings get settings => _settings;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _role != UserRole.unauthenticated;
  bool get isAdmin => _role == UserRole.admin;
  bool get isStaff => _role == UserRole.staff;
  bool get isRetailer => _role == UserRole.retailer;

  AuthProvider() {
    _init();
  }

  void _init() {
    _db.getSettingsStream().listen((settings) {
      _settings = settings;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Desk Authentication (Master PIN for Admin, Staff PIN for Staff)
  Future<bool> loginWithPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Fetch latest settings if needed
    final currentSettings = await _db.getSettings();
    _settings = currentSettings;

    final trimmedPin = pin.trim();
    if (trimmedPin == _settings.masterPin.trim()) {
      _role = UserRole.admin;
      _currentRetailer = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (trimmedPin == _settings.staffPin.trim()) {
      _role = UserRole.staff;
      _currentRetailer = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = 'Invalid 4-digit Desk PIN';
      notifyListeners();
      return false;
    }
  }

  /// Retailer Authentication (Mobile + 4-digit PIN)
  Future<bool> loginRetailer({
    required String mobile,
    required String pin,
    required List<Retailer> retailers,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '').trim();
    final cleanPin = pin.trim();

    try {
      final matching = retailers.firstWhere(
        (r) =>
            r.mobile.replaceAll(RegExp(r'\D'), '').trim() == cleanMobile &&
            r.pin.trim() == cleanPin,
      );

      if (!matching.isActive) {
        _isLoading = false;
        _errorMessage = 'Your retailer account is currently suspended. Please contact distributor.';
        notifyListeners();
        return false;
      }

      _role = UserRole.retailer;
      _currentRetailer = matching;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Invalid Mobile Number or 4-digit PIN';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _role = UserRole.unauthenticated;
    _currentRetailer = null;
    _errorMessage = null;
    notifyListeners();
  }
}

