// lib/features/HomeScreen.dart
// ── Added: WillPopScope exit confirmation dialog ──────────────────────────────
// ── Zero other changes ────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/core/widgets/homeIconGrid.dart';
import 'package:astrologer_app/features/Settings/FeedbackCeoScreen.dart';
import 'package:astrologer_app/features/Settings/SupportScreen.dart';
import 'package:astrologer_app/features/Settings/TodaysPerformanceScreen.dart';
import 'package:astrologer_app/features/Settings/TrainingVideos.dart'
    show TrainingVideo, TrainingVideosScreen;
import 'package:astrologer_app/features/account/AstrologerSideDrawer.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/model/AstrogurujiiConfirmationModal.dart';
import 'package:astrologer_app/model/PerformanceModel.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

// =============================================================================
// HOME SCREEN
// =============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── profile ─────────────────────────────────────────────────────────────────
  Astrologer? _astro;
  bool        _loading = true;

  // ── online toggles ───────────────────────────────────────────────────────────
  bool _chatOn  = false;
  bool _voiceOn = false;
  bool _videoOn = false;

  // ── schedule-next subtitles ──────────────────────────────────────────────────
  String _chatSub  = 'Offline';
  String _voiceSub = 'Offline';
  String _videoSub = 'Offline';

  // ── emergency card ───────────────────────────────────────────────────────────
  bool _emgChat = false;
  bool _emgCall = false;

  // ── auto boost ───────────────────────────────────────────────────────────────
  bool _boostChat = false;
  bool _boostCall = false;

  // ── performance ──────────────────────────────────────────────────────────────
  PerfData _perf = PerfData.empty();

  String _fmtISO(String? iso) {
    if (iso == null || iso.isEmpty) return 'Offline';
    try {
      return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) { return iso; }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPerformance();
  }

  // ── API: profile ─────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    try {
      final res = await ApiService().get_astrologer_profile();
      if (!mounted) return;
      final a = res.results.isNotEmpty ? res.results[0] : null;
      setState(() {
        _astro   = a;
        _loading = false;
        _chatOn  = a?.isChatOnline  ?? false;
        _voiceOn = a?.isVoiceOnline ?? false;
        _videoOn = a?.isVideoOnline ?? false;
        _chatSub  = _chatOn  ? 'Online' : _fmtISO(a?.nextOnlineChat);
        _voiceSub = _voiceOn ? 'Online' : _fmtISO(a?.nextOnlineCall);
        _videoSub = _videoOn ? 'Online' : _fmtISO(a?.nextOnlineVideo);
        _emgChat   = a?.isEmergencyChat ?? false;
        _emgCall   = a?.isEmergencyCall ?? false;
        _boostChat = a?.autoBoostChat   ?? false;
        _boostCall = a?.autoBoostCall   ?? false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('HomeScreen _loadProfile: $e');
    }
  }

  // ── API: performance ─────────────────────────────────────────────────────────
  Future<void> _loadPerformance() async {
    try {
      final res  = await ApiClient().post(
        'astrologer_api/today_performance', {},
        isAuthRequired: true,
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      final ok   = json['result'] == true || json['status'] == true;
      final data = json['data'] as Map<String, dynamic>?;
      if (ok && data != null) setState(() => _perf = PerfData.fromJson(data));
    } catch (e) {
      debugPrint('HomeScreen _loadPerformance: $e');
    }
  }

  // ── API: set online status ────────────────────────────────────────────────────
  Future<void> _setOnline(String type, bool on) async {
    final field = type == 'chat'  ? 'is_chat_online'
                : type == 'voice' ? 'is_voice_online'
                :                   'is_video_online';
    try {
      await ApiClient().post(
        'astrologer_api/profile_status_update',
        {field: on ? 'on' : 'off'},
        isAuthRequired: true,
      );
    } catch (e) { debugPrint('_setOnline error: $e'); }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────────
  void _confirm({
    required String    title,
    required String    msg,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    showDialog(
      context           : context,
      barrierDismissible: false,
      builder: (_) => DivinConfirmDialog(
        title  : title,
        message: msg,
        onYes  : () { Navigator.pop(context); onYes(); },
        onNo   : () { Navigator.pop(context); onNo();  },
      ),
    );
  }

  // ── Exit confirmation ─────────────────────────────────────────────────────────
 Future<bool> _onWillPop() async {
  final c = context.colors;

  final exit = await showDialog<bool>(
    context           : context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      backgroundColor: c.surface,
      insetPadding   : const EdgeInsets.symmetric(
          horizontal: 32, vertical: 24),
      clipBehavior   : Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Yellow header ──────────────────────────────────────────
          Container(
            width  : double.infinity,
            padding: EdgeInsets.fromLTRB(
                FigmaSize.w(24), FigmaSize.h(28),
                FigmaSize.w(24), FigmaSize.h(20)),
            color  : AppTheme.primaryYellow,
            child  : Column(children: [
              Container(
                width : FigmaSize.w(64),
                height: FigmaSize.w(64),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.35),
                ),
                child: const Icon(Icons.exit_to_app_rounded,
                    color: Colors.black87, size: 30),
              ),
              SizedBox(height: FigmaSize.h(12)),
              const Text(
                'Leaving so soon?',
                style: TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.w600,
                    color     : Colors.black87),
              ),
              SizedBox(height: FigmaSize.h(4)),
              Text(
                "You haven't seen everything yet!",
                style: TextStyle(
                    fontSize: 13,
                    color   : Colors.black.withOpacity(0.55)),
              ),
            ]),
          ),

          // ── Reasons to stay ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                FigmaSize.w(20), FigmaSize.h(16),
                FigmaSize.w(20), FigmaSize.h(4)),
            child: Container(
              decoration: BoxDecoration(
                color       : context.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(FigmaSize.w(14)),
              child: Column(children: [
                _exitReason(
                  icon : Icons.bar_chart_rounded,
                  title: 'Check your performance',
                  sub  : "Today's earnings & sessions are waiting",
                  c    : c,
                ),
                SizedBox(height: FigmaSize.h(12)),
                _exitReason(
                  icon : Icons.star_outline_rounded,
                  title: 'Stay online, earn more',
                  sub  : "You're just minutes from your daily target",
                  c    : c,
                ),
                SizedBox(height: FigmaSize.h(12)),
                _exitReason(
                  icon : Icons.notifications_none_rounded,
                  title: "Don't miss new requests",
                  sub  : 'Users may be trying to reach you right now',
                  c    : c,
                ),
              ]),
            ),
          ),

          // ── Buttons ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                FigmaSize.w(20), FigmaSize.h(16),
                FigmaSize.w(20), FigmaSize.h(24)),
            child: Column(children: [
              // Explore — primary yellow
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon : const Icon(Icons.rocket_launch_outlined,
                      color: Colors.black87, size: 18),
                  label: const Text('Explore the app',
                      style: TextStyle(
                          color     : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize  : 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: EdgeInsets.symmetric(
                        vertical: FigmaSize.h(14)),
                    shape  : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(height: FigmaSize.h(10)),
              // Exit — ghost
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: FigmaSize.h(13)),
                    side   : BorderSide(color: c.border),
                    shape  : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Exit app',
                      style: TextStyle(
                          color   : c.subText,
                          fontSize: 14)),
                ),
              ),
            ]),
          ),
        ],
      ),
    ),
  );

  if (exit == true) {
    SystemNavigator.pop();
    return true;
  }
  return false;
}

