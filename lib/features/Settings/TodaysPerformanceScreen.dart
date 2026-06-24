// lib/features/Settings/PerformanceDashboardScreen.dart
//
// Matches both screenshots exactly:
// ── Profile header: avatar, name, online dot, tag progress bar
// ── Tab 1 "My Performance":
//      Today's Profile Health table, My Availability grid,
//      Loyal User Conversion card
// ── Tab 2 "Earn Tag":
//      Current Status (busy mins + earnings),
//      Eligibility Criteria table (Rising Star / Top Choice / Celebrity)
// ── All data live from APIs

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models (inline — no extra files needed)
// ─────────────────────────────────────────────────────────────────────────────

class _HealthData {
  final int    totalSessions;
  final int    missedSessions;
  final double revenueLoss;
  final int    missedCalls;
  final int    missedChats;
  final int    loyalUsers;

  const _HealthData({
    required this.totalSessions,
    required this.missedSessions,
    required this.revenueLoss,
    required this.missedCalls,
    required this.missedChats,
    required this.loyalUsers,
  });

  factory _HealthData.fromJson(Map<String, dynamic> j) => _HealthData(
        totalSessions  : _i(j['total_sessions']),
        missedSessions : _i(j['missed_sessions']),
        revenueLoss    : _d(j['revenue_loss']),
        missedCalls    : _i(j['missed_calls']),
        missedChats    : _i(j['missed_chats']),
        loyalUsers     : _i(j['loyal_users']),
      );

  static int    _i(dynamic v) => int.tryParse(v?.toString()    ?? '0') ?? 0;
  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

class _AvailData {
  final int todayAvailMins;
  final int week7AvailMins;
  final int days30AvailMins;
  final int todayBusyMins;
  final int week7BusyMins;
  final int days30BusyMins;

  const _AvailData({
    required this.todayAvailMins,
    required this.week7AvailMins,
    required this.days30AvailMins,
    required this.todayBusyMins,
    required this.week7BusyMins,
    required this.days30BusyMins,
  });

  factory _AvailData.fromJson(Map<String, dynamic> j) => _AvailData(
        todayAvailMins  : _i(j['today_avail_mins']),
        week7AvailMins  : _i(j['week7_avail_mins']),
        days30AvailMins : _i(j['days30_avail_mins']),
        todayBusyMins   : _i(j['today_busy_mins']),
        week7BusyMins   : _i(j['week7_busy_mins']),
        days30BusyMins  : _i(j['days30_busy_mins']),
      );

  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

class _LoyalData {
  final double conversionPct;
  final int    totalUsers;
  final int    loyalUsers;
  final int    loyalLevel;

  const _LoyalData({
    required this.conversionPct,
    required this.totalUsers,
    required this.loyalUsers,
    required this.loyalLevel,
  });

  factory _LoyalData.fromJson(Map<String, dynamic> j) => _LoyalData(
        conversionPct : _d(j['conversion_pct']),
        totalUsers    : _i(j['total_users']),
        loyalUsers    : _i(j['loyal_users']),
        loyalLevel    : _i(j['loyal_level']),
      );

  String get ratingLabel {
    if (conversionPct >= 25.5) return 'Good';
    if (conversionPct >= 17.0) return 'Average';
    return 'Low';
  }

  Color get ratingColor {
    if (conversionPct >= 25.5) return Colors.green;
    if (conversionPct >= 17.0) return const Color(0xFFFCD417);
    return Colors.red;
  }

  static int    _i(dynamic v) => int.tryParse(v?.toString()    ?? '0') ?? 0;
  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

class _TagData {
  final double busyMins7;
  final double busyMins30;
  final double earnings30;
  final int    loyalLevel;
  final double chatRating;
  final double callRating;
  // Current tag: 0=none, 1=Rising Star, 2=Top Choice, 3=Celebrity
  final int    currentTag;
  // Gaps to next tag
  final double minsToNextTag;
  final double earningsToNextTag;

