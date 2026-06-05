class PerfData {
  final double onlineMinutes;   // how long astrologer has been online today
  final double totalMinutes;    // daily target in minutes (e.g. 14 h = 840)
  final String onlineTimeStr;   // e.g. "13h 11m"
  final String remainingStr;    // e.g. "0h 49m"
  final String centerLabel;     // e.g. "Almost\nThere" or "Keep\nGoing"
  final bool   isCurrentlyOnline;
 
  const PerfData({
    required this.onlineMinutes,
    required this.totalMinutes,
    required this.onlineTimeStr,
    required this.remainingStr,
    required this.centerLabel,
    required this.isCurrentlyOnline,
  });
 
  double get progress => (onlineMinutes / totalMinutes).clamp(0.0, 1.0);
 
  factory PerfData.empty() => const PerfData(
        onlineMinutes   : 0,
        totalMinutes    : 840,   // 14 h target
        onlineTimeStr   : '0m',
        remainingStr    : '14h 0m',
        centerLabel     : 'Get\nStarted',
        isCurrentlyOnline: false,
      );
 
  factory PerfData.fromJson(Map<String, dynamic> j) {
    const double target = 840.0; // 14 h in minutes
    final double chat   = _d(j['chat_minutes']);
    final double audio  = _d(j['audio_minutes']);
    final double video  = _d(j['video_minutes']);
    final double total  = chat + audio + video;
    final double remain = (target - total).clamp(0, target);
 
    String minsToStr(double m) {
      final h = m ~/ 60, min = (m % 60).round();
      if (h > 0 && min > 0) return '${h}h ${min}m';
      if (h > 0) return '${h}h';
      return '${min}m';
    }
 
    String label;
    if (total >= target)       label = 'Target\nMet! 🎉';
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
    );
  }
 
  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;
}