// Helper for exit reason rows
Widget _exitReason({
  required IconData icon,
  required String   title,
  required String   sub,
  required AppColors c,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppTheme.accentRed, size: 20),
      SizedBox(width: FigmaSize.w(10)),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color     : c.text)),
          SizedBox(height: FigmaSize.h(2)),
          Text(sub,
              style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  color   : c.subText)),
        ],
      )),
    ],
  );
}

  // ══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _buildAppBar(c),
        body  : RefreshIndicator(
          onRefresh: () async {
            await _loadProfile();
            await _loadPerformance();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child  : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── 1. Chat / Call / Video toggles ──────────────────────────
                _toggleCard(c),

                // ── 2. Services label + icon grid ────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                      left  : FigmaSize.w(16),
                      top   : FigmaSize.h(10),
                      bottom: FigmaSize.h(6)),
                  child: Text('Services',
                      style: TextStyle(
                          fontSize  : FigmaSize.w(13),
                          fontWeight: FontWeight.w500,
                          color     : const Color(0xFFD41000))),
                ),
                const HomeIconGrid(),
                SizedBox(height: FigmaSize.h(12)),

                // ── 3. Online for Emergency ──────────────────────────────────
                _EmergencyCard(
                  chatEnabled  : _emgChat,
                  callEnabled  : _emgCall,
                  chatRate     : '₹${((_astro?.perMinChat ?? 0) * 1.5)
                      .toStringAsFixed(1)}/min',
                  callRate     : '₹${((_astro?.perMinVoiceCall ?? 0) * 1.5)
                      .toStringAsFixed(1)}/min',
                  onChatChanged: (v) {
                    setState(() => _emgChat = v);
                    ApiClient().post(
                      'astrologer_api/update_emergency_status',
                      {'type': 'chat', 'status': v ? 'on' : 'off'},
                      isAuthRequired: true,
                    );
                  },
                  onCallChanged: (v) {
                    setState(() => _emgCall = v);
                    ApiClient().post(
                      'astrologer_api/update_emergency_status',
                      {'type': 'call', 'status': v ? 'on' : 'off'},
                      isAuthRequired: true,
                    );
                  },
                ),
                SizedBox(height: FigmaSize.h(12)),

                // ── 4. Today's Progress ──────────────────────────────────────
                _ProgressCard(
                  perf      : _perf,
                  onCheckTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TodayPerformanceScreen())),
                ),
                SizedBox(height: FigmaSize.h(12)),

                // ── 5. CEO Feedback banner ───────────────────────────────────
                _CeoBanner(c: c),
                SizedBox(height: FigmaSize.h(12)),

                // ── 6. Auto Boost ────────────────────────────────────────────
                _AutoBoostCard(
                  chatEnabled  : _boostChat,
                  callEnabled  : _boostCall,
                  onChatChanged: (v) => setState(() => _boostChat = v),
                  onCallChanged: (v) => setState(() => _boostCall = v),
                  c            : c,
                ),
                SizedBox(height: FigmaSize.h(12)),

                // ── 7. Training Videos ───────────────────────────────────────
                _TrainingVideosSection(c: c),
                SizedBox(height: FigmaSize.h(32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(AppColors c) => AppBar(
    backgroundColor          : AppTheme.primaryColor,
    foregroundColor          : Colors.black,
    automaticallyImplyLeading: false,
    elevation                : 0,
    title: Row(children: [
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AstrologerProfileScreen())),
        child: CircleAvatar(
          radius         : FigmaSize.w(18),
          backgroundColor: AppTheme.primaryColor,
          backgroundImage: (_astro?.profileImg.isNotEmpty == true)
              ? NetworkImage(_astro!.profileImg) : null,
          child: (_astro?.profileImg.isNotEmpty != true)
              ? const Icon(Icons.person, color: Colors.white, size: 20)
              : null,
        ),
      ),
      SizedBox(width: FigmaSize.w(10)),
      Expanded(
        child: Text(
          _astro?.displayname ?? '',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]),
    actions: [
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => WalletScreen())),
        child: SvgPicture.asset('assets/images/walllet.svg',
            width: FigmaSize.w(20), height: FigmaSize.h(20)),
      ),
      SizedBox(width: FigmaSize.w(16)),
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AstrogurujiiSupportScreen())),
        child: SvgPicture.asset('assets/images/assistant.svg',
            width: FigmaSize.w(24), height: FigmaSize.h(24)),
      ),
      SizedBox(width: FigmaSize.w(16)),
    ],
  );

  // ── Toggle card ──────────────────────────────────────────────────────────────
  Widget _toggleCard(AppColors c) => Container(
    margin    : EdgeInsets.symmetric(
        horizontal: FigmaSize.w(10), vertical: FigmaSize.h(12)),
    padding   : EdgeInsets.symmetric(
        horizontal: FigmaSize.w(12), vertical: FigmaSize.h(14)),
    decoration: BoxDecoration(
      color       : c.toggleBg,
      borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      border      : Border.all(color: c.border),
    ),
    child: Column(children: [

      // CHAT
      _serviceRow(
        c       : c,
        label   : 'Chat',
        subtitle: _chatSub,
        rate    : '₹ ${_astro?.perMinChat ?? 0}/min',
        value   : _chatOn,
        onChanged: (v) {
          if (v) {
            _confirm(
              title: 'Enable Chat',
              msg  : 'Are you sure you want to go online for chat?',
              onYes: () {
                setState(() { _chatOn = true; _chatSub = 'Online'; });
                _setOnline('chat', true);
              },
              onNo: () => setState(() => _chatOn = false),
            );
          } else {
            setState(() => _chatOn = false);
            _setOnline('chat', false);
            ScheduleNextOnlineModal.show(context,
              serviceType: 'chat',
              onScheduled: (dt) => setState(() =>
                  _chatSub = DateFormat('dd MMM, hh:mm a').format(dt)));
          }
        },
        onBreak: () => TakeBreakModal.show(context,
            serviceType   : 'chat',
            onBreakStarted: () => setState(() => _chatOn = false)),
      ),

      Divider(height: FigmaSize.h(24), color: c.border),

      // CALL
      _serviceRow(
        c       : c,
        label   : 'Call',
        subtitle: _voiceSub,
        rate    : '₹ ${_astro?.perMinVoiceCall ?? 0}/min',
        value   : _voiceOn,
        onChanged: (v) {
          if (v) {
            _confirm(
              title: 'Enable Call',
              msg  : 'Are you sure you want to go online for call?',
              onYes: () {
                setState(() { _voiceOn = true; _voiceSub = 'Online'; });
                _setOnline('voice', true);
              },
              onNo: () => setState(() => _voiceOn = false),
            );
          } else {
            setState(() => _voiceOn = false);
            _setOnline('voice', false);
            ScheduleNextOnlineModal.show(context,
              serviceType: 'call',
              onScheduled: (dt) => setState(() =>
                  _voiceSub = DateFormat('dd MMM, hh:mm a').format(dt)));
          }
        },
        onBreak: () => TakeBreakModal.show(context,
            serviceType   : 'call',
            onBreakStarted: () => setState(() => _voiceOn = false)),
      ),

      Divider(height: FigmaSize.h(24), color: c.border),

      // VIDEO
      _serviceRow(
        c       : c,
        label   : 'Video Call',
        subtitle: _videoSub,
        rate    : '₹ ${_astro?.perMinVideoCall ?? 0}/min',
        value   : _videoOn,
        onChanged: (v) {
          if (v) {
            _confirm(
              title: 'Enable Video',
              msg  : 'Are you sure you want to go online for video call?',
              onYes: () {
                setState(() { _videoOn = true; _videoSub = 'Online'; });
                _setOnline('video', true);
              },
              onNo: () => setState(() => _videoOn = false),
            );
          } else {
            setState(() => _videoOn = false);
            _setOnline('video', false);
            ScheduleNextOnlineModal.show(context,
              serviceType: 'video',
              onScheduled: (dt) => setState(() =>
                  _videoSub = DateFormat('dd MMM, hh:mm a').format(dt)));
          }
        },
        onBreak: () => TakeBreakModal.show(context,
            serviceType   : 'video',
            onBreakStarted: () => setState(() => _videoOn = false)),
      ),
    ]),
  );

  // ── Single service row ───────────────────────────────────────────────────────
  Widget _serviceRow({
    required AppColors c,
    required String    label,
    required String    subtitle,
    required String    rate,
    required bool      value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onBreak,
  }) {
    final isDark = c.bg.computeLuminance() < 0.08;

    final badgeBg = value
        ? (isDark ? const Color(0xFF1A3D2A) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0));

    final badgeBorder = value
        ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF81C784))
        : (isDark ? const Color(0xFF888888) : const Color(0xFFCCCCCC));

    final badgeText = value
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF757575));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize  : FigmaSize.w(15),
                    fontWeight: FontWeight.bold,
                    color     : c.text)),
            SizedBox(height: FigmaSize.h(4)),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(6),
                  vertical  : FigmaSize.h(2)),
              decoration: BoxDecoration(
                color       : badgeBg,
                borderRadius: BorderRadius.circular(6),
                border      : Border.all(color: badgeBorder, width: 1),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                    fontSize  : FigmaSize.w(11),
                    fontWeight: FontWeight.w500,
                    color     : badgeText),
              ),
            ),
          ],
        )),
        GestureDetector(
          onLongPress: onBreak,
          child: CustomToggleSwitch(value: value, onChanged: onChanged),
        ),
        SizedBox(width: FigmaSize.w(10)),
        SizedBox(
          width: FigmaSize.w(88),
          child: Text(rate,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize  : FigmaSize.w(12),
                  fontWeight: FontWeight.bold,
                  color     : c.text)),
        ),
      ],
    );
  }
}