  const _TagData({
    required this.busyMins7,
    required this.busyMins30,
    required this.earnings30,
    required this.loyalLevel,
    required this.chatRating,
    required this.callRating,
    required this.currentTag,
    required this.minsToNextTag,
    required this.earningsToNextTag,
  });

  factory _TagData.fromJson(Map<String, dynamic> j) {
    final bm7  = _d(j['busy_mins_7']);
    final bm30 = _d(j['busy_mins_30']);
    final e30  = _d(j['earnings_30']);
    final ll   = _i(j['loyal_level']);
    final cr   = _d(j['chat_rating']);
    final vr   = _d(j['call_rating']);
    final ct   = _i(j['current_tag']);
    final mn   = _d(j['mins_to_next_tag']);
    final en   = _d(j['earnings_to_next_tag']);
    return _TagData(
      busyMins7         : bm7,
      busyMins30        : bm30,
      earnings30        : e30,
      loyalLevel        : ll,
      chatRating        : cr,
      callRating        : vr,
      currentTag        : ct,
      minsToNextTag     : mn,
      earningsToNextTag : en,
    );
  }

  String get nextTagName {
    switch (currentTag) {
      case 0: return 'Rising Star';
      case 1: return 'Top Choice';
      case 2: return 'Celebrity';
      default: return '';
    }
  }

  static int    _i(dynamic v) => int.tryParse(v?.toString()    ?? '0') ?? 0;
  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen>
    with SingleTickerProviderStateMixin {

  static const _bg     = Color(0xFF12122A);
  static const _card   = Color(0xFF1C1C35);
  static const _yellow = Color(0xFFFCD417);
  static const _border = Color(0xFF2E2E50);
  static const _grey   = Color(0xFF9898B0);

  late final TabController _tab;
  final _client = ApiClient();

  // data
  Astrologer? _astro;
  _HealthData? _health;
  _AvailData?  _avail;
  _LoyalData?  _loyal;
  _TagData?    _tag;
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Load all data ──────────────────────────────────────────────────────────
  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final results = await Future.wait([
        ApiService().get_astrologer_profile(),
        _client.post('astrologer_api/performance_dashboard', {}, isAuthRequired: true),
      ]);

      final profileRes = results[0] as AstrologerProfileResponse;
      final dashRes    = results[1] as dynamic;
      final dashJson   = jsonDecode(dashRes.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _astro   = profileRes.results.isNotEmpty ? profileRes.results.first : null;

        if (dashJson['result'] == true) {
          final d = dashJson['data'] as Map<String, dynamic>;
          _health = _HealthData.fromJson(d['health']      as Map<String, dynamic>? ?? {});
          _avail  = _AvailData.fromJson(d['availability'] as Map<String, dynamic>? ?? {});
          _loyal  = _LoyalData.fromJson(d['loyal']        as Map<String, dynamic>? ?? {});
          _tag    = _TagData.fromJson(d['tag']             as Map<String, dynamic>? ?? {});
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _today() => DateFormat('dd MMMM yyyy').format(DateTime.now());

  // average rating from profile
  double get _avgRating {
    final ratings = _astro?.rating ?? [];
    if (ratings.isEmpty) return 0.0;
    return ratings.map((r) => r.rating.toDouble()).reduce((a, b) => a + b) /
        ratings.length;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation      : 0,
        title: const Text(
          'Performance Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon     : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _yellow))
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    _profileHeader(),
                    _tagProgressBar(),
                    _tabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _myPerformanceTab(),
                          _earnTagTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon : const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow, foregroundColor: Colors.black),
            ),
          ],
        ),
      );

