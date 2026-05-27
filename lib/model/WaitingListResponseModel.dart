import 'dart:convert';

UserChatListResponse userChatListResponseFromJson(String str) =>
    UserChatListResponse.fromJson(json.decode(str));

String userChatListResponseToJson(UserChatListResponse data) =>
    json.encode(data.toJson());

class UserChatListResponse {
  bool? result;
  String? message;
  List<UserChatData>? data2;

  UserChatListResponse({
    this.result,
    this.message,
    this.data2,
  });

  factory UserChatListResponse.fromJson(Map<String, dynamic> json) =>
      UserChatListResponse(
        result: json["result"],
        message: json["message"],
        data2: json["data2"] == null
            ? []
            : List<UserChatData>.from(
                json["data2"].map((x) => UserChatData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "result": result,
        "message": message,
        "data2": data2 == null
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
  });

  factory UserChatData.fromJson(Map<String, dynamic> json) => UserChatData(
        id: json["id"],
        userId: json["user_id"],
        astroId: json["astro_id"],
        type: json["type"],
        name: json["name"],
        image: json["image"],
        status: json["status"],
        createdAt: json["created_at"],
        updateAt: json["update_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "astro_id": astroId,
        "type": type,
        "name": name,
        "image": image,
        "status": status,
        "created_at": createdAt,
        "update_at": updateAt,
      };
}
