// lib/features/Settings/TodayPerformanceScreen.dart

import 'dart:convert';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class TodayPerformance {
  final String date;
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
  final String  onlineHoursStr;
  final bool    isCurrentlyOnline;
  final List<HourlyData> hourly;

  const TodayPerformance({
    required this.date,
    required this.chatSessions,
    required this.chatMinutes,
    required this.chatTimeStr,
    required this.audioSessions,
    required this.audioMinutes,
    required this.audioTimeStr,
    required this.videoSessions,
    required this.videoMinutes,
    required this.videoTimeStr,
    required this.totalSessions,
    required this.totalEarnings,
    required this.onlineSince,
    required this.onlineHoursStr,
    required this.isCurrentlyOnline,
    required this.hourly,
  });

  factory TodayPerformance.fromJson(Map<String, dynamic> j) => TodayPerformance(
        date             : j['date']?.toString()              ?? '',
        chatSessions     : _i(j['chat_sessions']),
        chatMinutes      : _d(j['chat_minutes']),
        chatTimeStr      : j['chat_time_str']?.toString()    ?? '0m',
        audioSessions    : _i(j['audio_sessions']),
        audioMinutes     : _d(j['audio_minutes']),
        audioTimeStr     : j['audio_time_str']?.toString()   ?? '0m',
        videoSessions    : _i(j['video_sessions']),
        videoMinutes     : _d(j['video_minutes']),
        videoTimeStr     : j['video_time_str']?.toString()   ?? '0m',
        totalSessions    : _i(j['total_sessions']),
        totalEarnings    : _d(j['total_earnings']),
        onlineSince      : j['online_since']?.toString(),
        onlineHoursStr   : j['online_hours_str']?.toString() ?? '0m',
        isCurrentlyOnline: j['is_currently_online'] == true,
        hourly           : (j['hourly_breakdown'] as List? ?? [])
            .map((e) => HourlyData.fromJson(e))
            .toList(),
      );

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
  static int    _i(dynamic v) => int.tryParse(v?.toString()    ?? '0') ?? 0;

  double get totalMinutes => chatMinutes + audioMinutes + videoMinutes;

  /// Progress toward 14h daily target (0.0 – 1.0)
  double get targetProgress => (totalMinutes / 840.0).clamp(0.0, 1.0);

  String get remainingStr {
    final rem = (840.0 - totalMinutes).clamp(0.0, 840.0);
    final h   = rem ~/ 60;
    final m   = (rem % 60).round();
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

class HourlyData {
  final String hour;
  final int chat, audio, video;
  const HourlyData({required this.hour, required this.chat,
      required this.audio, required this.video});
  factory HourlyData.fromJson(Map<String, dynamic> j) => HourlyData(
        hour : j['hour']?.toString()  ?? '',
        chat : _i(j['chat']),
        audio: _i(j['audio']),
        video: _i(j['video']),
      );
  int get total => chat + audio + video;
  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TodayPerformanceScreen extends StatefulWidget {
  const TodayPerformanceScreen({super.key});

  @override
  State<TodayPerformanceScreen> createState() => _TodayPerformanceScreenState();
}

class _TodayPerformanceScreenState extends State<TodayPerformanceScreen> {
  // ── App colour palette (matches rest of app) ───────────────────────────────
  static const _yellow  = Color(0xFFFCD417);
  static const _red     = Color(0xFFD41000);
  static const _grey898 = Color(0xFF898989);
  static const _border  = Color(0xFFE0E0E0);

  final _client = ApiClient();

  TodayPerformance? _data;
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await _client.post(
        'astrologer_api/today_performance', {},
        isAuthRequired: true,
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (json['result'] == true) {
        setState(() {
          _data    = TodayPerformance.fromJson(json['data']);
          _loading = false;
        });
      } else {
        setState(() { _error = json['message']?.toString(); _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor   : _yellow.withOpacity(0.25),
        foregroundColor   : Colors.black,
        elevation         : 0,
        title             : const Text(
          "Today's Performance",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon     : const Icon(Icons.refresh, color: Colors.black),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _yellow))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color    : _yellow,
                  child    : ListView(
                    padding : EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(16),
                      vertical  : FigmaSize.h(16),
                    ),
                    children: [
                      _onlineBanner(),
                      SizedBox(height: FigmaSize.h(14)),
                      _targetCard(),
                      SizedBox(height: FigmaSize.h(14)),
                      _sectionLabel('Sessions Today'),
                      SizedBox(height: FigmaSize.h(10)),
                      _sessionRow(),
                      SizedBox(height: FigmaSize.h(14)),
                      _sectionLabel('Time Breakdown'),
                      SizedBox(height: FigmaSize.h(10)),
                      _timeBreakdown(),
                      SizedBox(height: FigmaSize.h(14)),
                      _earningsCard(),
                      SizedBox(height: FigmaSize.h(14)),
                      _sectionLabel('Hourly Activity'),
                      SizedBox(height: FigmaSize.h(10)),
                      _hourlyBar(),
                      SizedBox(height: FigmaSize.h(24)),
                    ],
                  ),
                ),
    );
  }

  // ── Error view ─────────────────────────────────────────────────────────────
  Widget _errorView() => Center(
        child: Padding(
          padding: EdgeInsets.all(FigmaSize.w(24)),
          child  : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _red, size: 44),
              SizedBox(height: FigmaSize.h(12)),
              Text(_error ?? 'Something went wrong',
                  style    : const TextStyle(color: _red),
                  textAlign: TextAlign.center),
              SizedBox(height: FigmaSize.h(16)),
              ElevatedButton.icon(
                onPressed: _load,
                icon : const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _yellow,
                  foregroundColor: Colors.black,
                  elevation      : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Section label (matches app style) ─────────────────────────────────────
  Widget _sectionLabel(String t) => Text(
        t,
        style: TextStyle(
          fontSize  : FigmaSize.w(14),
          fontWeight: FontWeight.w600,
          color     : Colors.black,
        ),
      );

  // ── Online / offline banner ────────────────────────────────────────────────
  Widget _onlineBanner() {
    final d      = _data!;
    final online = d.isCurrentlyOnline;
    final color  = online ? Colors.green : Colors.grey;

    return Container(
      width     : double.infinity,
      padding   : EdgeInsets.symmetric(
          horizontal: FigmaSize.w(14), vertical: FigmaSize.h(12)),
      decoration: BoxDecoration(
        color       : color.withOpacity(0.07),
        border      : Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      ),
      child: Row(
        children: [
          // Pulsing dot
          Container(
            width : 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: FigmaSize.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online ? 'Currently Online' : 'Currently Offline',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(13),
                    fontWeight: FontWeight.w600,
                    color     : color,
                  ),
                ),
                if (d.onlineSince != null) ...[
                  SizedBox(height: FigmaSize.h(2)),
                  Text(
                    'Online since ${d.onlineSince}  •  ${d.onlineHoursStr} active today',
                    style: TextStyle(
                        fontSize: FigmaSize.w(11), color: _grey898),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 14-hour target progress card ───────────────────────────────────────────
  Widget _targetCard() {
    final d       = _data!;
    final pct     = d.targetProgress;
    final met     = pct >= 1.0;
    final barColor = met ? Colors.green : _red;

    return Container(
      padding   : EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color       : Colors.white,
        border      : Border.all(color: _border),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '14h Daily Target',
                style: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w600,
                  color     : Colors.black,
                ),
              ),
              Text(
                met ? 'Completed ✓' : '${d.remainingStr} left',
                style: TextStyle(
                  fontSize  : FigmaSize.w(12),
                  fontWeight: FontWeight.w500,
                  color     : met ? Colors.green : _red,
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(10)),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child       : LinearProgressIndicator(
              value          : pct,
              backgroundColor: _border,
              valueColor     : AlwaysStoppedAnimation<Color>(barColor),
              minHeight      : FigmaSize.h(8),
            ),
          ),
          SizedBox(height: FigmaSize.h(8)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                d.onlineHoursStr.isNotEmpty ? d.onlineHoursStr : '0m',
                style: TextStyle(
                  fontSize  : FigmaSize.w(12),
                  fontWeight: FontWeight.w600,
                  color     : barColor,
                ),
              ),
              Text(
                '14h 0m',
                style: TextStyle(
                    fontSize: FigmaSize.w(12), color: _grey898),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Session count row (4 cards) ───────────────────────────────────────────
  Widget _sessionRow() {
    final d = _data!;
    return Row(
      children: [
        _statCard('Total',  '${d.totalSessions}', Icons.bar_chart,       _yellow),
        SizedBox(width: FigmaSize.w(8)),
        _statCard('Chat',   '${d.chatSessions}',  Icons.chat_bubble_outline, Colors.blue),
        SizedBox(width: FigmaSize.w(8)),
        _statCard('Audio',  '${d.audioSessions}', Icons.phone_outlined,   Colors.green),
        SizedBox(width: FigmaSize.w(8)),
        _statCard('Video',  '${d.videoSessions}', Icons.videocam_outlined, Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding   : EdgeInsets.symmetric(
            vertical: FigmaSize.h(12), horizontal: FigmaSize.w(4)),
        decoration: BoxDecoration(
          color       : Colors.white,
          border      : Border.all(color: _border),
          borderRadius: BorderRadius.circular(FigmaSize.w(10)),
        ),
        child: Column(
          children: [
            Container(
              width : FigmaSize.w(32),
              height: FigmaSize.h(32),
              decoration: BoxDecoration(
                color       : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(height: FigmaSize.h(6)),
            Text(
              value,
              style: TextStyle(
                fontSize  : FigmaSize.w(18),
                fontWeight: FontWeight.w700,
                color     : Colors.black,
              ),
            ),
            SizedBox(height: FigmaSize.h(2)),
            Text(
              label,
              style: TextStyle(
                  fontSize: FigmaSize.w(11), color: _grey898),
            ),
          ],
        ),
      ),
    );
  }

  // ── Time breakdown (3 rows with progress bar) ─────────────────────────────
  Widget _timeBreakdown() {
    final d = _data!;
    final total = (d.chatMinutes + d.audioMinutes + d.videoMinutes)
        .clamp(1.0, double.infinity);

    return Column(
      children: [
        _timeRow('Chat', d.chatTimeStr, d.chatMinutes,
            Icons.chat_bubble_outline, Colors.blue, total),
        SizedBox(height: FigmaSize.h(8)),
        _timeRow('Voice Call', d.audioTimeStr, d.audioMinutes,
            Icons.phone_outlined, Colors.green, total),
        SizedBox(height: FigmaSize.h(8)),
        _timeRow('Video Call', d.videoTimeStr, d.videoMinutes,
            Icons.videocam_outlined, Colors.purple, total),
      ],
    );
  }

  Widget _timeRow(String label, String timeStr, double minutes,
      IconData icon, Color color, double total) {
    return Container(
      padding   : EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : Colors.white,
        border      : Border.all(color: _border),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      ),
      child: Row(
        children: [
          Container(
            width : FigmaSize.w(38),
            height: FigmaSize.h(38),
            decoration: BoxDecoration(
              color       : color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: FigmaSize.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.w500,
                        color     : Colors.black,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.w600,
                        color     : color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: FigmaSize.h(6)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child       : LinearProgressIndicator(
                    value          : minutes / total,
                    backgroundColor: _border,
                    valueColor     : AlwaysStoppedAnimation<Color>(color),
                    minHeight      : FigmaSize.h(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Earnings card ──────────────────────────────────────────────────────────
  Widget _earningsCard() {
    final d = _data!;
    return Container(
      width     : double.infinity,
      padding   : EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16), vertical: FigmaSize.h(16)),
      decoration: BoxDecoration(
        color       : _yellow.withOpacity(0.08),
        border      : Border.all(color: _yellow),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Earnings",
                  style: TextStyle(
                    fontSize  : FigmaSize.w(12),
                    fontWeight: FontWeight.w500,
                    color     : _grey898,
                  ),
                ),
                SizedBox(height: FigmaSize.h(4)),
                Text(
                  '₹ ${d.totalEarnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(24),
                    fontWeight: FontWeight.w700,
                    color     : Colors.black,
                  ),
                ),
                SizedBox(height: FigmaSize.h(4)),
                Text(
                  '${d.totalSessions} sessions completed',
                  style: TextStyle(
                      fontSize: FigmaSize.w(11), color: _grey898),
                ),
              ],
            ),
          ),
          Container(
            width : FigmaSize.w(48),
            height: FigmaSize.h(48),
            decoration: BoxDecoration(
              color       : _yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.black54, size: 26),
          ),
        ],
      ),
    );
  }

  // ── Hourly activity bar chart ──────────────────────────────────────────────
  Widget _hourlyBar() {
    final d = _data!;
    // Show 6 AM to 11 PM (index 6 to 23)
    final filtered = d.hourly.where((h) {
      final idx = d.hourly.indexOf(h);
      return idx >= 6 && idx <= 23;
    }).toList();

    final maxVal = filtered.fold<int>(
        1, (prev, h) => h.total > prev ? h.total : prev);

    return Container(
      padding   : EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : Colors.white,
        border      : Border.all(color: _border),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend row
          Row(
            children: [
              _dot(Colors.blue),   SizedBox(width: FigmaSize.w(4)),
              Text('Chat',  style: TextStyle(fontSize: FigmaSize.w(11), color: _grey898)),
              SizedBox(width: FigmaSize.w(12)),
              _dot(Colors.green),  SizedBox(width: FigmaSize.w(4)),
              Text('Audio', style: TextStyle(fontSize: FigmaSize.w(11), color: _grey898)),
              SizedBox(width: FigmaSize.w(12)),
              _dot(Colors.purple), SizedBox(width: FigmaSize.w(4)),
              Text('Video', style: TextStyle(fontSize: FigmaSize.w(11), color: _grey898)),
            ],
          ),
          SizedBox(height: FigmaSize.h(14)),

          // Bars
          SizedBox(
            height: FigmaSize.h(110),
            child : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children          : filtered.map((h) {
                final barH = maxVal == 0
                    ? 0.0
                    : (h.total / maxVal) * FigmaSize.h(88);
                final color = h.video > 0
                    ? Colors.purple
                    : h.audio > 0
                        ? Colors.green
                        : h.chat > 0
                            ? Colors.blue
                            : _border;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(1.5)),
                    child  : Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (h.total > 0)
                          Text(
                            '${h.total}',
                            style: TextStyle(
                                fontSize: FigmaSize.w(8),
                                color   : Colors.black54),
                          ),
                        SizedBox(height: FigmaSize.h(2)),
                        Container(
                          height    : barH.clamp(3.0, FigmaSize.h(88)),
                          decoration: BoxDecoration(
                            color       : color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        Text(
                          h.hour
                              .replaceAll(' AM', 'a')
                              .replaceAll(' PM', 'p'),
                          style: TextStyle(
                              fontSize: FigmaSize.w(8),
                              color   : _grey898),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width : 8, height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}