  // ── Profile header ─────────────────────────────────────────────────────────
  Widget _profileHeader() {
    final name    = _astro?.displayname ?? 'Astrologer';
    final img     = _astro?.profileImg  ?? '';
    final online  = (_astro?.isChatOnline ?? false) ||
                    (_astro?.isVoiceOnline ?? false) ||
                    (_astro?.isVideoOnline ?? false);

    return Padding(
      padding: EdgeInsets.only(top: FigmaSize.h(16), bottom: FigmaSize.h(8)),
      child: Column(
        children: [
          // Avatar
          Container(
            width : 72, height: 72,
            decoration: BoxDecoration(
              shape : BoxShape.circle,
              border: Border.all(color: _yellow, width: 2.5),
            ),
            child: ClipOval(
              child: img.isNotEmpty
                  ? Image.network(img, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.white, size: 38))
                  : const Icon(Icons.person, color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 10),
          // Name + online dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize  : 18,
                      fontWeight: FontWeight.w700,
                      color     : Colors.white)),
              const SizedBox(width: 6),
              Container(
                width : 14, height: 14,
                decoration: BoxDecoration(
                  color : online ? Colors.green : Colors.grey,
                  shape : BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tag progress bar ───────────────────────────────────────────────────────
  // Rising Star → Top Choice → Celebrity
  Widget _tagProgressBar() {
    final tagIdx = _tag?.currentTag ?? 0; // 0=none,1=rising,2=top,3=celebrity

    // Dot positions: 0=Rising Star, 1=Top Choice, 2=Celebrity
    final labels = ['Rising Star', 'Top choice', 'Celebrity'];

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(24), vertical: FigmaSize.h(8)),
      child: Column(
        children: [
          // Bar
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Grey track
              Container(
                height    : 6,
                decoration: BoxDecoration(
                  color       : _border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Yellow fill
              FractionallySizedBox(
                widthFactor: (tagIdx / 3.0).clamp(0.0, 1.0),
                child: Container(
                  height    : 6,
                  decoration: BoxDecoration(
                    color       : _yellow,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Dots at 1/3, 2/3, end
              ...List.generate(3, (i) {
                final frac = (i + 1) / 3.0;
                final done = tagIdx > i;
                return FractionallySizedBox(
                  widthFactor: frac,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width : 14, height: 14,
                      decoration: BoxDecoration(
                        color : done ? _yellow : _card,
                        shape : BoxShape.circle,
                        border: Border.all(
                            color: done ? _yellow : _grey, width: 2),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) => Text(l,
                style: const TextStyle(
                    fontSize: 10, color: _grey))).toList(),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _tabBar() => Container(
        color: _bg,
        child: TabBar(
          controller          : _tab,
          labelColor          : Colors.white,
          unselectedLabelColor: _grey,
          indicatorColor      : _yellow,
          indicatorWeight     : 3,
          labelStyle          : const TextStyle(fontWeight: FontWeight.w600),
          tabs                : const [
            Tab(text: 'My Performance'),
            Tab(text: 'Earn Tag'),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — MY PERFORMANCE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _myPerformanceTab() => RefreshIndicator(
        onRefresh: _load,
        color    : _yellow,
        child    : ListView(
          padding : EdgeInsets.all(FigmaSize.w(16)),
          children: [
            _profileHealthCard(),
            SizedBox(height: FigmaSize.h(16)),
            _availabilityCard(),
            SizedBox(height: FigmaSize.h(16)),
            _loyalConversionCard(),
            SizedBox(height: FigmaSize.h(24)),
          ],
        ),
      );

  // ── Today's Profile Health ─────────────────────────────────────────────────
  Widget _profileHealthCard() {
    final h = _health;

    final rows = [
      ['Total Sessions',                  '${h?.totalSessions  ?? 0}'],
      ['Missed Sessions',                 '${h?.missedSessions ?? 0}'],
      ['Revenue Loss from missed Sessions','₹${h?.revenueLoss.toStringAsFixed(0) ?? '0'}'],
      ['Missed Calls',                    '${h?.missedCalls    ?? 0}'],
      ['Missed Chats',                    '${h?.missedChats    ?? 0}'],
      ['Loyal Users',                     '${h?.loyalUsers     ?? 0}'],
    ];

    return _cardWrapper(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Today's Profile Health",
              style: TextStyle(
                  color     : Colors.white,
                  fontSize  : 15,
                  fontWeight: FontWeight.w700)),
          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color       : _border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_today(),
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: FigmaSize.h(11)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.value[0],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13))),
                    Text(e.value[1],
                        style: const TextStyle(
                            color     : Colors.white,
                            fontSize  : 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: _border),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── My Availability ────────────────────────────────────────────────────────
  Widget _availabilityCard() {
    final a = _avail;

    final cols = ['Today', 'Last 7 Days', 'Last 30 days'];
    final avail = [
      '${a?.todayAvailMins ?? 0} mins',
      '${a?.week7AvailMins ?? 0} mins',
      '${a?.days30AvailMins ?? 0} mins',
    ];
    final busy = [
      '${a?.todayBusyMins ?? 0} mins',
      '${a?.week7BusyMins ?? 0} mins',
      '${a?.days30BusyMins ?? 0} mins',
    ];

    return _cardWrapper(
      header: const Text('My Availability',
          style: TextStyle(
              color     : Colors.white,
              fontSize  : 15,
              fontWeight: FontWeight.w700)),
      child: Column(
        children: [
          // Header row
          _availRow('Availability', cols, isHeader: true),
          Divider(height: 1, color: _border),
          _availRow('Available Mins', avail),
          Divider(height: 1, color: _border),
          _availRow('Busy Mins', busy),
          Divider(height: 1, color: _border),
          // Check last 30 days link
          Padding(
            padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
            child: Row(
              children: const [
                Expanded(
                  child: Text('Check Last 30 Days Availability',
                      style: TextStyle(
                          color     : Colors.white,
                          fontSize  : 13,
                          fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _availRow(String label, List<String> vals,
      {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: TextStyle(
                  color     : isHeader ? Colors.white : Colors.white70,
                  fontSize  : 12,
                  fontWeight: isHeader
                      ? FontWeight.w700
                      : FontWeight.w400,
                )),
          ),
          ...vals.map((v) => Expanded(
                flex: 3,
                child: Text(v,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color     : isHeader ? Colors.white : Colors.white,
                      fontSize  : 12,
                      fontWeight: isHeader
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
              )),
        ],
      ),
    );
  }

  // ── Loyal User Conversion ──────────────────────────────────────────────────
  Widget _loyalConversionCard() {
    final l   = _loyal;
    final pct = l?.conversionPct ?? 0.0;
    // Brackets: 0–17 Low, 17–25.5 Average, 25.5–100 Good
    final barFraction = (pct / 100.0).clamp(0.0, 1.0);
    final label  = l?.ratingLabel  ?? 'Low';
    final lcolor = l?.ratingColor  ?? Colors.red;

    return _cardWrapper(
      header: const Text('Loyal User Conversion',
          style: TextStyle(
              color     : Colors.white,
              fontSize  : 15,
              fontWeight: FontWeight.w700)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: FigmaSize.h(8)),
          // Percentage + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${pct.toStringAsFixed(1)} %',
                style: TextStyle(
                  color     : _yellow,
                  fontSize  : FigmaSize.w(30),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding   : const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border      : Border.all(color: lcolor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: lcolor, size: 13),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          color     : lcolor,
                          fontWeight: FontWeight.w600,
                          fontSize  : 12)),
                ]),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(10)),

          // Progress bar with markers 0 / 17 / 25.5 / 100
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value          : barFraction,
                  backgroundColor: _border,
                  valueColor     : AlwaysStoppedAnimation<Color>(_yellow),
                  minHeight      : 8,
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0.0',   style: TextStyle(color: _grey, fontSize: 10)),
              Text('17.0',  style: TextStyle(color: _grey, fontSize: 10)),
              Text('25.5',  style: TextStyle(color: _grey, fontSize: 10)),
              Text('100.0', style: TextStyle(color: _grey, fontSize: 10)),
            ],
          ),
          SizedBox(height: FigmaSize.h(14)),

          // Stats row
          Row(
            children: [
              _loyalStat('Total users',      '${l?.totalUsers  ?? 0}'),
              _vDivider(),
              _loyalStat('Loyal Users',      '${l?.loyalUsers  ?? 0}'),
              _vDivider(),
              _loyalStat('Loyal user level', '${l?.loyalLevel  ?? 0}'),
            ],
          ),
          SizedBox(height: FigmaSize.h(12)),
          Text(
            'Loyal user conversion means if Astrotalk provides you with '
            '${l?.totalUsers ?? 500} new customers then how many of them '
            'became your loyal customers',
            style: const TextStyle(color: _grey, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _loyalStat(String label, String val) => Expanded(
        child: Column(
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _grey, fontSize: 11)),
            SizedBox(height: FigmaSize.h(4)),
            Text(val,
                style: const TextStyle(
                    color     : Colors.white,
                    fontSize  : 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _vDivider() => Container(
        width : 1,
        height: 36,
        color : _border,
        margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(8)),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — EARN TAG
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _earnTagTab() => RefreshIndicator(
        onRefresh: _load,
        color    : _yellow,
        child    : ListView(
          padding : EdgeInsets.all(FigmaSize.w(16)),
          children: [
            _currentStatusCard(),
            SizedBox(height: FigmaSize.h(16)),
            _eligibilityCard(),
            SizedBox(height: FigmaSize.h(24)),
          ],
        ),
      );

  // ── Current Status ─────────────────────────────────────────────────────────
  Widget _currentStatusCard() {
    final t    = _tag;
    final next = t?.nextTagName ?? 'Rising Star';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Current Status',
            style: TextStyle(
                color     : Colors.white,
                fontSize  : 15,
                fontWeight: FontWeight.w700)),
        SizedBox(height: FigmaSize.h(10)),

        // Average Busy Minutes card
        _cardWrapper(
          header: const Text('Average Busy Minutes',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t?.busyMins7.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                              color     : Colors.white,
                              fontSize  : 28,
                              fontWeight: FontWeight.w700),
                        ),
                        const Text('Last 7 days',
                            style: TextStyle(color: _grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 44, color: _border),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: FigmaSize.w(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t?.busyMins30.toStringAsFixed(0) ?? '0'}',
                            style: const TextStyle(
                                color     : Colors.white,
                                fontSize  : 28,
                                fontWeight: FontWeight.w700),
                          ),
                          const Text('Last 30 days',
                              style: TextStyle(color: _grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if ((t?.minsToNextTag ?? 0) > 0) ...[
                SizedBox(height: FigmaSize.h(10)),
                Divider(height: 1, color: _border),
                SizedBox(height: FigmaSize.h(10)),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                          text:
                              'Only ${t!.minsToNextTag.toStringAsFixed(0)} mins more to become '),
                      TextSpan(
                          text: next,
                          style: const TextStyle(
                              color     : _yellow,
                              fontWeight: FontWeight.w700)),
                      const TextSpan(text: '!'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: FigmaSize.h(12)),

        // Earnings + Loyal level row
        Row(
          children: [
            Expanded(
              child: _cardWrapper(
                header: const Text('Last 30 days Earning',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t?.earnings30.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                          color     : Colors.white,
                          fontSize  : 22,
                          fontWeight: FontWeight.w700),
                    ),
                    if ((t?.earningsToNextTag ?? 0) > 0) ...[
                      SizedBox(height: FigmaSize.h(6)),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          children: [
                            TextSpan(
                                text:
                                    'Only ₹${t!.earningsToNextTag.toStringAsFixed(2)} to become '),
                            TextSpan(
                                text: next,
                                style: const TextStyle(
                                    color: _yellow,
                                    fontWeight: FontWeight.w600)),
                            const TextSpan(text: '!'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(width: FigmaSize.w(10)),
            Expanded(
              child: _cardWrapper(
                header: const Text('Loyal User Level',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t?.loyalLevel ?? 0}',
                      style: const TextStyle(
                          color     : Colors.white,
                          fontSize  : 22,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: FigmaSize.h(6)),
                    const Text('Loyal user level should be 1',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Eligibility Criteria ────────────────────────────────────────────────────
  Widget _eligibilityCard() {
    // Tag thresholds matching the screenshot
    // Rising Star: busy 7d>=210, busy 30d included; Top choice: >=300; Celebrity: >=390
    // Mandatory: 30d earning >50000, Loyal>=1, Chat/Call rating >4.7

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Eligibility Criteria',
            style: TextStyle(
                color     : Colors.white,
                fontSize  : 15,
                fontWeight: FontWeight.w700)),
        SizedBox(height: FigmaSize.h(10)),

        // Busy Time table
        _cardWrapper(
          header: null,
          child: Column(
            children: [
              // Header
              _criteriaRow(
                  ['Eligibility', 'Rising Star', 'Top choice', 'Celebrity'],
                  isHeader: true),
              Divider(height: 1, color: _border),
              _criteriaRowWidget(
                label: 'Busy Time\nLast 7 days\nLast 30 days',
                vals : ['>=210', '>=300', '>=390'],
              ),
            ],
          ),
        ),
        SizedBox(height: FigmaSize.h(12)),

        // Mandatory table
        _cardWrapper(
          header: const Text('Mandatory',
              style: TextStyle(
                  color     : Colors.white,
                  fontSize  : 14,
                  fontWeight: FontWeight.w600)),
          child: Column(
            children: [
              _criteriaRow(['30 days earning', '>50000', '>50000', '>50000']),
              Divider(height: 1, color: _border),
              _criteriaRow(['Loyal User', '1', '1', '1']),
              Divider(height: 1, color: _border),
              _criteriaRow(['Chat Rating', '>4.7', '>4.7', '>4.7']),
              Divider(height: 1, color: _border),
              _criteriaRow(['Call Rating', '>4.7', '>4.7', '>4.7']),
              Divider(height: 1, color: _border),
              _criteriaRow(['Tag', '', '', '']),
            ],
          ),
        ),
        SizedBox(height: FigmaSize.h(10)),
        const Text(
          '**Other internal parameters are also considered.',
          style: TextStyle(color: Colors.red, fontSize: 11),
        ),
      ],
    );
  }

  Widget _criteriaRow(List<String> cells, {bool isHeader = false}) => Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(
          children: cells.asMap().entries.map((e) {
            final isFirst = e.key == 0;
            return Expanded(
              flex: isFirst ? 3 : 2,
              child: Text(
                e.value,
                textAlign: isFirst ? TextAlign.left : TextAlign.center,
                style: TextStyle(
                  color     : isHeader
                      ? Colors.white
                      : (isFirst ? Colors.white70 : Colors.white),
                  fontSize  : 12,
                  fontWeight: isHeader || !isFirst
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _criteriaRowWidget(
      {required String label, required List<String> vals}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, height: 1.6)),
          ),
          ...vals.map((v) => Expanded(
                flex: 2,
                child: Text(v,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color     : Colors.white,
                        fontSize  : 12,
                        fontWeight: FontWeight.w600)),
              )),
        ],
      ),
    );
  }

  // ── Reusable card wrapper ──────────────────────────────────────────────────
  Widget _cardWrapper({Widget? header, required Widget child}) => Container(
        width     : double.infinity,
        padding   : EdgeInsets.all(FigmaSize.w(14)),
        decoration: BoxDecoration(
          color       : _card,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) ...[header, SizedBox(height: FigmaSize.h(10))],
            child,
          ],
        ),
      );
}