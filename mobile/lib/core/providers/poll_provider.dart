import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class PollProvider extends ChangeNotifier {
  final ApiService _api;

  List<PollModel> _polls = [];
  bool _isLoading = false;
  String? _errorMessage;

  PollProvider(this._api);

  List<PollModel> get polls => _polls;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPolls(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/polls', queryParameters: {'community_id': communityId});
      _polls = (res as List<dynamic>)
          .map((p) => PollModel.fromJson(p as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Anketler yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPoll({
    required int communityId,
    required String title,
    String? description,
    required List<String> options,
    bool isPublicResult = true,
    DateTime? endAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/polls', body: {
        'community_id': communityId,
        'title': title.trim(),
        'description': description?.trim(),
        'options': options.where((o) => o.trim().isNotEmpty).toList(),
        'is_public_result': isPublicResult,
        'end_at': endAt?.toIso8601String(),
      });

      await loadPolls(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Anket oluşturulamadı.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> vote(int pollId, int optionId, int communityId) async {
    try {
      await _api.post('/polls/$pollId/vote', body: {'option_id': optionId});
      await loadPolls(communityId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }
}
