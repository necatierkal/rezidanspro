import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;

  ResidentDashboardSummaryModel? _residentSummary;
  ManagerDashboardStatsModel? _managerStats;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardProvider(this._api);

  ResidentDashboardSummaryModel? get residentSummary => _residentSummary;
  ManagerDashboardStatsModel? get managerStats => _managerStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadResidentDashboard(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/dashboard/resident', queryParameters: {'community_id': communityId});
      _residentSummary = ResidentDashboardSummaryModel.fromJson(res as Map<String, dynamic>);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Ana sayfa verileri yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadManagerDashboard(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/dashboard/manager', queryParameters: {'community_id': communityId});
      _managerStats = ManagerDashboardStatsModel.fromJson(res as Map<String, dynamic>);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Yönetici dashboard verileri yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }
}
