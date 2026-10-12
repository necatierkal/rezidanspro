import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class DuesProvider extends ChangeNotifier {
  final ApiService _api;

  // Strict separation of Resident vs Manager state
  List<DueModel> _myDues = [];
  List<DueModel> _managerDues = [];
  bool _isLoading = false;
  String? _errorMessage;

  DuesProvider(this._api);

  List<DueModel> get myDues => _myDues;
  List<DueModel> get managerDues => _managerDues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get myTotalUnpaidAmount {
    return _myDues
        .where((d) => d.status != 'PAID')
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  bool get hasMyUnpaidDues => _myDues.any((d) => d.status != 'PAID');

  Future<void> loadMyDues(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/dues/my', queryParameters: {'community_id': communityId});
      _myDues = (res as List<dynamic>)
          .map((d) => DueModel.fromJson(d as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Aidat bilgileri yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadManagerDues(int communityId, {String? statusFilter, String? periodFilter}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{'community_id': communityId};
      if (statusFilter != null && statusFilter.isNotEmpty) {
        params['status_filter'] = statusFilter;
      }
      if (periodFilter != null && periodFilter.isNotEmpty) {
        params['period_filter'] = periodFilter;
      }

      final res = await _api.get('/dues/manager', queryParameters: params);
      _managerDues = (res as List<dynamic>)
          .map((d) => DueModel.fromJson(d as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Yönetici aidat listesi yüklenemedi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDue({
    required int communityId,
    required int apartmentId,
    required String period,
    required double amount,
    required DateTime dueDate,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/dues', body: {
        'community_id': communityId,
        'apartment_id': apartmentId,
        'period': period.trim(),
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        'notes': notes?.trim(),
      });

      await loadManagerDues(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Aidat tanımlanamadı.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment({
    required int dueId,
    required double amount,
    required String paymentMethod,
    String? reference,
    required int communityId,
  }) async {
    try {
      await _api.post('/dues/$dueId/payments', body: {
        'amount': amount,
        'payment_method': paymentMethod.toUpperCase(),
        'reference': reference?.trim(),
      });

      await loadManagerDues(communityId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
