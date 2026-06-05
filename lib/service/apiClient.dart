import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = "https://admin.astrogurujii.com/";
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders({bool isAuthRequired = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (isAuthRequired) {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String endpoint,
      {bool isAuthRequired = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders(isAuthRequired: isAuthRequired);
    return _handleResponse(await http.get(url, headers: headers));
  }

  Future<http.Response> post(String endpoint, dynamic body,
      {bool isAuthRequired = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders(isAuthRequired: isAuthRequired);
    return _handleResponse(
        await http.post(url, headers: headers, body: jsonEncode(body)));
  }

  // ✅ Multipart upload — sends files[] as the backend expects
  Future<http.Response> uploadFiles(
    String endpoint,
    List<File> files, {
    bool isAuthRequired = true,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final token = isAuthRequired
        ? await _storage.read(key: 'auth_token')
        : null;

    final request = http.MultipartRequest('POST', url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    for (final file in files) {
      final ext      = file.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'files[]',       // ✅ field name the backend expects
          file.path,
          // ignore: avoid_slow_async_io
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    print('uploadFiles response: ${response.body}');
    return _handleResponse(response);
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _storage.delete(key: 'auth_token');
      throw Exception("Unauthorized: Token expired");
    }
    return response;
  }
}