// =============================================================================
// WIDGET: Online for Emergency
// =============================================================================
class _EmergencyCard extends StatelessWidget {
  final bool   chatEnabled, callEnabled;
  final String chatRate, callRate;
  final ValueChanged<bool> onChatChanged, onCallChanged;
  const _EmergencyCard({
    required this.chatEnabled, required this.callEnabled,
    required this.chatRate,    required this.callRate,
    required this.onChatChanged, required this.onCallChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin    : EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(FigmaSize.w(12)),
        border      : Border.all(color: const Color(0xFFD41000), width: 1.2),
      ),
      child: Column(children: [

        // red header
        Container(
          padding   : EdgeInsets.symmetric(
              horizontal: FigmaSize.w(14), vertical: FigmaSize.h(10)),
          decoration: BoxDecoration(
            color       : const Color(0xFFD41000),
            borderRadius: BorderRadius.only(
              topLeft : Radius.circular(FigmaSize.w(10)),
              topRight: Radius.circular(FigmaSize.w(10)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Online for Emergency!',
                  style: TextStyle(
                      color     : Colors.white,
                      fontSize  : FigmaSize.w(14),
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title  : const Text('Online for Emergency'),
                    content: const Text(
                        'When you are offline, users can still request a '
                        'session with you at 1.5× your normal rate.'),
                    actions: [TextButton(
                        onPressed: () => Navigator.pop(context),
                        child    : const Text('Got it'))],
                  ),
                ),
                child: Container(
                  width    : FigmaSize.w(22),
                  height   : FigmaSize.w(22),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('i',
                      style: TextStyle(
                          color     : const Color(0xFFD41000),
                          fontSize  : FigmaSize.w(13),
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // toggle rows
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(14), vertical: FigmaSize.h(10)),
          child: Column(children: [
            _row(c, 'Chat', chatRate, chatEnabled, onChatChanged),
            SizedBox(height: FigmaSize.h(10)),
            _row(c, 'Call', callRate, callEnabled, onCallChanged),
          ]),
        ),

        // 1.5× note
        Container(
          width    : double.infinity,
          padding  : EdgeInsets.symmetric(
              vertical: FigmaSize.h(8), horizontal: FigmaSize.w(14)),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF2A2500)
                : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.only(
              bottomLeft : Radius.circular(FigmaSize.w(10)),
              bottomRight: Radius.circular(FigmaSize.w(10)),
            ),
          ),
          child: Row(children: [
            const Text('💰', style: TextStyle(fontSize: 14)),
            SizedBox(width: FigmaSize.w(6)),
            Expanded(child: Text(
                'You will get 1.5x price during emergency session.',
                style: TextStyle(
                    fontSize: FigmaSize.w(12), color: c.text))),
          ]),
        ),
      ]),
    );
  }

  Widget _row(AppColors c, String label, String rate, bool value,
      ValueChanged<bool> cb) =>
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: FigmaSize.w(14), fontWeight: FontWeight.w600,
                    color: c.text)),
            Text(rate,
                style: TextStyle(
                    fontSize: FigmaSize.w(12), color: c.subText)),
          ],
        )),
        CustomToggleSwitch(value: value, onChanged: cb),
      ]);
}

