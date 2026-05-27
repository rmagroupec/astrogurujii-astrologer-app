import 'dart:convert';

BankAccResponse bankAccResponseFromJson(String str) =>
    BankAccResponse.fromJson(json.decode(str));

String bankAccResponseToJson(BankAccResponse data) =>
    json.encode(data.toJson());

class BankAccResponse {
  bool? result;
  String? message;
  List<BankAccRequest>? bankAccRequest;

  BankAccResponse({
    this.result,
    this.message,
    this.bankAccRequest,
  });

  factory BankAccResponse.fromJson(Map<String, dynamic> json) =>
      BankAccResponse(
        result: json["result"],
        message: json["message"],
        bankAccRequest: json["bank_acc_request"] == null
            ? []
            : List<BankAccRequest>.from(
                json["bank_acc_request"].map((x) => BankAccRequest.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "result": result,
        "message": message,
        "bank_acc_request": bankAccRequest == null
            ? []
            : List<dynamic>.from(bankAccRequest!.map((x) => x.toJson())),
      };
}

class BankAccRequest {
  String? id;
  String? astroId;
  String? accountType;
  String? accountHolderName;
  String? accountNo;
  String? bank;
  String? ifsc;
  String? adminComment;
  String? status;
  String? createdAt;
  String? updatedAt;

  BankAccRequest({
    this.id,
    this.astroId,
    this.accountType,
    this.accountHolderName,
    this.accountNo,
    this.bank,
    this.ifsc,
    this.adminComment,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccRequest.fromJson(Map<String, dynamic> json) =>
      BankAccRequest(
        id: json["id"],
        astroId: json["astro_id"],
        accountType: json["account_type"],
        accountHolderName: json["account_holder_name"],
        accountNo: json["account_no"],
        bank: json["bank"],
        ifsc: json["ifsc"],
        adminComment: json["admin_comment"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "astro_id": astroId,
        "account_type": accountType,
        "account_holder_name": accountHolderName,
        "account_no": accountNo,
        "bank": bank,
        "ifsc": ifsc,
        "admin_comment": adminComment,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
