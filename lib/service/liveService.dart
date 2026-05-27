import 'dart:convert';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:http/http.dart' as http;

class Liveservice {
  final ApiClient _apiClient = ApiClient();
Future<void> getLiveList() async {
  // Add 'return' before the client call
  final response = await _apiClient.get(
    "astrologer_api/galary_list", 
    
    isAuthRequired: true
  );
  print(response.body);
  // return AstrologerProfileResponse.fromJson(jsonDecode(response.body));
}

}