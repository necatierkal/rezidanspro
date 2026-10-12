import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final ApiService _api;

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedPriority; // null, NORMAL, IMPORTANT, URGENT

  AnnouncementProvider(this._api);

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedPriority => _selectedPriority;

  void setPriorityFilter(String? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  Future<void> loadAnnouncements(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{'community_id': communityId};
      if (_selectedPriority != null && _selectedPriority!.isNotEmpty) {
        params['priority'] = _selectedPriority;
      }

      final res = await _api.get('/announcements', queryParameters: params);
      _announcements = (res as List<dynamic>)
          .map((a) => AnnouncementModel.fromJson(a as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Duyurular yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required int communityId,
    required String title,
    required String body,
    String priority = 'NORMAL',
    String? attachmentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/announcements', body: {
        'community_id': communityId,
        'title': title.trim(),
        'body': body.trim(),
        'priority': priority.toUpperCase(),
        'attachment_url': attachmentUrl,
      });

      await loadAnnouncements(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Duyuru oluşturulamadı.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAnnouncement(int id, int communityId) async {
    try {
      await _api.delete('/announcements/$id');
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
