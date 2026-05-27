import 'dart:convert';

ChatCallResponse chatCallResponseFromJson(String str) =>
    ChatCallResponse.fromJson(json.decode(str));

String chatCallResponseToJson(ChatCallResponse data) =>
    json.encode(data.toJson());

class ChatCallResponse {
  bool? result;
  String? message;
  List<ChatCallRequest>? chatCallRequest;

  ChatCallResponse({
    this.result,
    this.message,
    this.chatCallRequest,
  });

  factory ChatCallResponse.fromJson(Map<String, dynamic> json) =>
      ChatCallResponse(
        result: json["result"],
        message: json["message"],
        chatCallRequest: json["chat_call_request"] == null
            ? []
            : List<ChatCallRequest>.from(
                json["chat_call_request"]
                    .map((x) => ChatCallRequest.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "result": result,
        "message": message,
        "chat_call_request": chatCallRequest == null
            ? []
            : List<dynamic>.from(chatCallRequest!.map((x) => x.toJson())),
      };
}

class ChatCallRequest {
  String? id;
  String? astroId;
  String? type;
  String? price;
  String? status;
  String? adminComment;
  String? createdAt;
  String? updateAt;

  ChatCallRequest({
    this.id,
    this.astroId,
    this.type,
    this.price,
    this.status,
    this.adminComment,
    this.createdAt,
    this.updateAt,
  });

  factory ChatCallRequest.fromJson(Map<String, dynamic> json) =>
      ChatCallRequest(
        id: json["id"],
        astroId: json["astro_id"],
        type: json["type"],
        price: json["price"],
        status: json["status"],
        adminComment: json["admin_comment"],
        createdAt: json["created_at"],
        updateAt: json["update_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "astro_id": astroId,
        "type": type,
        "price": price,
        "status": status,
        "admin_comment": adminComment,
        "created_at": createdAt,
        "update_at": updateAt,
      };
}
