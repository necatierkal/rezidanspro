import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class CommunityProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  List<UserMembershipModel> _memberships = [];
  UserMembershipModel? _activeMembership;
  bool _isLoading = false;
  String? _errorMessage;

  CommunityProvider(this._api, this._storage);

  List<UserMembershipModel> get memberships => _memberships;
  UserMembershipModel? get activeMembership => _activeMembership;
  CommunityModel? get activeCommunity => _activeMembership?.community;
  bool get isCurrentUserManager => _activeMembership?.isManager ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMyCommunities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/communities/my');
      final list = (res as List<dynamic>)
          .map((item) => UserMembershipModel.fromJson(item as Map<String, dynamic>))
          .toList();

      _memberships = list;

      if (_memberships.isNotEmpty) {
        final savedId = _storage.selectedCommunityId;
        if (savedId != null) {
          _activeMembership = _memberships.firstWhere(
            (m) => m.community.id == savedId,
            orElse: () => _memberships.first,
          );
        } else {
          _activeMembership = _memberships.first;
          await _storage.setSelectedCommunityId(_activeMembership!.community.id);
        }
      } else {
        _activeMembership = null;
      }

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Bina bilgileri yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchCommunity(int communityId) async {
    final found = _memberships.firstWhere(
      (m) => m.community.id == communityId,
      orElse: () => _activeMembership ?? _memberships.first,
    );
    _activeMembership = found;
    await _storage.setSelectedCommunityId(found.community.id);
    notifyListeners();
  }

  Future<bool> joinCommunity({
    required String inviteCode,
    required int apartmentId,
    bool isOwner = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/communities/join', body: {
        'invite_code': inviteCode.trim(),
        'apartment_id': apartmentId,
        'is_owner': isOwner,
      });

      await loadMyCommunities();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Siteye katılım sağlanamadı. Lütfen davet kodunu kontrol edin.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCommunity({
    required String name,
    required String type,
    String? city,
    String? district,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/communities', body: {
        'name': name.trim(),
        'type': type,
        'city': city?.trim(),
        'district': district?.trim(),
        'address': address?.trim(),
      });

      final commId = res['id'] as int;
      // Add default block and apartments
      final blockRes = await _api.post('/communities/$commId/blocks', body: {'name': 'A Blok'});
      final blockId = blockRes['id'] as int;

      for (int i = 1; i <= 10; i++) {
        await _api.post('/communities/$commId/blocks/$blockId/apartments', body: {
          'apartment_no': '$i',
          'floor': (i / 2).ceil(),
          'type': '3+1'
        });
      }

      await loadMyCommunities();
      await switchCommunity(commId);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Bina/site oluşturulamadı.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBlocksAndApartments(int communityId) async {
    try {
      final res = await _api.get('/communities/$communityId/blocks');
      return (res as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<String?> fetchInviteCode() async {
    if (_activeMembership == null) return null;
    try {
      final res = await _api.get('/communities/${_activeMembership!.community.id}/invite-code');
      return res['code'] as String?;
    } catch (_) {
      return null;
    }
  }
}
