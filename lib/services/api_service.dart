import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Centralized HTTP client that auto-attaches JWT Bearer token.
class ApiService {
  static const String _tokenKey = 'jwt_token';

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
    final headers = await _headers(auth: auth);
    return http.get(url, headers: headers);
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _headers(auth: auth);
    return http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _headers(auth: auth);
    return http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _headers(auth: auth);
    return http.patch(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
