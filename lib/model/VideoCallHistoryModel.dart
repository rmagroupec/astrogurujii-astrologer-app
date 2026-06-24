// lib/model/VideoCallHistoryModel.dart

class VideoCallHistoryResponse {
  final bool   result;
  final String message;
  final List<VideoCallHistory> data2;

  VideoCallHistoryResponse({required this.result, required this.message, required this.data2});

  factory VideoCallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return VideoCallHistoryResponse(
      result : json['result']  ?? false,
      message: json['message'] ?? '',
      data2  : json['data2'] != null
          ? List<VideoCallHistory>.from(json['data2'].map((x) => VideoCallHistory.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'result' : result,
    'message': message,
    'data2'  : data2.map((x) => x.toJson()).toList(),
  };
}

class VideoCallHistory {
  final String? id;
  final String? channelId;
  final String? astroId;
  final String? userId;
  final String? startTime;
  final String? endTime;
  final String? groupId;
  final String? callDuration;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final String? callType;
  final String? remedy;
  final String? knowlarityCallId;
  final String? userName;
  final String? orderTime;
  final String? userImage;
  final String? ratings;
  final String? callRate;
  final String? totalAmount;
  final String? callMin;

  // ✅ New fields
  final String? callDurationDisplay; // "(02:17 PM-02:22 PM)"
  final String? userDob;             // "03-November-2000"
  final String? userPob;             // "New Delhi, India, Delhi"
  final String? userCountry;         // "indian" / "foreign"
  final bool?   isRepeat;            // true = Repeat, false = New
  final String? offer;               // "Loyal User Offer (10.0%)"
  final String? note;                // ✅ astrologer's private note

  VideoCallHistory({
    this.id,
    this.channelId,
    this.astroId,
    this.userId,
    this.startTime,
    this.endTime,
    this.groupId,
    this.callDuration,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.callType,
    this.remedy,
    this.knowlarityCallId,
    this.userName,
    this.orderTime,
    this.userImage,
    this.ratings,
    this.callRate,
    this.totalAmount,
    this.callMin,
    this.callDurationDisplay,
    this.userDob,
    this.userPob,
    this.userCountry,
    this.isRepeat,
    this.offer,
    this.note,
  });

  factory VideoCallHistory.fromJson(Map<String, dynamic> json) {
    return VideoCallHistory(
      id:                   json['id']?.toString()                ?? '',
      channelId:            json['channel_id']?.toString()        ?? '',
      astroId:              json['astro_id']?.toString()          ?? '',
      userId:               json['user_id']?.toString()           ?? '',
      startTime:            json['start_time']?.toString()        ?? '',
      endTime:              json['end_time']?.toString()          ?? '',
      groupId:              json['group_id']?.toString()          ?? '',
      callDuration:         json['call_duracation']?.toString()   ?? '0',
      status:               json['status']?.toString()            ?? '',
      createdAt:            json['created_at']?.toString()        ?? '',
      updatedAt:            json['updated_at']?.toString()        ?? '',
      callType:             json['call_type']?.toString()         ?? '',
      remedy:               json['remedy']?.toString()            ?? '',
      knowlarityCallId:     json['knowlarity_call_id']?.toString() ?? '',
      userName:             json['user_name']?.toString()         ?? '',
      orderTime:            json['OrderTime']?.toString()         ?? '',
      userImage:            json['user_image']?.toString()        ?? '',
      ratings:              json['ratings']?.toString()           ?? '0',
      callRate:             json['call_rate']?.toString()         ?? '0',
      totalAmount:          json['total_amount']?.toString()      ?? '',
      callMin:              json['call_min']?.toString()          ?? '0',
      callDurationDisplay:  json['call_duration_display']?.toString() ?? '',
      userDob:              json['user_dob']?.toString()          ?? '',
      userPob:              json['user_pob']?.toString()          ?? '',
      userCountry:          json['user_country']?.toString()      ?? '',
      isRepeat:             json['is_repeat'] as bool?            ?? false,
      offer:                json['offer']?.toString()             ?? '',
      note:                 json['note']?.toString()              ?? '',  // ✅
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                   id,
    'channel_id':           channelId,
    'astro_id':             astroId,
    'user_id':              userId,
    'start_time':           startTime,
    'end_time':             endTime,
    'group_id':             groupId,
    'call_duracation':      callDuration,
    'status':               status,
    'created_at':           createdAt,
    'updated_at':           updatedAt,
    'call_type':            callType,
    'remedy':               remedy,
    'knowlarity_call_id':   knowlarityCallId,
    'user_name':            userName,
    'OrderTime':            orderTime,
    'user_image':           userImage,
    'ratings':              ratings,
    'call_rate':            callRate,
    'total_amount':         totalAmount,
    'call_min':             callMin,
    'call_duration_display': callDurationDisplay,
    'user_dob':             userDob,
    'user_pob':             userPob,
    'user_country':         userCountry,
    'is_repeat':            isRepeat,
    'offer':                offer,
    'note':                 note,   // ✅
  };
}