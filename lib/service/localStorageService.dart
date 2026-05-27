import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveLoginData(Map<String, dynamic> jsonResponse) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Store the sensitive JWT Token in Secure Storage
    await _secureStorage.write(
      key: 'auth_token',
      value: jsonResponse['JWTtoken'],
    );

    // 2. Store user profile details in SharedPreferences
    final results = jsonResponse['results'];
    await prefs.setString('astro_id', results['astrologerID']);
    await prefs.setString('astro_name', results['name']);
    await prefs.setString('astro_email', results['email']);
    await prefs.setString('astro_image', results['profile_img']);

    // Store online status as booleans
    await prefs.setBool('is_chat_online', results['is_chat_online'] == 'on');

    print("Data saved successfully!");
  }

  Future<bool> isLoggedIn() async {
    await Future.delayed(const Duration(seconds: 2));
    // Read the token we saved earlier
    String? token = await _secureStorage.read(key: 'auth_token');

    // Return true if token is not null and not empty
    return token != null && token.isNotEmpty;
  }
}
