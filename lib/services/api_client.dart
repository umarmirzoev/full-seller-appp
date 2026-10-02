import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Тонкая обёртка над http для запросов к FullSeller.WebApi:
/// JSON-кодирование, Bearer-токен, одна попытка refresh при 401.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  bool _refreshing = false;

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) cleanQuery[key] = value.toString();
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery);
  }

  Future<http.Response> _send(String method, String path, {Map<String, dynamic>? query, Object? body, required bool auth}) async {
    final uri = _uri(path, query);
    final headers = await _headers(auth: auth);
    final encodedBody = body == null ? null : jsonEncode(body);
    return await switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: encodedBody),
      'PUT' => http.put(uri, headers: headers, body: encodedBody),
      'DELETE' => http.delete(uri, headers: headers),
      _ => throw ApiException('Неизвестный HTTP-метод: $method'),
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _request('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _request('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _request('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) =>
      _request('DELETE', path, auth: auth);

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? query, Object? body, required bool auth}) async {
    http.Response res;
    try {
      res = await _send(method, path, query: query, body: body, auth: auth);
    } catch (_) {
      throw const ApiException('Не удалось подключиться к серверу. Проверьте, что backend запущен и доступен.');
    }

    if (res.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          res = await _send(method, path, query: query, body: body, auth: true);
        } catch (_) {
          throw const ApiException('Не удалось подключиться к серверу. Проверьте, что backend запущен и доступен.');
        }
      } else {
        await TokenStorage.clear();
      }
    }

    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        return null;
      }
    }

    var message = 'Ошибка сервера (${res.statusCode})';
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map) {
        if (decoded['message'] is String) message = decoded['message'] as String;
        else if (decoded['title'] is String) message = decoded['title'] as String;
      }
    } catch (_) {
      // тело ответа не JSON — оставляем сообщение по умолчанию
    }
    throw ApiException(message, statusCode: res.statusCode);
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final res = await http.post(
        _uri('/auth/refresh'),
        headers: await _headers(auth: false),
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        expiresAt: DateTime.parse(data['accessTokenExpiresAt'] as String),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