// =============================================================================
// WIDGET: Schedule Next Online (bottom sheet)
// =============================================================================
class ScheduleNextOnlineModal extends StatefulWidget {
  final String serviceType;
  final ValueChanged<DateTime> onScheduled;
  const ScheduleNextOnlineModal(
      {super.key, required this.serviceType, required this.onScheduled});

  static Future<void> show(BuildContext context,
      {required String serviceType,
       required ValueChanged<DateTime> onScheduled}) =>
      showModalBottomSheet(
        context          : context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => ScheduleNextOnlineModal(
            serviceType: serviceType, onScheduled: onScheduled),
      );

  @override
  State<ScheduleNextOnlineModal> createState() =>
      _ScheduleNextOnlineModalState();
}

class _ScheduleNextOnlineModalState extends State<ScheduleNextOnlineModal> {
  DateTime  _date    = DateTime.now();
  DateTime? _picked;
  bool      _sameAll = false;
  bool      _busy    = false;

  static const _opts = [
    _P('After 10 Minutes', 10),
    _P('After 20 Minutes', 20),
    _P('After 30 Minutes', 30),
    _P('After 1 hour',     60),
    _P('After 2 hours',   120),
    _P('After 6 hours',   360),
  ];

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(16), vertical: FigmaSize.h(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: FigmaSize.w(40), height: FigmaSize.h(4),
              margin: EdgeInsets.only(bottom: FigmaSize.h(14)),
              decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('When will you come Online Next',
                style: TextStyle(
                    fontSize: FigmaSize.w(16), fontWeight: FontWeight.w600,
                    color: c.text),
                textAlign: TextAlign.center),
            SizedBox(height: FigmaSize.h(6)),
            Text(DateFormat('dd MMM, yyyy').format(_date),
                style: TextStyle(
                    fontSize: FigmaSize.w(22), fontWeight: FontWeight.bold,
                    color: c.text)),
            Text(_isToday(_date)
                    ? 'Today, ${DateFormat('EEE').format(_date)}'
                    : DateFormat('EEEE').format(_date),
                style: TextStyle(
                    fontSize: FigmaSize.w(13), color: c.subText)),
            SizedBox(height: FigmaSize.h(14)),
            Row(children: [
              _dateChip(c, 'Today',    DateTime.now()),
              SizedBox(width: FigmaSize.w(8)),
              _dateChip(c, 'Tomorrow',
                  DateTime.now().add(const Duration(days: 1))),
              SizedBox(width: FigmaSize.w(8)),
              _customDateChip(c, context),
            ]),
            SizedBox(height: FigmaSize.h(14)),
            GridView.builder(
              shrinkWrap  : true,
              physics     : const NeverScrollableScrollPhysics(),
              itemCount   : _opts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 3.6,
                  mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemBuilder: (_, i) {
                final o   = _opts[i];
                final sel = _picked != null &&
                    (_picked!.difference(DateTime.now()).inMinutes - o.mins)
                        .abs() < 2;
                return GestureDetector(
                  onTap: () => setState(() =>
                      _picked = DateTime.now()
                          .add(Duration(minutes: o.mins))),
                  child: Container(
                    alignment : Alignment.center,
                    decoration: BoxDecoration(
                      color       : sel
                          ? const Color(0xFFD41000).withOpacity(0.08)
                          : c.surface,
                      border      : Border.all(
                          color: sel
                              ? const Color(0xFFD41000) : c.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(o.label,
                        style: TextStyle(
                          fontSize  : FigmaSize.w(13),
                          fontWeight: sel
                              ? FontWeight.w600 : FontWeight.normal,
                          color     : sel
                              ? const Color(0xFFD41000) : c.text,
                        )),
                  ),
                );
              },
            ),
            SizedBox(height: FigmaSize.h(12)),
            GestureDetector(
              onTap: () => setState(() => _sameAll = !_sameAll),
              child: Row(children: [
                Checkbox(
                  value      : _sameAll,
                  onChanged  : (v) =>
                      setState(() => _sameAll = v ?? false),
                  activeColor: const Color(0xFFD41000),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                Text('Same for Chat/Call',
                    style: TextStyle(
                        fontSize: FigmaSize.w(14), color: c.text)),
              ]),
            ),
            SizedBox(height: FigmaSize.h(12)),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _pickTime,
                child: const Text('Choose Time'),
              )),
              SizedBox(width: FigmaSize.w(12)),
              Expanded(child: ElevatedButton(
                onPressed: _picked == null || _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit'),
              )),
            ]),
            SizedBox(height: FigmaSize.h(12)),
          ]),
        ),
      ),
    );
  }

  Widget _dateChip(AppColors c, String label, DateTime date) {
    final sel = _date.day == date.day && _date.month == date.month
        && _date.year == date.year;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _date = date; _picked = null; }),
      child: Container(
        alignment : Alignment.center,
        padding   : EdgeInsets.symmetric(vertical: FigmaSize.h(8)),
        decoration: BoxDecoration(
          color       : sel ? const Color(0xFF1565C0) : c.surface,
          border      : Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color     : sel ? Colors.white : c.text,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                fontSize  : FigmaSize.w(13))),
      ),
    ));
  }

  Widget _customDateChip(AppColors c, BuildContext context) =>
      Expanded(child: GestureDetector(
        onTap: () async {
          final p = await showDatePicker(
              context    : context,
              initialDate: DateTime.now(),
              firstDate  : DateTime.now(),
              lastDate   : DateTime.now().add(const Duration(days: 30)));
          if (p != null) setState(() { _date = p; _picked = null; });
        },
        child: Container(
          alignment : Alignment.center,
          padding   : EdgeInsets.symmetric(vertical: FigmaSize.h(8)),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(8)),
          child: Text('Select Date',
              style: TextStyle(
                  fontSize: FigmaSize.w(13), color: c.text)),
        ),
      ));

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() => _picked = DateTime(
          _date.year, _date.month, _date.day, t.hour, t.minute));
    }
  }

  Future<void> _submit() async {
    if (_picked == null) return;
    setState(() => _busy = true);
    try {
      await ApiClient().post(
        'astrologer_api/schedule_next_online',
        {
          'type'         : widget.serviceType,
          'scheduled_time': _picked!.toIso8601String(),
          'same_for_all' : _sameAll,
        },
        isAuthRequired: true,
      );
      widget.onScheduled(_picked!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _P {
  final String label;
  final int    mins;
  const _P(this.label, this.mins);
}

// =============================================================================
// WIDGET: Take a Break dialog
// =============================================================================
class TakeBreakModal extends StatefulWidget {
  final String serviceType;
  final VoidCallback onBreakStarted;
  const TakeBreakModal(
      {super.key, required this.serviceType, required this.onBreakStarted});

  static Future<void> show(BuildContext context,
      {required String serviceType,
       required VoidCallback onBreakStarted}) =>
      showDialog(
        context: context,
        builder: (_) => TakeBreakModal(
            serviceType: serviceType, onBreakStarted: onBreakStarted),
      );

  @override
  State<TakeBreakModal> createState() => _TakeBreakModalState();
}

class _TakeBreakModalState extends State<TakeBreakModal> {
  int?  _mins;
  bool  _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: c.surface,
      child: Padding(
        padding: EdgeInsets.all(FigmaSize.w(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close, size: 22, color: c.subText),
            )),
          Text('Take a break',
              style: TextStyle(
                  fontSize: FigmaSize.w(17), fontWeight: FontWeight.bold,
                  color: c.text)),
          SizedBox(height: FigmaSize.h(12)),
          Container(
            width : FigmaSize.w(60), height: FigmaSize.w(60),
            decoration: BoxDecoration(
              shape : BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFD41000).withOpacity(0.4), width: 3)),
            alignment: Alignment.center,
            child: Icon(Icons.access_time,
                color: const Color(0xFFD41000), size: FigmaSize.w(32)),
          ),
          SizedBox(height: FigmaSize.h(12)),
          Text(
            'Are you sure you want to schedule a break?\nPlease select the duration',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: FigmaSize.w(13), color: c.subText),
          ),
          SizedBox(height: FigmaSize.h(14)),
          Row(children: [
            _chip(c, 5),
            SizedBox(width: FigmaSize.w(12)),
            _chip(c, 10),
          ]),
          SizedBox(height: FigmaSize.h(16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mins == null || _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(AppColors c, int m) {
    final sel = _mins == m;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _mins = m),
      child: Container(
        alignment : Alignment.center,
        padding   : EdgeInsets.symmetric(vertical: FigmaSize.h(13)),
        decoration: BoxDecoration(
          color       : sel
              ? const Color(0xFFD41000).withOpacity(0.08) : c.surface,
          border      : Border.all(
              color: sel ? const Color(0xFFD41000) : c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$m minutes',
            style: TextStyle(
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                color     : sel ? const Color(0xFFD41000) : c.text,
                fontSize  : FigmaSize.w(14))),
      ),
    ));
  }

  Future<void> _submit() async {
    if (_mins == null) return;
    setState(() => _busy = true);
    try {
      await ApiClient().post(
        'astrologer_api/take_break',
        {'type': widget.serviceType, 'duration_minutes': _mins},
        isAuthRequired: true,
      );
      widget.onBreakStarted();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// =============================================================================
// WIDGET: Today's Progress
// =============================================================================
class _ProgressCard extends StatelessWidget {
  final PerfData     perf;
  final VoidCallback onCheckTap;
  const _ProgressCard({required this.perf, required this.onCheckTap});

  @override
  Widget build(BuildContext context) {
    final c   = context.colors;
    final msg = perf.progress >= 1.0
        ? 'Target Completed! 🎉'
        : 'Only ${perf.remainingStr} left to complete your 14 hours online target.';

    return Container(
      margin    : EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      padding   : EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
        border      : Border.all(color: c.border),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Progress",
                style: TextStyle(
                    fontSize  : FigmaSize.w(15),
                    fontWeight: FontWeight.w600,
                    color     : const Color(0xFFD41000))),
            SizedBox(height: FigmaSize.h(6)),
            Text(msg,
                style: TextStyle(
                    fontSize: FigmaSize.w(12), color: c.subText)),
            SizedBox(height: FigmaSize.h(12)),
            GestureDetector(
              onTap: onCheckTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(14),
                    vertical  : FigmaSize.h(8)),
                decoration: BoxDecoration(
                  color       : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Check Performance',
                    style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.w600,
                        color     : Colors.black)),
              ),
            ),
          ],
        )),
        SizedBox(width: FigmaSize.w(14)),
        SizedBox(
          width : FigmaSize.w(90),
          height: FigmaSize.h(90),
          child : Stack(alignment: Alignment.center, children: [
            SizedBox(
              width : FigmaSize.w(90),
              height: FigmaSize.h(90),
              child : CircularProgressIndicator(
                value          : perf.progress,
                strokeWidth    : 7,
                backgroundColor: c.border,
                valueColor     : AlwaysStoppedAnimation<Color>(
                  perf.progress >= 1.0
                      ? Colors.green : AppTheme.primaryColor,
                ),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(perf.onlineTimeStr,
                  style: TextStyle(
                      fontSize  : FigmaSize.w(13),
                      fontWeight: FontWeight.bold,
                      color     : c.text)),
              Text(perf.centerLabel,
                  style: TextStyle(
                      fontSize: FigmaSize.w(9), color: c.subText),
                  textAlign: TextAlign.center),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// =============================================================================
// WIDGET: CEO Feedback Banner
// =============================================================================
class _CeoBanner extends StatelessWidget {
  final AppColors c;
  const _CeoBanner({required this.c});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => FeedbackCeoScreen())),
    child: Container(
      width  : double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16), vertical: FigmaSize.h(14)),
      color: context.isDark
          ? const Color(0xFF2A2500)
          : const Color(0xFFFEF8D9),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.feedback_outlined,
                  color: Color(0xFFD41000), size: 20),
              SizedBox(width: FigmaSize.w(8)),
              Text('Feedback to the CEO Office!',
                  style: TextStyle(
                      fontSize  : FigmaSize.w(14),
                      fontWeight: FontWeight.w500,
                      color     : c.text)),
            ]),
            SizedBox(height: FigmaSize.h(4)),
            Text('Please share your honest feedback to help us improve',
                style: TextStyle(
                    fontSize: FigmaSize.w(12), color: c.subText)),
          ],
        )),
        Icon(Icons.chevron_right, color: c.subText),
      ]),
    ),
  );
}

