// lib/model/AstrologerWalletModel.dart

class AstrologerWalletResponse {
  final bool result;
  final String message;
  final WalletData data;
  final OnlineStatus onlineStatus;
  final String notifyCount;

  AstrologerWalletResponse({
    required this.result,
    required this.message,
    required this.data,
    required this.onlineStatus,
    required this.notifyCount,
  });

  factory AstrologerWalletResponse.fromJson(Map<String, dynamic> json) {
    return AstrologerWalletResponse(
      result:      json['result']  ?? false,
      message:     json['message'] ?? '',
      notifyCount: json['notify_count']?.toString() ?? '',
      data: WalletData.fromJson(json),
      onlineStatus: OnlineStatus(
        isCallOnline:  json['is_call_online']  ?? 'off',
        isChatOnline:  json['is_chat_online']  ?? 'off',
        isVideoOnline: json['is_video_online'] ?? 'off',
      ),
    );
  }
}

class WalletData {
  final String myWallet;
  final String percentage;
  final String tds;
  final String payableAmount;
  final String todayAvailableBalance;
  final String todayPayableAmount;
  final String todayAstromallAvailableBalance;
  final String todayAstromallPayableAmount;
  final double adminDeductedBoostAllTime;
  final double adminDeductedNormalAllTime;
  final double todayAdminDeducted;
  final double todayAdminDeductedBoost;
  final double todayEmergencyEarnings;
  final double todayNormalEarnings;

  WalletData({
    required this.myWallet,
    required this.percentage,
    required this.tds,
    required this.payableAmount,
    required this.todayAvailableBalance,
    required this.todayPayableAmount,
    required this.todayAstromallAvailableBalance,
    required this.todayAstromallPayableAmount,
    required this.adminDeductedBoostAllTime,
    required this.adminDeductedNormalAllTime,
    required this.todayAdminDeducted,
    required this.todayAdminDeductedBoost,
    required this.todayEmergencyEarnings,
    required this.todayNormalEarnings,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
    myWallet     : json['my_wallet']?.toString()     ?? '0',
    percentage   : json['percentage']?.toString()    ?? '0',
    tds          : json['tds']?.toString()           ?? '0',
    payableAmount: json['payable_amount']?.toString() ?? '0',
    todayAvailableBalance          : json['today_available_balance']?.toString()           ?? '0',
    todayPayableAmount             : json['today_payable_amount']?.toString()               ?? '0',
    todayAstromallAvailableBalance : json['today_astromall_available_balance']?.toString()  ?? '0',
    todayAstromallPayableAmount    : json['today_astromall_payable_amount']?.toString()      ?? '0',
    adminDeductedBoostAllTime : double.tryParse(json['admin_deducted_boost_all_time']?.toString()  ?? '0') ?? 0,
    adminDeductedNormalAllTime: double.tryParse(json['admin_deducted_normal_all_time']?.toString() ?? '0') ?? 0,
    todayAdminDeducted        : double.tryParse(json['today_admin_deducted']?.toString()        ?? '0') ?? 0,
    todayAdminDeductedBoost   : double.tryParse(json['today_admin_deducted_boost']?.toString()  ?? '0') ?? 0,
    todayEmergencyEarnings    : double.tryParse(json['today_emergency_earnings']?.toString()    ?? '0') ?? 0,
    todayNormalEarnings       : double.tryParse(json['today_normal_earnings']?.toString()       ?? '0') ?? 0,
  );
}

class OnlineStatus {
  final String isCallOnline;
  final String isChatOnline;
  final String isVideoOnline;

  OnlineStatus({
    required this.isCallOnline,
    required this.isChatOnline,
    required this.isVideoOnline,
  });

  factory OnlineStatus.fromJson(Map<String, dynamic> json) {
    return OnlineStatus(
      isCallOnline:  json['is_call_online']  ?? 'off',
      isChatOnline:  json['is_chat_online']  ?? 'off',
      isVideoOnline: json['is_video_online'] ?? 'off',
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WALLET TRANSACTION  (used by WalletScreen recent transactions)
// ─────────────────────────────────────────────────────────────────
class TransactionListResponse1 {
  final bool                    status;
  final String                  message;
  final List<WalletTransaction> results;

  TransactionListResponse1({
    required this.status,
    required this.message,
    required this.results,
  });

  factory TransactionListResponse1.fromJson(Map<String, dynamic> json) {
     print('TX JSON: $json');
  return TransactionListResponse1(
    status : json['status']  ?? json['result'] ?? false,
    message: json['message'] ?? '',
    results: (json['results'] as List<dynamic>? ?? [])  // ✅ was 'transaction_list'
        .map((e) => WalletTransaction.fromJson(e))
        .toList(),
  );
}
}

class WalletTransaction {
  final String id;
  final String amount;
  final String type;
  final String description;
  final String createdDate;
  final String note;
  final String userName;
  final int    callDuration;
  final String payFor;
  final String channelId;   // ✅ new
  final String userId;      // ✅ new

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdDate,
    required this.note,
    required this.userName,
    required this.callDuration,
    required this.payFor,
    required this.channelId,  // ✅ new
    required this.userId,     // ✅ new
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
  return WalletTransaction(
    id          : json['_id']?.toString()          ?? '',
    amount      : json['amount']?.toString()        ?? '0',
    type        : json['amount_type']?.toString()   ?? '',
    description : json['note']?.toString()          ?? '',
    createdDate : json['Created_date']?.toString()  ?? '',
    note        : json['note']?.toString()          ?? '',
    userName    : json['user_name']?.toString()     ?? '',  // ✅ "Chat with Name"
  callDuration: int.tryParse(
  json['call_duracation']?.toString() ??   // ✅ API field name (with typo)
  json['call_duration']?.toString()  ??   // fallback
  '0'
) ?? 0,
    payFor      : json['pay_for']?.toString()       ?? '',
    channelId   : json['channel_id']?.toString()   ?? '',  // ✅ new
    userId      : json['user_id']?.toString()       ?? '',  // ✅ new
  );
}
}