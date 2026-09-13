// lib/features/Settings/TodaysPerformanceScreen.dart
// ── Matches all 3 screenshots exactly ─────────────────────────────────────────
// ── Tab 1 "My Performance": Profile Health, Availability, Loyal Conversion,
//                            Average Chat Rating, Average Call Rating
// ── Tab 2 "Earn Tag": Current Status, Eligibility Criteria table
// ── All data live from performance_dashboard API + profile API
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes — only colors made theme-aware ─────────────────────────

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRAND / SEMANTIC CONSTANTS — not theme-dependent (same in dark & light)
// ─────────────────────────────────────────────────────────────────────────────
// bg/card/border/text/subText now come from context.colors (AppColors)
// yellow/red now come from AppTheme.primaryYellow / AppTheme.accentRed
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

  // Now parses the `today_performance` API response shape.
  factory _HealthData.fromJson(Map<String, dynamic> j) => _HealthData(
    totalSessions : _i(j['total_sessions']),
    missedSessions: _i(j['missed_total']),
    revenueLoss   : _d(j['revenue_loss_estimate']),
    // today_performance splits missed calls into audio + video
    missedCalls   : _i(j['missed_audio']) + _i(j['missed_video']),
    missedChats   : _i(j['missed_chat']),
    // today_performance has no loyal-users count; keep 0 here,
    // it's still shown correctly via the Loyal Conversion card (performance_dashboard).
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
  // AppTheme.* are static — safe to use here without a BuildContext.
  Color get labelColor {
    if (conversionPct >= 25.5) return _green;
    if (conversionPct >= 17.0) return AppTheme.primaryYellow;
    return AppTheme.accentRed;
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
  String? _todayLabel;

 Future<void> _load() async {
  if (!mounted) return;
  setState(() { _loading = true; _error = null; });
  try {
    final results = await Future.wait([
      ApiService().get_astrologer_profile(),
      _client.post('astrologer_api/performance_dashboard', {}, isAuthRequired: true),
      _client.post('astrologer_api/today_performance', {}, isAuthRequired: true),
    ]);
    final profileRes = results[0] as AstrologerProfileResponse;
    final dashJson   = jsonDecode((results[1] as dynamic).body) as Map<String, dynamic>;
    final todayJson  = jsonDecode((results[2] as dynamic).body) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _astro = profileRes.results.isNotEmpty ? profileRes.results.first : null;

      if (dashJson['result'] == true) {
        final d = dashJson['data'] as Map<String, dynamic>;
        _avail  = _AvailData.fromJson(d['availability']  as Map<String, dynamic>? ?? {});
        _loyal  = _LoyalData.fromJson(d['loyal']         as Map<String, dynamic>? ?? {});
        _tag    = _TagData.fromJson(d['tag']              as Map<String, dynamic>? ?? {});
      }

      // "Today's Profile Health" now sourced from today_performance,
      // which has the actual today-only breakdown (missed by reason, revenue loss, etc.)
      if (todayJson['result'] == true) {
        final td = todayJson['data'] as Map<String, dynamic>? ?? {};
        // carry loyal_users from the dashboard's loyal data since today_performance
        // doesn't track it, so the health card still shows a meaningful number.
        final merged = {
          ...td,
          'loyal_users': _loyal?.loyalUsers ?? 0,
        };
        _todayLabel = td['day_label']?.toString();
        _health = _HealthData.fromJson(merged);
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
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation      : 0,
        title: Text('Performance Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: c.text)),
        actions: [
          IconButton(
            icon     : Icon(Icons.refresh_rounded, color: c.text),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
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
        color    : AppTheme.primaryYellow,
        child    : ListView(
          padding : EdgeInsets.all(FigmaSize.w(14)),
          children: [
           _ProfileHealthCard(health: _health, today: _todayLabel ?? _today()),
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
        color    : AppTheme.primaryYellow,
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
    final c      = context.colors;
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
                border: Border.all(color: AppTheme.primaryYellow, width: 2.5),
              ),
              child: ClipOval(
                child: img.isNotEmpty
                    ? Image.network(img, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person, color: c.text, size: 40))
                    : Icon(Icons.person, color: c.text, size: 40),
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
                style: TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.w700,
                    color     : c.text)),
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
    final c = context.colors;
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
                  color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height    : 4,
                decoration: BoxDecoration(
                    color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(2)),
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
                    color : done ? AppTheme.primaryYellow : c.surface,
                    shape : BoxShape.circle,
                    border: Border.all(
                        color: done ? AppTheme.primaryYellow : c.subText, width: 2),
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
              style: TextStyle(color: c.subText, fontSize: 10))).toList(),
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
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.bg,
      child: TabBar(
        controller          : controller,
        labelColor          : c.text,
        unselectedLabelColor: c.subText,
        indicatorColor      : AppTheme.primaryYellow,
        indicatorWeight     : 2.5,
        dividerColor        : c.border,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width     : double.infinity,
      padding   : padding ?? EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(12),
        border      : Border.all(color: c.border),
      ),
      child: child,
    );
  }
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
    final c = context.colors;
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
          Text("Today's Profile Health",
              style: TextStyle(
                  color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border      : Border.all(color: c.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(today,
                style: TextStyle(color: c.subText, fontSize: 11)),
          ),
        ],
      ),
      SizedBox(height: FigmaSize.h(12)),
      ...rows.asMap().entries.map((e) => Column(children: [
        if (e.key > 0) Divider(height: 1, color: c.border),
        Padding(
          padding: EdgeInsets.symmetric(vertical: FigmaSize.h(11)),
          child: Row(children: [
            Expanded(
              child: Text(e.value[0],
                  style: TextStyle(color: c.subText, fontSize: 13))),
            Text(e.value[1],
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
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
    final c = context.colors;
    final a = avail;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('My Availability',
          style: TextStyle(
              color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(12)),
      _row(c, ['Availability', 'Today', 'Last 7 Days', 'Last 30 days'], isHeader: true),
      Divider(height: 1, color: c.border),
      _row(c, ['Available Mins',
        '${a?.todayAvail  ?? 0} mins',
        '${a?.week7Avail  ?? 0} mins',
        '${a?.days30Avail ?? 0} mins']),
      Divider(height: 1, color: c.border),
      _row(c, ['Busy Mins',
        '${a?.todayBusy  ?? 0} mins',
        '${a?.week7Busy  ?? 0} mins',
        '${a?.days30Busy ?? 0} mins']),
      Divider(height: 1, color: c.border),
      Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
        child: Row(children: [
          Expanded(child: Text('Check Last 30 Days Availability',
              style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right, color: c.subText),
        ]),
      ),
    ]));
  }

  Widget _row(AppColors c, List<String> cells, {bool isHeader = false}) => Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(children: cells.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          return Expanded(
            flex: isFirst ? 3 : 2,
            child: Text(e.value,
                textAlign: isFirst ? TextAlign.left : TextAlign.center,
                style: TextStyle(
                  color     : c.text,
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
    final c   = context.colors;
    final l   = loyal;
    final pct = l?.conversionPct ?? 0.0;
    final lc  = l?.labelColor ?? AppTheme.accentRed;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Loyal User Conversion',
          style: TextStyle(
              color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),
      Container(
        decoration: BoxDecoration(
          color       : c.surface,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: lc, width: 1.5),
        ),
        padding: EdgeInsets.all(FigmaSize.w(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('${pct.toStringAsFixed(1)} %',
                style: TextStyle(
                    color: AppTheme.primaryYellow, fontSize: FigmaSize.w(30), fontWeight: FontWeight.w700)),
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
              backgroundColor: c.border,
              valueColor     : AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
              minHeight      : 8,
            ),
          ),
          SizedBox(height: FigmaSize.h(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.0',   style: TextStyle(color: c.subText, fontSize: 10)),
              Text('17.0',  style: TextStyle(color: c.subText, fontSize: 10)),
              Text('25.5',  style: TextStyle(color: c.subText, fontSize: 10)),
              Text('100.0', style: TextStyle(color: c.subText, fontSize: 10)),
            ],
          ),
          SizedBox(height: FigmaSize.h(16)),
          // Stats row
          Row(children: [
            _stat(c, 'Total users',      '${l?.totalUsers  ?? 0}'),
            _divider(c),
            _stat(c, 'Loyal Users',      '${l?.loyalUsers  ?? 0}'),
            _divider(c),
            _stat(c, 'Loyal user level', '${l?.loyalLevel  ?? 0}'),
          ]),
        ]),
      ),
      SizedBox(height: FigmaSize.h(8)),
      Text(
        'Loyal user conversion means if Astrogurujii provides you with '
        '${l?.totalUsers ?? 500} new customers then how many of them became your loyal customers',
        style: TextStyle(color: c.subText, fontSize: 11, height: 1.5),
      ),
    ]);
  }

  Widget _stat(AppColors c, String label, String val) => Expanded(child: Column(children: [
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: c.subText, fontSize: 11)),
        SizedBox(height: FigmaSize.h(4)),
        Text(val, style: TextStyle(
            color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
      ]));

  Widget _divider(AppColors c) => Container(
        width: 1, height: 36, color: c.border,
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

  // AppTheme.* are static — safe to use here without a BuildContext.
  Color get _statusColor {
    if (rating >= 4.75) return _green;
    if (rating >= 4.5)  return AppTheme.primaryYellow;
    return AppTheme.accentRed;
  }

  Color get _barColor {
    if (rating >= 4.75) return _green;
    if (rating >= 4.5)  return AppTheme.primaryYellow;
    return AppTheme.accentRed;
  }

  Color get _borderColor => _statusColor;

  // Map 1.0–5.0 to 0.0–1.0
  double get _progress => ((rating - 1.0) / 4.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),
      Container(
        decoration: BoxDecoration(
          color       : c.surface,
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
              backgroundColor: c.border,
              valueColor     : AlwaysStoppedAnimation<Color>(_barColor),
              minHeight      : 8,
            ),
          ),
          SizedBox(height: FigmaSize.h(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1.0',  style: TextStyle(color: c.subText, fontSize: 10)),
              Text('4.5',  style: TextStyle(color: c.subText, fontSize: 10)),
              Text('4.75', style: TextStyle(color: c.subText, fontSize: 10)),
              Text('5.0',  style: TextStyle(color: c.subText, fontSize: 10)),
            ],
          ),
        ]),
      ),
      SizedBox(height: FigmaSize.h(8)),
      Text(description,
          style: TextStyle(color: c.subText, fontSize: 11, height: 1.6)),
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
    final c    = context.colors;
    final t    = tag;
    final next = t?.nextTagName ?? 'Rising Star';
    final bm7  = t?.busyMins7.toStringAsFixed(0)   ?? '0';
    final bm30 = t?.busyMins30.toStringAsFixed(0)  ?? '0';
    final e30  = t?.earnings30.toStringAsFixed(2)  ?? '0.00';
    final ll   = '${t?.loyalLevel ?? 0}';
    final minsLeft = t?.minsToNext.toStringAsFixed(0) ?? '0';
    final earnLeft = t?.earningsToNext.toStringAsFixed(2) ?? '0.00';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Current Status',
          style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),

      // Busy Minutes card
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Average Busy Minutes',
            style: TextStyle(color: c.subText, fontSize: 13)),
        SizedBox(height: FigmaSize.h(10)),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bm7, style: TextStyle(
                color: c.text, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(2)),
            Text('Last 7 days', style: TextStyle(color: c.subText, fontSize: 12)),
          ])),
          Container(width: 1, height: 44, color: c.border,
              margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(14))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bm30, style: TextStyle(
                color: c.text, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(2)),
            Text('Last 30 days', style: TextStyle(color: c.subText, fontSize: 12)),
          ])),
        ]),
        SizedBox(height: FigmaSize.h(10)),
        if (next.isNotEmpty)
          RichText(text: TextSpan(
            style: TextStyle(color: c.subText, fontSize: 12, height: 1.5),
            children: [
              const TextSpan(text: 'Only '),
              TextSpan(text: '$minsLeft mins',
                  style: TextStyle(
                      color: c.text, fontWeight: FontWeight.w600)),
              const TextSpan(text: ' more to become '),
              TextSpan(text: next,
                  style: TextStyle(
                      color: c.text, fontWeight: FontWeight.w700)),
              const TextSpan(text: '!'),
            ],
          )),
      ])),

      SizedBox(height: FigmaSize.h(10)),

      // Earnings + Loyal Level row
      Row(children: [
        Expanded(
          child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Last 30 days Earning',
                style: TextStyle(color: c.subText, fontSize: 12)),
            SizedBox(height: FigmaSize.h(6)),
            Text(e30, style: TextStyle(
                color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(6)),
            if (next.isNotEmpty)
              RichText(text: TextSpan(
                style: TextStyle(color: c.subText, fontSize: 11, height: 1.5),
                children: [
                  const TextSpan(text: 'Only ₹'),
                  TextSpan(text: earnLeft,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' to become '),
                  TextSpan(text: next,
                      style: TextStyle(
                          color: c.text, fontWeight: FontWeight.w700)),
                  const TextSpan(text: '!'),
                ],
              )),
          ])),
        ),
        SizedBox(width: FigmaSize.w(10)),
        Expanded(
          child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Loyal User Level',
                style: TextStyle(color: c.subText, fontSize: 12)),
            SizedBox(height: FigmaSize.h(6)),
            Text(ll, style: TextStyle(
                color: c.text, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: FigmaSize.h(6)),
            Text('Loyal user level should be 1',
                style: TextStyle(color: c.subText, fontSize: 11, height: 1.4)),
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
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Eligibility Criteria',
          style: TextStyle(
              color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: FigmaSize.h(10)),

      // Busy Time table
      _Card(child: Column(children: [
        _tRow(c, ['Eligibility', 'Rising Star', 'Top choice', 'Celebrity'], isHeader: true),
        Divider(height: 1, color: c.border),
        _tRowMulti(
          c,
          label: 'Busy Time\nLast 7 days\nLast 30 days',
          vals : ['>=210', '>=300', '>=390'],
        ),
      ])),

      SizedBox(height: FigmaSize.h(12)),

      // Mandatory table
      _Card(child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Mandatory',
                style: TextStyle(
                    color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        _tRow(c, ['30 days earning', '>50000', '>50000', '>50000']),
        Divider(height: 1, color: c.border),
        _tRow(c, ['Loyal User', '1', '1', '1']),
        Divider(height: 1, color: c.border),
        _tRow(c, ['Chat Rating', '>4.7', '>4.7', '>4.7']),
        Divider(height: 1, color: c.border),
        _tRow(c, ['Call Rating', '>4.7', '>4.7', '>4.7']),
        Divider(height: 1, color: c.border),
        _tRow(c, ['Tag', '', '', '']),
      ])),

      SizedBox(height: FigmaSize.h(8)),
      Text(
        '**Other internal parameters are also considered.',
        style: TextStyle(color: AppTheme.accentRed, fontSize: 11, height: 1.5),
      ),
    ]);
  }

  Widget _tRow(AppColors c, List<String> cells, {bool isHeader = false}) => Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(children: cells.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          return Expanded(
            flex: isFirst ? 3 : 2,
            child: Text(
              e.value,
              textAlign: isFirst ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color     : isHeader ? c.text : (isFirst ? c.subText : c.text),
                fontSize  : 12,
                fontWeight: isHeader || !isFirst ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList()),
      );

  Widget _tRowMulti(AppColors c, {required String label, required List<String> vals}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: TextStyle(
                    color: c.subText, fontSize: 12, height: 1.6)),
          ),
          ...vals.map((v) => Expanded(
                flex: 2,
                child: Text(v,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: c.text, fontSize: 12, fontWeight: FontWeight.w600)),
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
            Icon(Icons.error_outline, color: AppTheme.accentRed, size: 44),
            SizedBox(height: FigmaSize.h(12)),
            Text(error,
                style: TextStyle(color: AppTheme.accentRed),
                textAlign: TextAlign.center),
            SizedBox(height: FigmaSize.h(16)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon : const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
            ),
          ]),
        ),
      );
}