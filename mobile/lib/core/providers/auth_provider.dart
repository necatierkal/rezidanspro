import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/mock_data_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._api, this._storage) {
    _initFromStorage();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _storage.accessToken != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initFromStorage() {
    if (_storage.accessToken != null && _storage.userId != null) {
      _currentUser = UserModel(
        id: _storage.userId!,
        uuid: '',
        email: _storage.userEmail ?? '',
        firstName: '',
        lastName: '',
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login', body: {
        'email': email.trim(),
        'password': password,
      });

      final accessToken = (res['access_token'] as String?) ?? 'demo_token';
      final refreshToken = (res['refresh_token'] as String?) ?? 'demo_refresh';
      final userId = (res['user_id'] as int?) ?? (res['user']?['id'] as int? ?? 1);
      final userEmail = (res['email'] as String?) ?? (res['user']?['email'] as String? ?? email);
      final role = (res['role'] as String?) ?? (res['user']?['role'] as String? ?? 'RESIDENT');
      final firstName = (res['first_name'] as String?) ?? (res['user']?['first_name'] as String? ?? '');
      final lastName = (res['last_name'] as String?) ?? (res['user']?['last_name'] as String? ?? '');

      await _storage.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        email: userEmail,
        role: role,
      );

      _currentUser = UserModel(
        id: userId,
        uuid: '',
        email: userEmail,
        firstName: firstName,
        lastName: lastName,
        isActive: true,
        createdAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Giriş yapılamadı. Lütfen tekrar deneyin.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginDemo({required bool asManager}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _storage.setIsDemoMode(true);
    MockDataService().isManagerMode = asManager;

    final userId = asManager ? 1 : 2;
    final email = asManager ? 'manager@rezidanspro.app' : 'resident@rezidanspro.app';
    final role = asManager ? 'MANAGER' : 'RESIDENT';
    final firstName = asManager ? 'Kemal' : 'Necati';
    final lastName = asManager ? 'Yılmaz' : 'Erkal';

    await _storage.saveAuthData(
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
      userId: userId,
      email: email,
      role: role,
    );
    await _storage.setSelectedCommunityId(1);

    _currentUser = UserModel(
      id: userId,
      uuid: asManager ? 'u-mgr-001' : 'u-res-002',
      email: email,
      firstName: firstName,
      lastName: lastName,
      isActive: true,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/register', body: {
        'email': email.trim(),
        'password': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone': phone?.trim(),
      });

      final accessToken = res['access_token'] as String;
      final refreshToken = res['refresh_token'] as String;
      final userId = res['user_id'] as int;
      final userEmail = res['email'] as String;
      final role = res['role'] as String;

      await _storage.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        email: userEmail,
        role: role,
      );

      _currentUser = UserModel(
        id: userId,
        uuid: '',
        email: userEmail,
        firstName: firstName,
        lastName: lastName,
        isActive: true,
        createdAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Kayıt oluşturulamadı. Lütfen tekrar deneyin.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _api.get('/auth/me');
      _currentUser = UserModel.fromJson(res as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> logout() async {
    await _storage.clearAuth();
    _currentUser = null;
    notifyListeners();
    return true;
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete('/auth/account');
      await logout();
      _isLoading = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Hesap silinemedi. Lütfen tekrar deneyin.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
