import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _api;

  List<PrivateMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  MessageProvider(this._api);

  List<PrivateMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMessages(int communityId, {int? contactUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{'community_id': communityId};
      if (contactUserId != null) {
        params['contact_user_id'] = contactUserId;
      }

      final res = await _api.get('/messages', queryParameters: params);
      _messages = (res as List<dynamic>)
          .map((m) => PrivateMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Mesajlar yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required int communityId,
    required int receiverId,
    String? subject,
    required String body,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/messages', body: {
        'community_id': communityId,
        'receiver_id': receiverId,
        'subject': subject?.trim(),
        'body': body.trim(),
      });

      await loadMessages(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Mesaj gönderilemedi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markRead(int messageId) async {
    try {
      await _api.put('/messages/$messageId/read');
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        // Updated in place
        notifyListeners();
      }
    } catch (_) {}
  }
}
