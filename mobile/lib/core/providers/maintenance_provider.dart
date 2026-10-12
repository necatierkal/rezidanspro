import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  final ApiService _api;

  List<MaintenanceModel> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusFilter;
  String? _categoryFilter;

  MaintenanceProvider(this._api);

  List<MaintenanceModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;

  void setFilters({String? status, String? category}) {
    _statusFilter = status;
    _categoryFilter = category;
    notifyListeners();
  }

  Future<void> loadRequests(int communityId, {bool mineOnly = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{'community_id': communityId};
      if (mineOnly) params['mine_only'] = true;
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        params['status_filter'] = _statusFilter;
      }
      if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
        params['category_filter'] = _categoryFilter;
      }

      final res = await _api.get('/maintenance', queryParameters: params);
      _requests = (res as List<dynamic>)
          .map((m) => MaintenanceModel.fromJson(m as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Arıza kayıtları yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reportFault({
    required int communityId,
    int? apartmentId,
    required String title,
    required String description,
    required String category,
    String priority = 'NORMAL',
    String? photoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/maintenance', body: {
        'community_id': communityId,
        'apartment_id': apartmentId,
        'title': title.trim(),
        'description': description.trim(),
        'category': category.toUpperCase(),
        'priority': priority.toUpperCase(),
        'photo_url': photoUrl,
      });

      await loadRequests(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Arıza bildirimi kaydedilemedi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int id, String newStatus, int communityId) async {
    try {
      final res = await _api.put('/maintenance/$id', body: {'status': newStatus.toUpperCase()});
      final updated = MaintenanceModel.fromJson(res as Map<String, dynamic>);
      final idx = _requests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _requests[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addComment(int requestId, String body) async {
    try {
      final res = await _api.post('/maintenance/$requestId/comments', body: {'body': body.trim()});
      final comment = MaintenanceCommentModel.fromJson(res as Map<String, dynamic>);
      final idx = _requests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _requests[idx].comments.add(comment);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
