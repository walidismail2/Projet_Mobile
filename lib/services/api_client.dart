import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    try {
      final res = await _client
          .get(_uri(path, query), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Serveur injoignable. Vérifie que le backend tourne ($baseUrl).');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(
            _uri(path),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Serveur injoignable. Vérifie que le backend tourne ($baseUrl).');
    }
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final msg = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Erreur HTTP ${res.statusCode}';
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
