class VideoCallHistoryResponse {
  final bool result;
  final String message;
  final List<VideoCallHistory> data2;

  VideoCallHistoryResponse({
    required this.result,
     required this.message,
     required this.data2,
  });

  factory VideoCallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return VideoCallHistoryResponse(
      result: json['result'] ?? false,
      message: json['message'] ?? '',
      data2: json['data2'] != null
          ? List<VideoCallHistory>.from(
              json['data2'].map((x) => VideoCallHistory.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'message': message,
      'data2': data2.map((x) => x.toJson()).toList(),
    };
  }
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
  });

  factory VideoCallHistory.fromJson(Map<String, dynamic> json) {
    return VideoCallHistory(
      id: json['id'] ?? '',
      channelId: json['channel_id'] ?? '',
      astroId: json['astro_id'] ?? '',
      userId: json['user_id'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      groupId: json['group_id'] ?? '',
      callDuration: json['call_duracation'] ?? '0',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      callType: json['call_type'] ?? '',
      remedy: json['remedy'] ?? '',
      knowlarityCallId: json['knowlarity_call_id'] ?? '',
      userName: json['user_name'] ?? '',
      orderTime: json['OrderTime'] ?? '',
      userImage: json['user_image'] ?? '',
      ratings: json['ratings'].toString() ?? '0',
      callRate: json['call_rate'] ?? '0',
      totalAmount: json['total_amount'] ?? '',
      callMin: json['call_min'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'astro_id': astroId,
      'user_id': userId,
      'start_time': startTime,
      'end_time': endTime,
      'group_id': groupId,
      'call_duracation': callDuration,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'call_type': callType,
      'remedy': remedy,
      'knowlarity_call_id': knowlarityCallId,
      'user_name': userName,
      'OrderTime': orderTime,
      'user_image': userImage,
      'ratings': ratings,
      'call_rate': callRate,
      'total_amount': totalAmount,
      'call_min': callMin,
    };
  }
}
