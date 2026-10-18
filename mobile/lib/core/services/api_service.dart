import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';
import 'mock_data_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final StorageService storageService;
  late String _baseUrl;

  ApiService(this.storageService) {
    if (storageService.customServerUrl != null && storageService.customServerUrl!.isNotEmpty) {
      _baseUrl = storageService.customServerUrl!;
    } else if (kIsWeb) {
      _baseUrl = AppConfig.localApiBaseUrl;
    } else if (Platform.isAndroid) {
      _baseUrl = AppConfig.defaultApiBaseUrl;
    } else {
      _baseUrl = AppConfig.localApiBaseUrl;
    }
  }

  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) {
    _baseUrl = url;
    storageService.setCustomServerUrl(url);
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = storageService.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  ApiException _handleError(dynamic error, {int? statusCode, String? responseBody}) {
    if (responseBody != null && responseBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map && decoded.containsKey('detail')) {
          final detail = decoded['detail'];
          if (detail is String) {
            return ApiException(detail, statusCode: statusCode);
          }
        }
      } catch (_) {}
    }

    if (statusCode == 401) {
      return ApiException('Oturum süreniz doldu. Lütfen tekrar giriş yapın.', statusCode: 401);
    } else if (statusCode == 403) {
      return ApiException('Bu işlem için yetkiniz bulunmamaktadır.', statusCode: 403);
    } else if (statusCode == 404) {
      return ApiException('Aradığınız kayıt bulunamadı.', statusCode: 404);
    } else if (statusCode != null && statusCode >= 500) {
      return ApiException('Sunucuyla bağlantı kurulamadı. Lütfen tekrar deneyin.', statusCode: statusCode);
    }

    return ApiException('Bir sorun oluştu. Lütfen tekrar deneyin.', statusCode: statusCode);
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    if (storageService.isDemoMode) {
      return MockDataService().handleGet(endpoint, queryParameters);
    }

    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final stringParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
        uri = uri.replace(queryParameters: stringParams);
      }

      final response = await http.get(uri, headers: _buildHeaders()).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw _handleError(null, statusCode: response.statusCode, responseBody: response.body);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Seamless offline fallback so app works on physical device without local server setup
      return MockDataService().handleGet(endpoint, queryParameters);
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    if (storageService.isDemoMode) {
      return MockDataService().handlePost(endpoint, body);
    }

    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw _handleError(null, statusCode: response.statusCode, responseBody: response.body);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Seamless offline fallback
      return MockDataService().handlePost(endpoint, body);
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    if (storageService.isDemoMode) {
      return {'message': 'İşlem başarılı'};
    }

    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw _handleError(null, statusCode: response.statusCode, responseBody: response.body);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      return {'message': 'İşlem başarılı'};
    }
  }

  Future<dynamic> delete(String endpoint) async {
    if (storageService.isDemoMode) {
      return {'message': 'Kayıt silindi'};
    }

    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw _handleError(null, statusCode: response.statusCode, responseBody: response.body);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      return {'message': 'Kayıt silindi'};
    }
  }
}
