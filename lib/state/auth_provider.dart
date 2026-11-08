import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/retailer.dart';
import '../services/repository_manager.dart';

enum UserRole {
  unauthenticated,
  admin,
  staff,
  retailer,
}

class AuthProvider extends ChangeNotifier {
  final RepositoryManager _repo;

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

  AuthProvider({RepositoryManager? repository}) : _repo = repository ?? RepositoryManager.instance {
    _init();
  }

  void _init() {
    _repo.getSettingsStream().listen((settings) {
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

    // Fetch latest settings
    _settings = await _repo.getSettings();

    final result = await _repo.verifyDeskPin(pin);

    _isLoading = false;
    if (result['success'] == true) {
      final roleStr = result['role']?.toString();
      _role = (roleStr == 'owner' || roleStr == 'admin') ? UserRole.admin : UserRole.staff;
      _currentRetailer = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message']?.toString() ?? 'Invalid 4-digit Desk PIN';
      notifyListeners();
      return false;
    }
  }

  /// Retailer Authentication (Mobile + 4-digit PIN)
  Future<bool> loginRetailer({
    required String mobile,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.verifyRetailer(mobile: mobile, pin: pin);

    _isLoading = false;
    if (result['success'] == true && result['retailer'] is Retailer) {
      _role = UserRole.retailer;
      _currentRetailer = result['retailer'] as Retailer;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message']?.toString() ?? 'Invalid Mobile Number or 4-digit PIN';
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

  @visibleForTesting
  void setRoleForTesting(UserRole role) {
    _role = role;
    notifyListeners();
  }
}
