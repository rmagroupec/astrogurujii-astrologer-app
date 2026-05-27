import 'dart:convert';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:http/http.dart' as http;

class CallStatusService {
  final ApiClient _apiClient = ApiClient();

  /// Update call status (accept / reject / end)
  Future<bool> updateCallStatus({
    required String channelId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.post(
        'astrologer_api/call_status_update',
        {
          'channel_id': channelId,
          'status': status,
        },
        isAuthRequired: true,
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        print('✅ Call status updated: $status');
        return true;
      } else {
        print('❌ Call status update failed: ${decoded['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating call status: $e');
      return false;
    }
  }

  
}
