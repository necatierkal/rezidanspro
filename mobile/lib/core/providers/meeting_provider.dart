import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class MeetingProvider extends ChangeNotifier {
  final ApiService _api;

  List<MeetingModel> _meetings = [];
  bool _isLoading = false;
  String? _errorMessage;

  MeetingProvider(this._api);

  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMeetings(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/meetings', queryParameters: {'community_id': communityId});
      _meetings = (res as List<dynamic>)
          .map((m) => MeetingModel.fromJson(m as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Toplantılar yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMeeting({
    required int communityId,
    required String title,
    String? description,
    required String location,
    required DateTime startAt,
    DateTime? endAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/meetings', body: {
        'community_id': communityId,
        'title': title.trim(),
        'description': description?.trim(),
        'location': location.trim(),
        'start_at': startAt.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
      });

      await loadMeetings(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Toplantı oluşturulamadı.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rsvp(int meetingId, String status, int communityId) async {
    try {
      await _api.post('/meetings/$meetingId/rsvp', body: {'status': status.toUpperCase()});
      await loadMeetings(communityId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