// =============================================================================
// WIDGET: Auto Boost
// =============================================================================
class _AutoBoostCard extends StatelessWidget {
  final bool chatEnabled, callEnabled;
  final ValueChanged<bool> onChatChanged, onCallChanged;
  final AppColors c;
  const _AutoBoostCard({
    required this.chatEnabled, required this.callEnabled,
    required this.onChatChanged, required this.onCallChanged,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin    : EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
    padding   : EdgeInsets.all(FigmaSize.w(16)),
    decoration: BoxDecoration(
      color       : c.surface,
      borderRadius: BorderRadius.circular(FigmaSize.w(10)),
      border      : Border.all(color: c.border),
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Auto Boost Your Profile',
            style: TextStyle(
                fontSize  : FigmaSize.w(15),
                fontWeight: FontWeight.w600,
                color     : c.text)),
        Row(children: [
          Icon(Icons.history,      color: c.subText, size: 20),
          SizedBox(width: FigmaSize.w(8)),
          Icon(Icons.info_outline, color: c.subText, size: 20),
        ]),
      ]),
      SizedBox(height: FigmaSize.h(14)),
      _boostRow('Chat', Icons.chat_bubble_outline, chatEnabled, onChatChanged),
      SizedBox(height: FigmaSize.h(12)),
      _boostRow('Call', Icons.call_outlined,        callEnabled, onCallChanged),
    ]),
  );

  Widget _boostRow(String label, IconData icon, bool value,
      ValueChanged<bool> cb) =>
      Row(children: [
        Container(
          width : FigmaSize.w(36), height: FigmaSize.h(36),
          decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Icon(icon,
              size : FigmaSize.w(18),
              color: const Color(0xFFD41000)),
        ),
        SizedBox(width: FigmaSize.w(12)),
        Expanded(child: Text(label,
            style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w500,
                color     : c.text))),
        CustomToggleSwitch(value: value, onChanged: cb),
      ]);
}

