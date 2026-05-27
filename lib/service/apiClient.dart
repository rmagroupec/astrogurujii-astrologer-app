import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = "https://admin.astrogurujii.com/";
  final _storage = const FlutterSecureStorage();

  // Helper to get headers (With or Without Auth)
  Future<Map<String, String>> _getHeaders({bool isAuthRequired = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (isAuthRequired) {
      String? token = await _storage.read(key: 'auth_token');
      print(token);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Professional GET wrapper
  Future<http.Response> get(String endpoint, {bool isAuthRequired = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders(isAuthRequired: isAuthRequired);
    
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // Professional POST wrapper
  Future<http.Response> post(String endpoint, dynamic body, {bool isAuthRequired = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders(isAuthRequired: isAuthRequired);
    
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    print(response.body);
    return _handleResponse(response);
  }

  // Centralized Error/Response Handling (The "onError" Interceptor)
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Global Logic: Clear token and navigate to Login
      _storage.delete(key: 'auth_token');
      throw Exception("Unauthorized: Token expired");
    }
    return response;
  }
}