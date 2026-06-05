import 'dart:convert';

import 'package:astrologer_app/features/modal/PujaBookingModel.dart';
import 'package:astrologer_app/features/service/model/NotificationModel.dart';
import 'package:astrologer_app/model/AstrolgerTransactionsModel.dart';
import 'package:astrologer_app/model/AstrologerGalleryModel.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/model/AstrologerWalletModel.dart';
import 'package:astrologer_app/model/BankAccountRequestModel.dart';
import 'package:astrologer_app/model/PriceIncreaseRequestModel.dart';
import 'package:astrologer_app/model/VideoCallHistoryModel.dart';
import 'package:astrologer_app/model/WaitingListResponseModel.dart';
import 'package:astrologer_app/model/WeeklyRankingModel.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/model/ratingListModel.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:http/http.dart' as http;
import 'package:astrologer_app/service/apiClient.dart';

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


  Future<AstrologerWalletResponse> PoojaStartLive(String  pujaID) async {
    final response = await _client.post(
      "astrologer_api/astrologer_wallet",
      {"puja_id":pujaID},

      isAuthRequired: true,
    );
    print(response.body);
    return AstrologerWalletResponse.fromJson(jsonDecode(response.body));
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

    String toApiValue(bool value) => value ? 'on' : 'off';

    if (isChat != null) {
      body['is_chat'] = toApiValue(isChat);
    }
    if (isVoiceCall != null) {
      body['is_voice_call'] = toApiValue(isVoiceCall);
    }
    if (isVideoCall != null) {
      body['is_video_call'] = toApiValue(isVideoCall);
    }

    final response = await _client.post(
      "astrologer_api/profile_status_update",
      body,
      isAuthRequired: true,
    );
    print(response.body);
    final data = jsonDecode(response.body);
    print(data);
    return data['status'];
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

  Future<RatingListResponse> getReviewList() async {
    final response = await _client.post(
      "astrologer_api/review_list",
      {},

      isAuthRequired: true,
    );
    print(response.body);
    return RatingListResponse.fromJson(jsonDecode(response.body));
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
  
}
