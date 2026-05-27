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
      result: json['result'] ?? false,
      message: json['message'] ?? '',
      data: WalletData.fromJson(json['data'] ?? {}),
      onlineStatus: OnlineStatus.fromJson(json['online_status'] ?? {}),
      notifyCount: json['notify_count'] ?? '',
    );
  }
}

class WalletData {
  final String lifetimeEarning;
  final String pendingEarning;
  final String weeklyEarning;
  final String rank;

  final String todayAvailableBalance;
  final String todayPayableAmount;

  final String todayAstromallAvailableBalance;
  final String todayAstromallPayableAmount;

  final String note;

  WalletData({
    required this.lifetimeEarning,
    required this.pendingEarning,
    required this.weeklyEarning,
    required this.rank,
    required this.todayAvailableBalance,
    required this.todayPayableAmount,
    required this.todayAstromallAvailableBalance,
    required this.todayAstromallPayableAmount,
    required this.note,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      lifetimeEarning: json['lifetime_earning'] ?? '0',
      pendingEarning: json['pending_earning'] ?? '0',
      weeklyEarning: json['weekly_earning'] ?? '0',
      rank: json['rank'] ?? '0',
      todayAvailableBalance: json['today_available_balance'] ?? '0',
      todayPayableAmount: json['today_payable_amount'] ?? '0',
      todayAstromallAvailableBalance: json['today_astromall_available_balance'] ?? '0',
      todayAstromallPayableAmount: json['today_astromall_payable_amount'] ?? '0',
      note: json['note'] ?? '',
    );
  }
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
      isCallOnline: json['is_call_online'] ?? 'off',
      isChatOnline: json['is_chat_online'] ?? 'off',
      isVideoOnline: json['is_video_online'] ?? 'off',
    );
  }
}
