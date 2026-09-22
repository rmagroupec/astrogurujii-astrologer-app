import 'dart:convert';

import 'package:astrologer_app/features/modal/PujaBookingModel.dart';
import 'package:astrologer_app/features/modal/PujaLiveModel.dart';
import 'package:astrologer_app/features/service/model/NotificationModel.dart';
import 'package:astrologer_app/model/AstrolgerTransactionsModel.dart';
import 'package:astrologer_app/model/AstrologerGalleryModel.dart';
import 'package:astrologer_app/model/AstrologerGiftModel.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/model/AstrologerWalletModel.dart';
import 'package:astrologer_app/model/BankAccountRequestModel.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/model/AstrologerWalletModel.dart'  as model;
import 'package:astrologer_app/model/PriceIncreaseRequestModel.dart';
import 'package:astrologer_app/model/VideoCallHistoryModel.dart';
import 'package:astrologer_app/model/WaitingListResponseModel.dart';
import 'package:astrologer_app/model/WeeklyRankingModel.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/model/ratingListModel.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:http/http.dart' as http;
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/foundation.dart';
import 'package:astrologer_app/model/last_call_list_model.dart';
import 'package:astrologer_app/model/LocationModel.dart';

class ApiService {
  final ApiClient _client = ApiClient();

  // Authenticated Call
  Future<bool> deductAmount(String channelId) async {
    final response = await _client.post("deduct-balance", {
      "channel_id": channelId,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['result'] == true;
    }
    return false;
  }

  // Unauthenticated Call (Example: Login)
  // Change Future<void> to Future<http.Response>
  Future<http.Response> login(String email, String pass) async {
    final token =
        NotificationService().fcmToken ??
        await NotificationService().getStoredToken();

    print(token);
    return await _client.post("astrologer_api/astrologer_login", {
      "email": email,
      "password": pass,
      "deviceToken": token,
      "deviceID": "testID",
      "deviceType": "android",
    }, isAuthRequired: false);
  }


  // ── PUJA LIVE ─────────────────────────────────────────────────────────────
  // NOTE: this used to POST to "astrologer_api/astrologer_wallet" and parse
  // the reply as AstrologerWalletResponse — i.e. it called the WALLET
  // endpoint. That returns 200 with wallet data, so the UI happily showed
  // "Pooja started successfully" while the server never set is_live and
  // never issued an Agora token. That was the main reason puja live did
  // nothing at all. It now calls the real endpoint.
  //
  // [pujaId] must be the booking's Mongo _id (PoojaBooking.id) — the server
  // also accepts puja_booking_id, but _id is the canonical one.
  Future<PujaLiveResponse> PoojaStartLive(String pujaId) async {
    final response = await _client.post(
      "astrologer_api/puja_live_start",
      {"puja_id": pujaId},
      isAuthRequired: true,
    );
    if (kDebugMode) print('puja_live_start → ${response.body}');
    return PujaLiveResponse.fromJson(jsonDecode(response.body));
  }

  Future<PujaLiveResponse> PoojaEndLive(String pujaId) async {
    final response = await _client.post(
      "astrologer_api/puja_live_end",
      {"puja_id": pujaId},
      isAuthRequired: true,
    );
    if (kDebugMode) print('puja_live_end → ${response.body}');
    return PujaLiveResponse.fromJson(jsonDecode(response.body));
  }

  /// Agora tokens expire (1 h). Called from onTokenPrivilegeWillExpire so a
  /// long puja doesn't drop off air mid-stream.
  Future<PujaLiveResponse> PoojaLiveToken(String pujaId) async {
    final response = await _client.post(
      "astrologer_api/puja_live_token",
      {"puja_id": pujaId},
      isAuthRequired: true,
    );
    if (kDebugMode) print('puja_live_token → ${response.body}');
    return PujaLiveResponse.fromJson(jsonDecode(response.body));
  }
  Future<PoojaBookingResponse> getPujaBooking() async {
    final response = await _client.get(
      "astrologer_api/puja_bookings",

      isAuthRequired: true,
    );
    print(response.body);
    return PoojaBookingResponse.fromJson(jsonDecode(response.body));
  }

    Future<NotificationResponse> AstrologerNotificatinList() async {
 
 
    final response = await _client.post(
      "astrologer_api/astrologer_notifications",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return NotificationResponse.fromJson(jsonDecode(response.body));
  }
  // Fetch states (countries_id = "1" for India, states_id = "0" means top level)
// Countries list (countries_id=0, states_id=0)
Future<LocationResponse> getCountryList() async {
  final response = await _client.post(
    'astrologer_api/location_list',
    {'countries_id': '0', 'states_id': '0'},
    isAuthRequired: false,
  );
  return LocationResponse.fromJson(jsonDecode(response.body));
}

// States of a country (states_id=0)
Future<LocationResponse> getStateList(String countriesId) async {
  final response = await _client.post(
    'astrologer_api/location_list',
    {'countries_id': countriesId, 'states_id': '0'},
    isAuthRequired: false,
  );
  return LocationResponse.fromJson(jsonDecode(response.body));
}

// Cities of a state
Future<LocationResponse> getCityList(String countriesId, String statesId) async {
  final response = await _client.post(
    'astrologer_api/location_list',
    {'countries_id': countriesId, 'states_id': statesId},
    isAuthRequired: false,
  );
  return LocationResponse.fromJson(jsonDecode(response.body));
}

  Future<AstrologerProfileResponse> get_astrologer_profile() async {
    final response = await _client.post(
      "astrologer_api/get_profile_astrologer",
      {},
      isAuthRequired: true,
    );
    print(response.body);
    return AstrologerProfileResponse.fromJson(jsonDecode(response.body));
  }

   Future<bool> updateAvailableStatus({
    bool? isChat,
    bool? isVoiceCall,
    bool? isVideoCall,
  }) async {
    final body = <String, dynamic>{};
    String v(bool b) => b ? 'on' : 'off';
 
    // ✅ CORRECT field names — these control the live online badge
    if (isChat      != null) body['is_chat_online']  = v(isChat);
    if (isVoiceCall != null) body['is_voice_online'] = v(isVoiceCall);
    if (isVideoCall != null) body['is_video_online'] = v(isVideoCall);
 
    final response = await _client.post(
      'astrologer_api/profile_status_update',
      body,
      isAuthRequired: true,
    );
    print('updateAvailableStatus → ${response.body}');   // plain print, no import needed
    final data = jsonDecode(response.body);
    return data['status'] == true;
  }

  Future<AstrologerGalleryResponse> getGalleryList() async {
    final response = await _client.get(
      "astrologer_api/galary_list",

      isAuthRequired: true,
    );
    print(response.body);
    return AstrologerGalleryResponse.fromJson(jsonDecode(response.body));
  }

  Future<void> addGallery() async {
    final response = await _client.post(
      "astrologer_api/add_galary",
      {},
      isAuthRequired: true,
    );
    print(response.body);
    // return AstrologerProfileResponse.fromJson(jsonDecode(response.body));
  }



  Future<TransactionListResponse> getAstrologerTransactions() async {
    final response = await _client.post(
      "astrologer_api/astrologer_transactions",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return TransactionListResponse.fromJson(jsonDecode(response.body));
  }

 // lib/service/apiService.dart

/// ── Fetch Reviews with Optional Filtering ──────────────────────────────
Future<RatingListResponse> getReviewList({String filter = 'all'}) async {
  try {
    // Passing the map directly as the second argument block
    final response = await _client.post(
      "astrologer_api/review_list",
      {
        "filter": filter,
      },
      isAuthRequired: true,
    );

    debugPrint("Review List Response: ${response.body}");
    return RatingListResponse.fromJson(jsonDecode(response.body));
  } catch (e) {
    debugPrint("Get review list network exception: $e");
    rethrow;
  }
}
  Future<ChatCallResponse> PriceIncreaseRequestList() async {
    final response = await _client.post(
      "astrologer_api/chat_call_request_list",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return ChatCallResponse.fromJson(jsonDecode(response.body));
  }

  Future<RatingListResponse> ChangePriceIncreaseRequest(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      "astrologer_api/chat_call_request_list",
      data,

      isAuthRequired: true,
    );
    print(response.body);
    return RatingListResponse.fromJson(jsonDecode(response.body));
  }

  Future<BankAccResponse> AstroBankAccountList() async {
    
    final response = await _client.post(
      "astrologer_api/bank_acc_request_list",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return BankAccResponse.fromJson(jsonDecode(response.body));
  }

  Future<UserChatListResponse> WaitingUserList() async {
    final response = await _client.post(
      "astrologer_api/waiting_user_list",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return UserChatListResponse.fromJson(jsonDecode(response.body));
  }

  Future<AstrologerLiveListResponse> LiveEventsList() async {
    final response = await _client.post(
      "astrologer_api/astroLoger_live_list",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return AstrologerLiveListResponse.fromJson(jsonDecode(response.body));
  }
   Future<VideoCallHistoryResponse> VideoCallHistoryList(String chat_type) async {
   dynamic data = {"call_type":chat_type};
     print(data);
    final response = await _client.post(
      "astrologer_api/video_call_history",
      data,

      isAuthRequired: true,
    );
    print(response.body);
    return VideoCallHistoryResponse.fromJson(jsonDecode(response.body));
  }
 
  Future<AstrologerWalletResponse> GetAstrologerWallet() async {
    final response = await _client.post(
      "astrologer_api/astrologer_wallet",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return AstrologerWalletResponse.fromJson(jsonDecode(response.body));
  }
  Future<WeeklyRankingResponse> GetAstrologerWeeklyEarning() async {
    final response = await _client.post(
      "astrologer_api/weekly_astromall_ranking",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return WeeklyRankingResponse.fromJson(jsonDecode(response.body));
  }
   Future<http.Response> UpdatePhoneNumberFunc(dynamic data) async {
    final response = await _client.post(
      "astrologer_api/astrologer_update_number",
      data,

      isAuthRequired: true,
    );
    print(response.body);
    return response;
  }

Future<String> TermsAndCondition(dynamic data) async {
    final response = await _client.get(
      "links/termandcondition",
     

      isAuthRequired: true,
    );
    print(response.body);
    return response.body;
  }
  
  Future<AstrologerGiftResponse> AstrologerGiftList() async {
    final response = await _client.post(
      "astrologer_api/astrolger_gifts",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return AstrologerGiftResponse.fromJson(jsonDecode(response.body));
  }

Future<LastCallListModel?> lastCallList() async {
  try {
    final response = await _client.post(
      'astrologer_api/last_call_list',
      {},
      isAuthRequired: true,
    );
    return LastCallListModel.fromJson(jsonDecode(response.body));
  } catch (e) {
    debugPrint('lastCallList error: $e');
    return null;
  }
}
// Change the return type from List<WalletTransaction> to model.TransactionListResponse1
Future<TransactionListResponse1> GetAstrologerWalletTransaction({
  String? type,
  String? fromDate,
  String? toDate,
}) async {
  final body = <String, dynamic>{};
  if (type != null && type.isNotEmpty && type != 'all') body['type'] = type;
  if (fromDate != null && fromDate.isNotEmpty) body['from_date'] = fromDate;
  if (toDate   != null && toDate.isNotEmpty)   body['to_date']   = toDate;

  final resp = await ApiClient().post(
    'astrologer_api/astrologer_wallet_transaction',
    body,
    isAuthRequired: true,
  );
  final json = jsonDecode(resp.body);
  return TransactionListResponse1.fromJson(json);
}
Future<bool> updateReviewAction({
  required String reviewId,
  required String action, // Acceptable parameters: 'pin' | 'unpin' | 'flag'
}) async {
  try {
    final response = await _client.post(
      "astrologer_api/review_action",
      {
        "review_id": reviewId,
        "actionType": action,
      },
      isAuthRequired: true,
    );

    debugPrint("Review Action Response: ${response.body}");
    
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    return responseData['status'] ?? false;
  } catch (e) {
    debugPrint("Review interaction exception: $e");
    return false;
  }
}

 Future<bool?> toggle(String userId) async {
    try {
   
      final resp = await _client.post(
      'astrologer_api/community_toggle_favourite',
       {'user_id': userId}
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['result'] == true) {
        return data['is_favourite'] as bool?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
