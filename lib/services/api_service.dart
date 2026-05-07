import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Centralized HTTP client that auto-attaches JWT Bearer token.
class ApiService {
  static const String _tokenKey = 'jwt_token';
  static const String _phoneKey = 'user_phone';

  // ─── Token Management ───

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Phone (primary key — used to identify the rider in websocket events) ───

  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  // ─── Headers ───

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ─── HTTP Methods ───

  static Future<http.Response> get(String path, {bool auth = true}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    var response = await http.get(url, headers: await _headers(auth: auth));
    if (response.statusCode == 401 && auth) {
      if (await refreshAccessToken()) {
        response = await http.get(url, headers: await _headers(auth: auth));
      }
    }
    return response;
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final encodedBody = body != null ? jsonEncode(body) : null;
    var response = await http.post(url,
        headers: await _headers(auth: auth), body: encodedBody);
    if (response.statusCode == 401 && auth) {
      if (await refreshAccessToken()) {
        response = await http.post(url,
            headers: await _headers(auth: auth), body: encodedBody);
      }
    }
    return response;
  }

  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final encodedBody = body != null ? jsonEncode(body) : null;
    var response = await http.put(url,
        headers: await _headers(auth: auth), body: encodedBody);
    if (response.statusCode == 401 && auth) {
      if (await refreshAccessToken()) {
        response = await http.put(url,
            headers: await _headers(auth: auth), body: encodedBody);
      }
    }
    return response;
  }

  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final encodedBody = body != null ? jsonEncode(body) : null;
    var response = await http.patch(url,
        headers: await _headers(auth: auth), body: encodedBody);
    if (response.statusCode == 401 && auth) {
      if (await refreshAccessToken()) {
        response = await http.patch(url,
            headers: await _headers(auth: auth), body: encodedBody);
      }
    }
    return response;
  }

  // ─── Refresh Token ───

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> clearRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refresh_token');
  }

  /// Silently exchange the refresh token for a new access token.
  static Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.refreshToken}?refreshToken=$refreshToken');
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        if (data['refreshToken'] != null) {
          await saveRefreshToken(data['refreshToken']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// GET an external URL (e.g. Mapbox) without auth.
  static Future<http.Response> getExternal(Uri url) => http.get(url);
}
