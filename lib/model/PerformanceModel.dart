// lib/model/PerformanceModel.dart

class PerfData {
  final double onlineMinutes;    // ✅ total online time (busy + idle) — used for progress ring
  final double totalMinutes;     // daily target (14h = 840 min)
  final String onlineTimeStr;    // e.g. "2h 15m"
  final String remainingStr;     // e.g. "11h 45m"
  final String centerLabel;      // e.g. "Keep\nGoing"
  final bool   isCurrentlyOnline;

  // ✅ busy vs idle breakdown
  final double busyMinutes;      // actual time on calls
  final String busyTimeStr;
  final double idleMinutes;      // online but not on a call
  final String idleTimeStr;
  final String onlineHoursStr;   // same as onlineTimeStr but from API

  // ✅ active call
  final bool    isOnCall;
  final String? activeCallType;
  final double  activeCallMinutes;

  // ✅ per-service online status
  final bool isChatOnline;
  final bool isVoiceOnline;
  final bool isVideoOnline;

  // ✅ per-service sessions & minutes
  final int    chatSessions;
  final double chatMinutes;
  final String chatTimeStr;
  final int    audioSessions;
  final double audioMinutes;
  final String audioTimeStr;
  final int    videoSessions;
  final double videoMinutes;
  final String videoTimeStr;
  final int    totalSessions;
  final double totalEarnings;
  final String? onlineSince;

  const PerfData({
    required this.onlineMinutes,
    required this.totalMinutes,
    required this.onlineTimeStr,
    required this.remainingStr,
    required this.centerLabel,
    required this.isCurrentlyOnline,
    this.busyMinutes       = 0,
    this.busyTimeStr       = '0m',
    this.idleMinutes       = 0,
    this.idleTimeStr       = '0m',
    this.onlineHoursStr    = '0m',
    this.isOnCall          = false,
    this.activeCallType,
    this.activeCallMinutes = 0,
    this.isChatOnline      = false,
    this.isVoiceOnline     = false,
    this.isVideoOnline     = false,
    this.chatSessions      = 0,
    this.chatMinutes       = 0,
    this.chatTimeStr       = '0m',
    this.audioSessions     = 0,
    this.audioMinutes      = 0,
    this.audioTimeStr      = '0m',
    this.videoSessions     = 0,
    this.videoMinutes      = 0,
    this.videoTimeStr      = '0m',
    this.totalSessions     = 0,
    this.totalEarnings     = 0,
    this.onlineSince,
  });

  // ✅ progress uses total online time (including idle when online)
  double get progress => (onlineMinutes / totalMinutes).clamp(0.0, 1.0);

  factory PerfData.empty() => const PerfData(
    onlineMinutes    : 0,
    totalMinutes     : 840,
    onlineTimeStr    : '0m',
    remainingStr     : '14h 0m',
    centerLabel      : 'Get\nStarted',
    isCurrentlyOnline: false,
  );

  factory PerfData.fromJson(Map<String, dynamic> j) {
    const double target = 840.0; // 14h

    final double chat  = _d(j['chat_minutes']);
    final double audio = _d(j['audio_minutes']);
    final double video = _d(j['video_minutes']);

    // ✅ Use online_minutes from API — this includes:
    //    - completed call minutes
    //    - active call live minutes
    //    - idle time while any service is online (from online_since)
    final double apiOnlineMinutes = _d(j['online_minutes']);
    final double total = apiOnlineMinutes > 0
        ? apiOnlineMinutes
        : (chat + audio + video); // fallback

    final double remain = (target - total).clamp(0, target);

    String minsToStr(double m) {
      final h   = m ~/ 60;
      final min = (m % 60).round();
      if (h > 0 && min > 0) return '${h}h ${min}m';
      if (h > 0) return '${h}h';
      return '${min}m';
    }

    String label;
    if (total >= target)            label = 'Target\nMet! 🎉';
    else if (total >= target * 0.9) label = 'Almost\nThere';
    else if (total >= target * 0.5) label = 'Keep\nGoing';
    else                            label = 'Get\nStarted';

    return PerfData(
      onlineMinutes    : total,
      totalMinutes     : target,
      onlineTimeStr    : minsToStr(total),
      remainingStr     : minsToStr(remain),
      centerLabel      : label,
      isCurrentlyOnline: j['is_currently_online'] == true,

      busyMinutes      : _d(j['busy_minutes']),
      busyTimeStr      : j['busy_time_str']?.toString()    ?? '0m',
      idleMinutes      : _d(j['idle_minutes']),
      idleTimeStr      : j['idle_time_str']?.toString()    ?? '0m',
      onlineHoursStr   : j['online_hours_str']?.toString() ?? '0m',

      isOnCall         : j['is_on_call']      == true,
      activeCallType   : j['active_call_type']?.toString(),
      activeCallMinutes: _d(j['active_call_minutes']),

      isChatOnline     : j['is_chat_online']  == true,
      isVoiceOnline    : j['is_voice_online'] == true,
      isVideoOnline    : j['is_video_online'] == true,

      chatSessions     : _i(j['chat_sessions']),
      chatMinutes      : chat,
      chatTimeStr      : j['chat_time_str']?.toString()    ?? '0m',
      audioSessions    : _i(j['audio_sessions']),
      audioMinutes     : audio,
      audioTimeStr     : j['audio_time_str']?.toString()   ?? '0m',
      videoSessions    : _i(j['video_sessions']),
      videoMinutes     : video,
      videoTimeStr     : j['video_time_str']?.toString()   ?? '0m',
      totalSessions    : _i(j['total_sessions']),
      totalEarnings    : _d(j['total_earnings']),
      onlineSince      : j['online_since']?.toString(),
    );
  }

  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  static int _i(dynamic v) =>
      int.tryParse(v?.toString() ?? '0') ?? 0;
}