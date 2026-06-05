import 'dart:convert';

AstrologerLiveListResponse astrologerLiveListResponseFromJson(String str) =>
    AstrologerLiveListResponse.fromJson(json.decode(str));

String astrologerLiveListResponseToJson(AstrologerLiveListResponse data) =>
    json.encode(data.toJson());

class AstrologerLiveListResponse {
  bool? status;
  String? message;
  List<LiveEventData>? data;

  AstrologerLiveListResponse({this.status, this.message, this.data});

  factory AstrologerLiveListResponse.fromJson(Map<String, dynamic> json) =>
      AstrologerLiveListResponse(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<LiveEventData>.from(
                json["data"].map((x) => LiveEventData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class LiveEventData {
  String? id;
  List<dynamic>? users;
  String? isLive;
  String? startTime;
  String? endTime;
  String? channelId;
  String? password;
  String? isDelete;
  String? createdDate;
  String? updatedAt;
  String? title;
  AstrologerInfo? astrologer;
  String? liveDate;
  String? status;
  String? recurringDay;
  int? v;

  LiveEventData({
    this.id,
    this.users,
    this.isLive,
    this.startTime,
    this.endTime,
    this.channelId,
    this.password,
    this.isDelete,
    this.createdDate,
    this.updatedAt,
    this.title,
    this.astrologer,
    this.liveDate,
    this.status,
    this.recurringDay,
    this.v,
  });

  factory LiveEventData.fromJson(Map<String, dynamic> json) => LiveEventData(
        id: json["_id"],
        users: json["users"] ?? [],
        isLive: json["is_live"]?.toString(),
        startTime: json["start_time"],
        endTime: json["end_time"],
        channelId: json["channel_id"],
        password: json["password"],
        isDelete: json["is_delete"],
        createdDate: json["Created_date"],
        updatedAt: json["updated_at"],
        title: json["title"],
        // ✅ guard: populate returns an object, but if it fails it's a plain String ID
        astrologer: (json["astrologer_id"] is Map<String, dynamic>)
            ? AstrologerInfo.fromJson(
                json["astrologer_id"] as Map<String, dynamic>)
            : null,
        liveDate: json["live_date"],
        status: json["status"],
        recurringDay: json["recurringDay"],
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "users": users,
        "is_live": isLive,
        "start_time": startTime,
        "end_time": endTime,
        "channel_id": channelId,
        "password": password,
        "is_delete": isDelete,
        "Created_date": createdDate,
        "updated_at": updatedAt,
        "title": title,
        "astrologer_id": astrologer?.toJson(),
        "live_date": liveDate,
        "status": status,
        "recurringDay": recurringDay,
        "__v": v,
      };
}

class AstrologerInfo {
  String? id;
  String? profileImg;
  String? name;
  String? number;
  String? email;

  AstrologerInfo({this.id, this.profileImg, this.name, this.number, this.email});

  factory AstrologerInfo.fromJson(Map<String, dynamic> json) => AstrologerInfo(
        id: json["_id"],
        profileImg: json["profile_img"],
        name: json["name"],
        number: json["number"],
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "profile_img": profileImg,
        "name": name,
        "number": number,
        "email": email,
      };
}