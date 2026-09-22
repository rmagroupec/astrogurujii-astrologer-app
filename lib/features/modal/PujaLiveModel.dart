// lib/features/modal/PujaLiveModel.dart
//
// Response of astrologer_api/puja_live_start, /puja_live_token and
// /puja_live_end. The start/token responses carry everything needed to
// actually join the Agora channel — which the old flow never returned,
// so puja "live" could never stream.

class PujaLiveResponse {
  final bool   status;
  final String message;

  /// Agora RTC token for this channel (broadcaster/publisher role).
  final String token;

  /// Agora channel name. Shared with viewers, stays stable across rejoins.
  final String channelId;

  /// 0 means "let Agora assign a uid" — must match how the token was built.
  final int    uid;

  /// Agora App ID from the server, so it never drifts from the app constant.
  final String appId;

  /// Token lifetime in seconds; refresh before this elapses.
  final int    expiresIn;

  final bool   isLive;
  final String pujaBookingId;
  final String startTime;
  final String endTime;

  const PujaLiveResponse({
    required this.status,
    required this.message,
    this.token         = '',
    this.channelId     = '',
    this.uid           = 0,
    this.appId         = '',
    this.expiresIn     = 3600,
    this.isLive        = false,
    this.pujaBookingId = '',
    this.startTime     = '',
    this.endTime       = '',
  });

  /// True only when the server returned a usable channel + token.
  bool get canJoin => status && token.isNotEmpty && channelId.isNotEmpty;

  factory PujaLiveResponse.fromJson(Map<String, dynamic> json) {
    return PujaLiveResponse(
      status       : json['status'] == true,
      message      : json['message']?.toString() ?? '',
      token        : json['token']?.toString() ?? '',
      channelId    : json['channel_id']?.toString() ?? '',
      uid          : _toInt(json['uid'], 0),
      appId        : json['app_id']?.toString() ?? '',
      expiresIn    : _toInt(json['expires_in'], 3600),
      isLive       : json['is_live'] == true,
      pujaBookingId: json['puja_booking_id']?.toString() ?? '',
      startTime    : json['start_time']?.toString() ?? '',
      endTime      : json['end_time']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
