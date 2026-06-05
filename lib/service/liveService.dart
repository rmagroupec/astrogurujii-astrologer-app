import 'dart:convert';
import 'dart:io';
import 'package:astrologer_app/model/OfferListModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';
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

Future<http.Response> GoLive(Map<String, dynamic> data) async {
  final response = await _apiClient.post(
    "astrologer_api/go_live",
    data,
    isAuthRequired: true,
  );
  print(response.body);
  print("GoLive response: ${response.body}");
  return response;
}
Future<Map<String, dynamic>> LiveStart(String liveId) async {
    final response = await _apiClient.post(
      "astrologer_api/live_start",
      {"live_id": liveId},
      isAuthRequired: true,
    );
    return jsonDecode(response.body);
  }

Future<Map<String, dynamic>> LiveEnd(String liveId) async {
  try {
    final response = await _apiClient.post(
      "astrologer_api/live_end",
      {"live_id": liveId},
      isAuthRequired: true,
    );
    print("LiveEnd response: ${response.body}");
    return jsonDecode(response.body);
  } catch (e) {
    print("❌ LiveEnd error: $e");
    return {"status": false, "message": e.toString()};
  }
}
Future<OfferListResponse> GetOfferList() async {
  final response = await _apiClient.get(
    "astrologer_api/offer_list",
    isAuthRequired: true,
  );
  print("OfferList: ${response.body}");
  return OfferListResponse.fromJson(jsonDecode(response.body));
}
Future<bool> addGallery(List<File> files) async {
  try {
    final response = await _apiClient.uploadFiles(
      "astrologer_api/add_galary",
      files,
      isAuthRequired: true,
    );
    final body = jsonDecode(response.body);
    print("addGallery: $body");
    return body['status'] == true;
  } catch (e) {
    debugPrint("❌ addGallery error: $e");
    return false;
  }
}
}