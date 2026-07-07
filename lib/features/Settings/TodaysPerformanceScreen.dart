// lib/features/Settings/TodaysPerformanceScreen.dart
// ── Matches all 3 screenshots exactly ─────────────────────────────────────────
// ── Tab 1 "My Performance": Profile Health, Availability, Loyal Conversion,
//                            Average Chat Rating, Average Call Rating
// ── Tab 2 "Earn Tag": Current Status, Eligibility Criteria table
// ── All data live from performance_dashboard API + profile API

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME CONSTANTS (dark, matches screenshots)
// ─────────────────────────────────────────────────────────────────────────────

const _bg     = Color(0xFF0E0E1A);
const _card   = Color(0xFF1A1A2E);
const _yellow = Color(0xFFFCD417);
const _red    = Color(0xFFD41000);
const _border = Color(0xFF2A2A45);
const _grey   = Color(0xFF8888AA);
const _green  = Color(0xFF27AE60);
const _blue   = Color(0xFF4A90D9);

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _HealthData {
  final int totalSessions, missedSessions, missedCalls, missedChats, loyalUsers;
  final double revenueLoss;
  const _HealthData({
    required this.totalSessions, required this.missedSessions,
    required this.revenueLoss, required this.missedCalls,
    required this.missedChats, required this.loyalUsers,
  });
  factory _HealthData.fromJson(Map<String, dynamic> j) => _HealthData(
    totalSessions : _i(j['total_sessions']),
    missedSessions: _i(j['missed_sessions']),
    revenueLoss   : _d(j['revenue_loss']),
    missedCalls   : _i(j['missed_calls']),
    missedChats   : _i(j['missed_chats']),
    loyalUsers    : _i(j['loyal_users']),
  );
  static int    _i(v) => int.tryParse(v?.toString() ?? '0') ?? 0;
  static double _d(v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

class _AvailData {
  final int todayAvail, week7Avail, days30Avail;
  final int todayBusy,  week7Busy,  days30Busy;
  const _AvailData({
    required this.todayAvail, required this.week7Avail, required this.days30Avail,
    required this.todayBusy,  required this.week7Busy,  required this.days30Busy,
  });
  factory _AvailData.fromJson(Map<String, dynamic> j) => _AvailData(
    todayAvail : _i(j['today_avail_mins']),
    week7Avail : _i(j['week7_avail_mins']),
    days30Avail: _i(j['days30_avail_mins']),
    todayBusy  : _i(j['today_busy_mins']),
    week7Busy  : _i(j['week7_busy_mins']),
    days30Busy : _i(j['days30_busy_mins']),
  );
  static int _i(v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

class _LoyalData {
  final double conversionPct;
  final int totalUsers, loyalUsers, loyalLevel;
  const _LoyalData({
    required this.conversionPct, required this.totalUsers,
    required this.loyalUsers,    required this.loyalLevel,
  });
  factory _LoyalData.fromJson(Map<String, dynamic> j) => _LoyalData(
    conversionPct: _d(j['conversion_pct']),
    totalUsers   : _i(j['total_users']),
    loyalUsers   : _i(j['loyal_users']),
    loyalLevel   : _i(j['loyal_level']),
  );
  String get label {
    if (conversionPct >= 25.5) return 'Good';
    if (conversionPct >= 17.0) return 'Average';
    return 'Low';
  }
  Color get labelColor {
    if (conversionPct >= 25.5) return _green;
    if (conversionPct >= 17.0) return _yellow;
    return _red;
  }
  static int    _i(v) => int.tryParse(v?.toString() ?? '0') ?? 0;
  static double _d(v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

class _TagData {
  final double busyMins7, busyMins30, earnings30;
  final int    loyalLevel, currentTag;
  final double chatRating, callRating;
  final double minsToNext, earningsToNext;
  const _TagData({
    required this.busyMins7,  required this.busyMins30,
    required this.earnings30, required this.loyalLevel,
    required this.currentTag, required this.chatRating,
    required this.callRating, required this.minsToNext,
    required this.earningsToNext,
  });
  factory _TagData.fromJson(Map<String, dynamic> j) => _TagData(
    busyMins7    : _d(j['busy_mins_7']),
    busyMins30   : _d(j['busy_mins_30']),
    earnings30   : _d(j['earnings_30']),
    loyalLevel   : _i(j['loyal_level']),
    currentTag   : _i(j['current_tag']),
    chatRating   : _d(j['chat_rating']),
    callRating   : _d(j['call_rating']),
    minsToNext   : _d(j['mins_to_next_tag']),
    earningsToNext: _d(j['earnings_to_next_tag']),
  );
  String get nextTagName {
    switch (currentTag) {
      case 0: return 'Rising Star';
      case 1: return 'Top Choice';
      case 2: return 'Celebrity';
      default: return '';
    }
  }
  static int    _i(v) => int.tryParse(v?.toString() ?? '0') ?? 0;
  static double _d(v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
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

  late final TabController _tab;
  final _client = ApiClient();

  Astrologer?  _astro;
  _HealthData? _health;
  _AvailData?  _avail;
  _LoyalData?  _loyal;
  _TagData?    _tag;
  bool         _loading = true;
  String?      _error;

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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService().get_astrologer_profile(),
        _client.post('astrologer_api/performance_dashboard', {}, isAuthRequired: true),
      ]);
      final profileRes = results[0] as AstrologerProfileResponse;
      final dashJson   = jsonDecode((results[1] as dynamic).body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _astro = profileRes.results.isNotEmpty ? profileRes.results.first : null;
        if (dashJson['result'] == true) {
          final d = dashJson['data'] as Map<String, dynamic>;
          _health = _HealthData.fromJson(d['health']       as Map<String, dynamic>? ?? {});
          _avail  = _AvailData.fromJson(d['availability']  as Map<String, dynamic>? ?? {});
          _loyal  = _LoyalData.fromJson(d['loyal']         as Map<String, dynamic>? ?? {});
          _tag    = _TagData.fromJson(d['tag']              as Map<String, dynamic>? ?? {});
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  // ── Derived ratings ────────────────────────────────────────────────────────
  double get _chatRating  => _tag?.chatRating ?? 0.0;
  double get _callRating  => _tag?.callRating ?? 0.0;

  String _today() => DateFormat('dd MMMM yyyy').format(DateTime.now());

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation      : 0,
        title: const Text('Performance Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        actions: [
          IconButton(
            icon     : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _yellow))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : Column(children: [
                  _ProfileHeader(astro: _astro, tag: _tag),
                  _TagProgressBar(currentTag: _tag?.currentTag ?? 0),
                  _TabBar(controller: _tab),
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      children: [_myPerfTab(), _earnTagTab()],
                    ),
                  ),
                ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — MY PERFORMANCE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _myPerfTab() => RefreshIndicator(
        onRefresh: _load,
        color    : _yellow,
        child    : ListView(
          padding : EdgeInsets.all(FigmaSize.w(14)),
          children: [
            _ProfileHealthCard(health: _health, today: _today()),
            SizedBox(height: FigmaSize.h(16)),
            _AvailabilityCard(avail: _avail),
            SizedBox(height: FigmaSize.h(16)),
            _LoyalConversionCard(loyal: _loyal),
            SizedBox(height: FigmaSize.h(16)),
            _RatingCard(
              label      : 'Average Chat Rating',
              rating     : _chatRating,
              description: 'Average Chat Rating is the average of ratings given by users on '
                           'paid (non-PO) chat orders over the last 90 days. It may increase '
                           'or decrease daily as the 90-day window keeps shifting. If a user '
                           'rates multiple times, only one rating is counted.',
            ),
            SizedBox(height: FigmaSize.h(16)),
            _RatingCard(
              label      : 'Average Call Rating',
              rating     : _callRating,
              description: 'Average Call Rating is the average of ratings given by users on '
                           'paid (non-PO) call orders over the last 90 days. It may increase '
                           'or decrease daily as the 90-day window keeps shifting. If a user '
                           'rates multiple times, only one rating is counted.',
            ),
            SizedBox(height: FigmaSize.h(24)),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — EARN TAG
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _earnTagTab() => RefreshIndicator(
        onRefresh: _load,
        color    : _yellow,
        child    : ListView(
          padding : EdgeInsets.all(FigmaSize.w(14)),
          children: [
            _CurrentStatusCard(tag: _tag),
            SizedBox(height: FigmaSize.h(16)),
            _EligibilityCard(),
            SizedBox(height: FigmaSize.h(24)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Astrologer? astro;
  final _TagData?   tag;
  const _ProfileHeader({required this.astro, required this.tag});

  @override
  Widget build(BuildContext context) {
    final name   = astro?.displayname ?? astro?.displayname ?? 'Astrologer';
    final img    = astro?.profileImg  ?? '';
    final online = (astro?.isChatOnline  ?? false) ||
                   (astro?.isVoiceOnline ?? false) ||
                   (astro?.isVideoOnline ?? false);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: FigmaSize.h(16)),
      child: Column(children: [
        // Avatar
        Stack(
          children: [
            Container(
              width : 76, height: 76,
              decoration: BoxDecoration(
                shape : BoxShape.circle,
                border: Border.all(color: _yellow, width: 2.5),
              ),
              child: ClipOval(
                child: img.isNotEmpty
                    ? Image.network(img, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.white, size: 40))
                    : const Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
        SizedBox(height: FigmaSize.h(10)),
        // Name + verified green dot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.w700,
                    color     : Colors.white)),
            SizedBox(width: FigmaSize.w(6)),
            Container(
              width : 18, height: 18,
              decoration: const BoxDecoration(
                  color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAG PROGRESS BAR (Rising Star → Top Choice → Celebrity)
// ─────────────────────────────────────────────────────────────────────────────

class _TagProgressBar extends StatelessWidget {
  final int currentTag; // 0=none, 1=Rising Star, 2=Top Choice, 3=Celebrity
  const _TagProgressBar({required this.currentTag});

  @override
  Widget build(BuildContext context) {
    const labels = ['Rising Star', 'Top choice', 'Celebrity'];
    // Progress value: tag 0 → 0.08, tag 1 → 0.33, tag 2 → 0.66, tag 3 → 1.0
    final progress = [0.08, 0.33, 0.66, 1.0][currentTag.clamp(0, 3)];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(20), vertical: FigmaSize.h(4)),
      child: Column(children: [
        // Bar with dots
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Track
            Container(
              height    : 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height    : 4,
                decoration: BoxDecoration(
                    color: _yellow, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Milestone dots at 33%, 66%, 100%
            ...List.generate(3, (i) {
              final frac  = [0.33, 0.66, 1.0][i];
              final done  = progress >= frac;
              return Align(
                alignment: Alignment(frac * 2 - 1, 0),
                child: Container(
                  width : 14, height: 14,
                  decoration: BoxDecoration(
                    color : done ? _yellow : _card,
                    shape : BoxShape.circle,
                    border: Border.all(
                        color: done ? _yellow : _grey, width: 2),
                  ),
                ),
              );
            }),
          ],
        ),
        SizedBox(height: FigmaSize.h(6)),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(l,
              style: const TextStyle(color: _grey, fontSize: 10))).toList(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
        color: _bg,
        child: TabBar(
          controller          : controller,
          labelColor          : Colors.white,
          unselectedLabelColor: _grey,
          indicatorColor      : _yellow,
          indicatorWeight     : 2.5,
          dividerColor        : _border,
          labelStyle          : const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400, fontSize: 14),
          tabs                : const [
            Tab(text: 'My Performance'),
            Tab(text: 'Earn Tag'),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        width     : double.infinity,
        padding   : padding ?? EdgeInsets.all(FigmaSize.w(14)),
        decoration: BoxDecoration(
          color       : _card,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: _border),
        ),
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY'S PROFILE HEALTH
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHealthCard extends StatelessWidget {
  final _HealthData? health;
  final String       today;
  const _ProfileHealthCard({required this.health, required this.today});

  @override
  Widget build(BuildContext context) {
    final h = health;
    final rows = [
      ['Total Sessions',                    '${h?.totalSessions  ?? 0}'],
      ['Missed Sessions',                   '${h?.missedSessions ?? 0}'],
      ['Revenue Loss from missed Sessions', '₹${h?.revenueLoss.toStringAsFixed(0) ?? 0}'],
      ['Missed Calls',                      '${h?.missedCalls    ?? 0}'],
      ['Missed Chats',                      '${h?.missedChats    ?? 0}'],
      ['Loyal Users',                       '${h?.loyalUsers     ?? 0}'],
    ];

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Today's Profile Health",
              style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border      : Border.all(color: _border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(today,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
      SizedBox(height: FigmaSize.h(12)),
      ...rows.asMap().entries.map((e) => Column(children: [
        if (e.key > 0) Divider(height: 1, color: _border),
        Padding(
          padding: EdgeInsets.symmetric(vertical: FigmaSize.h(11)),
          child: Row(children: [
            Expanded(
              child: Text(e.value[0],
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
            Text(e.value[1],
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ])).toList(),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY AVAILABILITY
// ─────────────────────────────────────────────────────────────────────────────

class _AvailabilityCard extends StatelessWidget {
  final _AvailData? avail;
  const _AvailabilityCard({required this.avail});

  @override
  Widget build(BuildContext context) {
    final a = avail;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('My Availability',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(12)),
      _row(['Availability', 'Today', 'Last 7 Days', 'Last 30 days'], isHeader: true),
      Divider(height: 1, color: _border),
      _row(['Available Mins',
        '${a?.todayAvail  ?? 0} mins',
        '${a?.week7Avail  ?? 0} mins',
        '${a?.days30Avail ?? 0} mins']),
      Divider(height: 1, color: _border),
      _row(['Busy Mins',
        '${a?.todayBusy  ?? 0} mins',
        '${a?.week7Busy  ?? 0} mins',
        '${a?.days30Busy ?? 0} mins']),
      Divider(height: 1, color: _border),
      Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
        child: Row(children: const [
          Expanded(child: Text('Check Last 30 Days Availability',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right, color: Colors.white70),
        ]),
      ),
    ]));
  }

  Widget _row(List<String> cells, {bool isHeader = false}) => Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(children: cells.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          return Expanded(
            flex: isFirst ? 3 : 2,
            child: Text(e.value,
                textAlign: isFirst ? TextAlign.left : TextAlign.center,
                style: TextStyle(
                  color     : isHeader ? Colors.white : Colors.white,
                  fontSize  : 12,
                  fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                )),
          );
        }).toList()),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOYAL USER CONVERSION
// ─────────────────────────────────────────────────────────────────────────────

class _LoyalConversionCard extends StatelessWidget {
  final _LoyalData? loyal;
  const _LoyalConversionCard({required this.loyal});

  @override
  Widget build(BuildContext context) {
    final l   = loyal;
    final pct = l?.conversionPct ?? 0.0;
    final lc  = l?.labelColor ?? _red;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Loyal User Conversion',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),
      Container(
        decoration: BoxDecoration(
          color       : _card,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: lc, width: 1.5),
        ),
        padding: EdgeInsets.all(FigmaSize.w(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('${pct.toStringAsFixed(1)} %',
                style: TextStyle(
                    color: _yellow, fontSize: FigmaSize.w(30), fontWeight: FontWeight.w700)),
            const Spacer(),
            // Label badge
            Container(
              padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  border: Border.all(color: lc), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.info_outline, color: lc, size: 13),
                SizedBox(width: FigmaSize.w(4)),
                Text(l?.label ?? 'Low',
                    style: TextStyle(color: lc, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ]),
          SizedBox(height: FigmaSize.h(10)),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value          : (pct / 100.0).clamp(0.0, 1.0),
              backgroundColor: _border,
              valueColor     : AlwaysStoppedAnimation<Color>(_yellow),
              minHeight      : 8,
            ),
          ),
          SizedBox(height: FigmaSize.h(4)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.0',   style: TextStyle(color: _grey, fontSize: 10)),
              Text('17.0',  style: TextStyle(color: _grey, fontSize: 10)),
              Text('25.5',  style: TextStyle(color: _grey, fontSize: 10)),
              Text('100.0', style: TextStyle(color: _grey, fontSize: 10)),
            ],
          ),
          SizedBox(height: FigmaSize.h(16)),
          // Stats row
          Row(children: [
            _stat('Total users',      '${l?.totalUsers  ?? 0}'),
            _divider(),
            _stat('Loyal Users',      '${l?.loyalUsers  ?? 0}'),
            _divider(),
            _stat('Loyal user level', '${l?.loyalLevel  ?? 0}'),
          ]),
        ]),
      ),
      SizedBox(height: FigmaSize.h(8)),
      Text(
        'Loyal user conversion means if Astrogurujii provides you with '
        '${l?.totalUsers ?? 500} new customers then how many of them became your loyal customers',
        style: const TextStyle(color: _grey, fontSize: 11, height: 1.5),
      ),
    ]);
  }

  Widget _stat(String label, String val) => Expanded(child: Column(children: [
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: _grey, fontSize: 11)),
        SizedBox(height: FigmaSize.h(4)),
        Text(val, style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ]));

  Widget _divider() => Container(
        width: 1, height: 36, color: _border,
        margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(6)));
}

// ─────────────────────────────────────────────────────────────────────────────
// AVERAGE RATING CARD  (Image 2 — chat & call)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final String label;
  final double rating;
  final String description;
  const _RatingCard({
    required this.label,
    required this.rating,
    required this.description,
  });

  String get _statusLabel {
    if (rating >= 4.75) return 'Excellent';
    if (rating >= 4.5)  return 'Good';
    return 'Need Improvement';
  }

  Color get _statusColor {
    if (rating >= 4.75) return _green;
    if (rating >= 4.5)  return _yellow;
    return _red;
  }

  Color get _barColor {
    if (rating >= 4.75) return _green;
    if (rating >= 4.5)  return _yellow;
    return _red;
  }

  Color get _borderColor => _statusColor;

  // Map 1.0–5.0 to 0.0–1.0
  double get _progress => ((rating - 1.0) / 4.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),
      Container(
        decoration: BoxDecoration(
          color       : _card,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: _borderColor, width: 1.5),
        ),
        padding: EdgeInsets.all(FigmaSize.w(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Large rating number
            Text(rating.toStringAsFixed(2),
                style: TextStyle(
                    color     : _statusColor,
                    fontSize  : FigmaSize.w(36),
                    fontWeight: FontWeight.w700)),
            SizedBox(width: FigmaSize.w(10)),
            // Stars
            Row(children: List.generate(5, (i) {
              final filled = i < rating.floor();
              final half   = !filled && i < rating.ceil() && (rating % 1) >= 0.5;
              return Icon(
                half ? Icons.star_half_rounded
                     : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
                color: Colors.amber,
                size : FigmaSize.w(22),
              );
            })),
            const Spacer(),
            // Status badge
            Container(
              padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  border: Border.all(color: _statusColor),
                  borderRadius: BorderRadius.circular(20),
                  color: _statusColor.withOpacity(0.1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _statusColor == _green ? Icons.check_circle_outline : Icons.info_outline,
                  color: _statusColor, size: 13),
                SizedBox(width: FigmaSize.w(4)),
                Text(_statusLabel,
                    style: TextStyle(
                        color: _statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ]),
          SizedBox(height: FigmaSize.h(12)),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value          : _progress,
              backgroundColor: _border,
              valueColor     : AlwaysStoppedAnimation<Color>(_barColor),
              minHeight      : 8,
            ),
          ),
          SizedBox(height: FigmaSize.h(4)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1.0',  style: TextStyle(color: _grey, fontSize: 10)),
              Text('4.5',  style: TextStyle(color: _grey, fontSize: 10)),
              Text('4.75', style: TextStyle(color: _grey, fontSize: 10)),
              Text('5.0',  style: TextStyle(color: _grey, fontSize: 10)),
            ],
          ),
        ]),
      ),
      SizedBox(height: FigmaSize.h(8)),
      Text(description,
          style: const TextStyle(color: _grey, fontSize: 11, height: 1.6)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CURRENT STATUS (Earn Tag tab)
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentStatusCard extends StatelessWidget {
  final _TagData? tag;
  const _CurrentStatusCard({required this.tag});

  @override
  Widget build(BuildContext context) {
    final t    = tag;
    final next = t?.nextTagName ?? 'Rising Star';
    final bm7  = t?.busyMins7.toStringAsFixed(0)   ?? '0';
    final bm30 = t?.busyMins30.toStringAsFixed(0)  ?? '0';
    final e30  = t?.earnings30.toStringAsFixed(2)  ?? '0.00';
    final ll   = '${t?.loyalLevel ?? 0}';
    final minsLeft = t?.minsToNext.toStringAsFixed(0) ?? '0';
    final earnLeft = t?.earningsToNext.toStringAsFixed(2) ?? '0.00';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Current Status',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),

      // Busy Minutes card
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Average Busy Minutes',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        SizedBox(height: FigmaSize.h(10)),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bm7, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(2)),
            const Text('Last 7 days', style: TextStyle(color: _grey, fontSize: 12)),
          ])),
          Container(width: 1, height: 44, color: _border,
              margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(14))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bm30, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(2)),
            const Text('Last 30 days', style: TextStyle(color: _grey, fontSize: 12)),
          ])),
        ]),
        SizedBox(height: FigmaSize.h(10)),
        if (next.isNotEmpty)
          RichText(text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
            children: [
              const TextSpan(text: 'Only '),
              TextSpan(text: '$minsLeft mins',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const TextSpan(text: ' more to become '),
              TextSpan(text: next,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const TextSpan(text: '!'),
            ],
          )),
      ])),

      SizedBox(height: FigmaSize.h(10)),

      // Earnings + Loyal Level row
      Row(children: [
        Expanded(
          child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Last 30 days Earning',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: FigmaSize.h(6)),
            Text(e30, style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(6)),
            if (next.isNotEmpty)
              RichText(text: TextSpan(
                style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
                children: [
                  const TextSpan(text: 'Only ₹'),
                  TextSpan(text: earnLeft,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' to become '),
                  TextSpan(text: next,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const TextSpan(text: '!'),
                ],
              )),
          ])),
        ),
        SizedBox(width: FigmaSize.w(10)),
        Expanded(
          child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Loyal User Level',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: FigmaSize.h(6)),
            Text(ll, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(6)),
            const Text('Loyal user level should be 1',
                style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4)),
          ])),
        ),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ELIGIBILITY CRITERIA TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Eligibility Criteria',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),

      // Busy Time table
      _Card(child: Column(children: [
        _tRow(['Eligibility', 'Rising Star', 'Top choice', 'Celebrity'], isHeader: true),
        Divider(height: 1, color: _border),
        _tRowMulti(
          label: 'Busy Time\nLast 7 days\nLast 30 days',
          vals : ['>=210', '>=300', '>=390'],
        ),
      ])),

      SizedBox(height: FigmaSize.h(12)),

      // Mandatory table
      _Card(child: Column(children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10, top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Mandatory',
                style: TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        _tRow(['30 days earning', '>50000', '>50000', '>50000']),
        Divider(height: 1, color: _border),
        _tRow(['Loyal User', '1', '1', '1']),
        Divider(height: 1, color: _border),
        _tRow(['Chat Rating', '>4.7', '>4.7', '>4.7']),
        Divider(height: 1, color: _border),
        _tRow(['Call Rating', '>4.7', '>4.7', '>4.7']),
        Divider(height: 1, color: _border),
        _tRow(['Tag', '', '', '']),
      ])),

      SizedBox(height: FigmaSize.h(8)),
      const Text(
        '**Other internal parameters are also considered.',
        style: TextStyle(color: _red, fontSize: 11, height: 1.5),
      ),
    ]);
  }

  Widget _tRow(List<String> cells, {bool isHeader = false}) => Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(children: cells.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          return Expanded(
            flex: isFirst ? 3 : 2,
            child: Text(
              e.value,
              textAlign: isFirst ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color     : isHeader ? Colors.white : (isFirst ? Colors.white70 : Colors.white),
                fontSize  : 12,
                fontWeight: isHeader || !isFirst ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList()),
      );

  Widget _tRowMulti({required String label, required List<String> vals}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              )),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(FigmaSize.w(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: _red, size: 44),
            SizedBox(height: FigmaSize.h(12)),
            Text(error,
                style: const TextStyle(color: _red),
                textAlign: TextAlign.center),
            SizedBox(height: FigmaSize.h(16)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon : const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _yellow, foregroundColor: Colors.black),
            ),
          ]),
        ),
      );
}