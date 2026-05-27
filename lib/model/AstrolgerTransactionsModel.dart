import 'dart:convert';

/// ===============================
/// JSON Helpers
/// ===============================

TransactionListResponse transactionListResponseFromJson(String str) =>
    TransactionListResponse.fromJson(json.decode(str));

String transactionListResponseToJson(TransactionListResponse data) =>
    json.encode(data.toJson());

/// ===============================
/// Top-Level Response Model
/// ===============================

class TransactionListResponse {
  final bool result;
  final String message;
  final List<TransactionItem> transactionList;

  TransactionListResponse({
    required this.result,
    required this.message,
    required this.transactionList,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    return TransactionListResponse(
      result: json['result'] ?? false,
      message: json['message'] ?? '',
      transactionList: (json['transaction_list'] as List<dynamic>? ?? [])
          .map((e) => TransactionItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'message': message,
      'transaction_list':
          transactionList.map((e) => e.toJson()).toList(),
    };
  }
}

/// ===============================
/// Transaction Item Model
/// ===============================

class TransactionItem {
  final String transactionId;
  final String astrologerId;
  final String userId;
  final String transactionType;
  final double amount;
  final DateTime transactionDate;
  final String payFor;
  final String note;
  final String transactionStatus;
  final String userName;
  final int callDuration;

  TransactionItem({
    required this.transactionId,
    required this.astrologerId,
    required this.userId,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    required this.payFor,
    required this.note,
    required this.transactionStatus,
    required this.userName,
    required this.callDuration,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      transactionId: json['transactionID'] ?? '',
      astrologerId: json['astrologer_id'] ?? '',
      userId: json['user_id'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      amount: _toDouble(json['amount']),
      transactionDate: _toDate(json['transaction_date']),
      payFor: json['pay_for'] ?? '',
      note: json['note'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      userName: json['user_name'] ?? '',
      callDuration: _toInt(json['call_duracation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionID': transactionId,
      'astrologer_id': astrologerId,
      'user_id': userId,
      'transaction_type': transactionType,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'pay_for': payFor,
      'note': note,
      'transaction_status': transactionStatus,
      'user_name': userName,
      'call_duracation': callDuration,
    };
  }

  /// ===============================
  /// Computed Helpers (Optional but Useful)
  /// ===============================

  bool get isCredit => transactionType.toLowerCase() == 'credit';

  bool get isChat => payFor.toLowerCase() == 'chat';
  bool get isVideo => payFor.toLowerCase() == 'video';
  bool get isVoice => payFor.toLowerCase() == 'voice';

  String get formattedAmount => "₹${amount.toStringAsFixed(2)}";
}

/// ===============================
/// Safe Parsing Helpers
/// ===============================

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  return int.tryParse(value.toString()) ?? 0;
}

DateTime _toDate(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(value.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
