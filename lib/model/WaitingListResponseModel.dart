import 'dart:convert';

UserChatListResponse userChatListResponseFromJson(String str) =>
    UserChatListResponse.fromJson(json.decode(str));

String userChatListResponseToJson(UserChatListResponse data) =>
    json.encode(data.toJson());

class UserChatListResponse {
  bool?              result;
  String?            message;
  List<UserChatData>? data2;

  UserChatListResponse({this.result, this.message, this.data2});

  factory UserChatListResponse.fromJson(Map<String, dynamic> json) =>
      UserChatListResponse(
        result  : json["result"],
        message : json["message"],
        data2   : json["data2"] == null
            ? []
            : List<UserChatData>.from(
                json["data2"].map((x) => UserChatData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "result" : result,
        "message": message,
        "data2"  : data2 == null
            ? []
            : List<dynamic>.from(data2!.map((x) => x.toJson())),
      };
}

class UserChatData {
  String? id;
  String? userId;
  String? astroId;
  String? type;
  String? name;
  String? image;
  String? status;
  String? createdAt;
  String? updateAt;

  // ── New fields from updated API ──────────────────────────────────────────
  /// Minutes the user should expect to wait.
  /// 0 = astrologer is available now.
  /// Always ≤ 20 (hard-capped on server).
  int    waitTimeMinutes;

  /// Human-readable string: "Available now" | "5 min wait" etc.
  String waitLabel;

  UserChatData({
    this.id,
    this.userId,
    this.astroId,
    this.type,
    this.name,
    this.image,
    this.status,
    this.createdAt,
    this.updateAt,
    this.waitTimeMinutes = 5,
    this.waitLabel       = '5 min wait',
  });

  factory UserChatData.fromJson(Map<String, dynamic> json) => UserChatData(
        id               : json["id"]?.toString(),
        userId           : json["user_id"]?.toString(),
        astroId          : json["astro_id"]?.toString(),
        type             : json["type"]?.toString(),
        name             : json["name"]?.toString(),
        image            : json["image"]?.toString(),
        status           : json["status"]?.toString(),
        createdAt        : json["created_at"]?.toString(),
        updateAt         : json["update_at"]?.toString(),
        waitTimeMinutes  : _toInt(json["wait_time_minutes"]),
        waitLabel        : json["wait_label"]?.toString() ?? _defaultLabel(_toInt(json["wait_time_minutes"])),
      );

  Map<String, dynamic> toJson() => {
        "id"                 : id,
        "user_id"            : userId,
        "astro_id"           : astroId,
        "type"               : type,
        "name"               : name,
        "image"              : image,
        "status"             : status,
        "created_at"         : createdAt,
        "update_at"          : updateAt,
        "wait_time_minutes"  : waitTimeMinutes,
        "wait_label"         : waitLabel,
      };

  static int _toInt(dynamic v) {
    if (v == null) return 5;
    if (v is int)    return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 5;
  }

  static String _defaultLabel(int mins) =>
      mins == 0 ? 'Available now' : '$mins min wait';
}