// =============================================================================
// WIDGET: Training Videos
// =============================================================================
class _TrainingVideosSection extends StatefulWidget {
  final AppColors c;
  const _TrainingVideosSection({required this.c});
  @override
  State<_TrainingVideosSection> createState() =>
      _TrainingVideosSectionState();
}

class _TrainingVideosSectionState extends State<_TrainingVideosSection> {
  List<TrainingVideo> _videos  = [];
  bool                _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res  = await ApiClient().post(
          'astrologer_api/training_videos', {},
          isAuthRequired: true);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      final ok   = json['result'] == true || json['status'] == true;
      final list = json['data'] as List<dynamic>? ?? [];
      if (ok && list.isNotEmpty) {
        setState(() {
          _videos  = list.map((e) =>
              TrainingVideo.fromJson(e as Map<String, dynamic>)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(TrainingVideo v) async {
    final uri = Uri.parse(v.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _videos.isEmpty) return const SizedBox.shrink();
    final c = widget.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(Icons.play_circle_outline,
                  color: Color(0xFFD41000), size: 22),
              SizedBox(width: FigmaSize.w(6)),
              Text('Training Videos',
                  style: TextStyle(
                      fontSize  : FigmaSize.w(15),
                      fontWeight: FontWeight.w600,
                      color     : c.text)),
            ]),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const TrainingVideosScreen())),
              child: Text('View All',
                  style: TextStyle(
                      fontSize  : FigmaSize.w(14),
                      color     : const Color(0xFFD41000),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
      SizedBox(height: FigmaSize.h(10)),
      SizedBox(
        height: FigmaSize.h(160),
        child : ListView.separated(
          scrollDirection : Axis.horizontal,
          padding         : EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
          itemCount       : _videos.length,
          separatorBuilder: (_, __) => SizedBox(width: FigmaSize.w(12)),
          itemBuilder: (_, i) {
            final v = _videos[i];
            return GestureDetector(
              onTap: () => _open(v),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FigmaSize.w(10)),
                child: Stack(alignment: Alignment.center, children: [
                  Image.network(
                    v.autoThumbnail,
                    width : FigmaSize.w(160),
                    height: FigmaSize.h(160),
                    fit   : BoxFit.cover,
                    loadingBuilder: (_, child, prog) => prog == null
                        ? child
                        : Container(
                            width : FigmaSize.w(160),
                            height: FigmaSize.h(160),
                            color : c.toggleBg,
                            child : const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFCD417),
                                    strokeWidth: 2))),
                    errorBuilder: (_, __, ___) => Container(
                        width : FigmaSize.w(160),
                        height: FigmaSize.h(160),
                        color : c.toggleBg,
                        child : const Icon(Icons.video_library,
                            color: Colors.grey, size: 40)),
                  ),
                  Container(
                    width : FigmaSize.w(160),
                    height: FigmaSize.h(160),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end  : Alignment.topCenter)),
                  ),
                  Icon(Icons.play_circle_filled,
                      color: Colors.white.withOpacity(0.9),
                      size : FigmaSize.w(40)),
                  Positioned(
                    bottom: FigmaSize.h(8),
                    left  : FigmaSize.w(8),
                    right : FigmaSize.w(8),
                    child : Text(v.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color     : Colors.white,
                            fontSize  : FigmaSize.w(10),
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}