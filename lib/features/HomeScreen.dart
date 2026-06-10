import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/constants/LoyalUserFeedbackComponent.dart';
import 'package:astrologer_app/core/constants/PaidSessionWithUsers.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/core/widgets/homeIconGrid.dart';
import 'package:astrologer_app/features/Settings/FeedbackCeoScreen.dart';
import 'package:astrologer_app/features/Settings/ImmprtantNoticeScreen.dart';
import 'package:astrologer_app/features/Settings/MainSettingScreen.dart';
import 'package:astrologer_app/features/Settings/SupportScreen.dart';
import 'package:astrologer_app/features/Settings/TodaysPerformanceScreen.dart';
import 'package:astrologer_app/features/Settings/TrainingVideos.dart';
import 'package:astrologer_app/features/Settings/notificationScreen.dart';
import 'package:astrologer_app/features/account/AstrologerSideDrawer.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/features/modal/LanguageModal.dart';
import 'package:astrologer_app/model/AstrogurujiiConfirmationModal.dart';
import 'package:astrologer_app/model/PerformanceModel.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Astrologer? astrologerData;
  bool isLoading = true;
  bool chatEnabled = false;
  bool voiceEnabled = false;
  bool videoEnabled = false;

  // ── NEW state for added sections ──────────────────────────────────────────
  bool emergencyChatEnabled = true;
  bool emergencyCallEnabled = false;
  bool autoBoostChat = true;
  bool autoBoostCall = true;

  PerfData _perf = PerfData.empty();
 
  @override
  void initState() {
    super.initState();
    fetchAstrologerProfile();
    _loadPerformance();
  }


  void fetchAstrologerProfile() async {
    try {
      var response = await ApiService().get_astrologer_profile();

      setState(() {
        astrologerData = response.results.isNotEmpty
            ? response.results[0]
            : null;
        chatEnabled = astrologerData?.isChatEnabled ?? false;
        voiceEnabled = astrologerData?.isVoiceCallEnabled ?? false;
        videoEnabled = astrologerData?.isVideoCallEnabled ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Exception: $e");
    }
  }

Future<void> _loadPerformance() async {
    try {
      final client = ApiClient();
      final res    = await client.post(
        'astrologer_api/today_performance', {},
        isAuthRequired: true,
      );
      final json = jsonDecode(res.body);
      if (!mounted) return;
      if (json['result'] == true) {
        setState(() => _perf = PerfData.fromJson(
            json['data'] as Map<String, dynamic>));
      }
    } catch (_) {
      // silently keep empty defaults — non-critical card
    }
  }
  bool _isSwitched = false;
  void _showLanguagePopup(BuildContext context) {
    showDialog(context: context, builder: (context) => const LanguagePopup());
  }

  void _confirmToggle({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DivinConfirmDialog(
        title: title,
        message: message,
        onYes: () {
          Navigator.pop(context);
          onConfirm();
        },
        onNo: () {
          Navigator.pop(context);
          onCancel();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return isLoading
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            appBar: AppBar(
              foregroundColor: Colors.black,
              backgroundColor: AppTheme.primaryColor,
              actions: [
                SVGIconHome(
                  "assets/images/walllet.svg",
                  FigmaSize.h(20),
                  FigmaSize.w(20),
                  Colors.black,
                  () {},
                ),
                SizedBox(width: FigmaSize.w(20)),
                SVGIconHome(
                  "assets/images/assistant.svg",
                  FigmaSize.h(35),
                  FigmaSize.w(35),
                  Colors.black,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AstrogurujiiSupportScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(width: FigmaSize.w(20)),
              ],
              automaticallyImplyLeading: false,
              title: Container(
  child: Row(
    children: [
      SizedBox(width: FigmaSize.w(20)),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AstrologerProfileScreen(),
            ),
          );
        },
        child: CircleAvatar(
          radius: FigmaSize.w(18),
          backgroundColor: const Color(0xFFFCD417),
          backgroundImage: (astrologerData?.profileImg != null &&
                  astrologerData!.profileImg.isNotEmpty)
              ? NetworkImage(astrologerData!.profileImg)
              : null,
          child: (astrologerData?.profileImg == null ||
                  astrologerData!.profileImg.isEmpty)
              ? const Icon(Icons.person, color: Colors.white, size: 20)
              : null,
        ),
      ),
                  ],
                ),
              ),
              elevation: 1,
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Container(
  margin: EdgeInsets.symmetric(
    horizontal: FigmaSize.w(10),
    vertical  : FigmaSize.h(16),
  ),
  padding: EdgeInsets.symmetric(
    horizontal: FigmaSize.w(12),
    vertical  : FigmaSize.h(16),
  ),
  decoration: BoxDecoration(
    color       : const Color(0xFFF3F3F3),
    borderRadius: BorderRadius.circular(FigmaSize.w(10)),
    border      : Border.all(color: const Color(0x0A000000), width: 1),
  ),
  child: Column(
    children: [
 
      // ── CHAT ──────────────────────────────────────────────────────────────
      _serviceRow(
        label   : "Chat",
        subtitle: "Aug, 21 07:30 PM",
        rate    : "₹ ${astrologerData?.perMinChat ?? 0} /min",
        value   : chatEnabled,
        onChanged: (newValue) {
          if (newValue) {
            _confirmToggle(
              title   : "Enable Chat",
              message : "Are you sure you want to go online for chat?",
              onConfirm: () {
                setState(() => chatEnabled = true);
                ApiService().updateAvailableStatus(isChat: true);
              },
              onCancel: () => setState(() => chatEnabled = false),
            );
          } else {
            setState(() => chatEnabled = false);
            ApiService().updateAvailableStatus(isChat: false);
          }
        },
      ),
 
      const Divider(height: 24, color: Color(0xFFE0E0E0)),
 
      // ── CALL ──────────────────────────────────────────────────────────────
      _serviceRow(
        label   : "Call",
        subtitle: "Aug, 21 07:09 PM",
        rate    : "₹ ${astrologerData?.perMinVoiceCall ?? 0} /min",
        value   : voiceEnabled,
        onChanged: (newValue) {
          if (newValue) {
            _confirmToggle(
              title   : "Enable Call",
              message : "Are you sure you want to go online for voice call?",
              onConfirm: () {
                setState(() => voiceEnabled = true);
                ApiService().updateAvailableStatus(isVoiceCall: true);
              },
              onCancel: () => setState(() => voiceEnabled = false),
            );
          } else {
            setState(() => voiceEnabled = false);
            ApiService().updateAvailableStatus(isVoiceCall: false);
          }
        },
      ),
 
      const Divider(height: 24, color: Color(0xFFE0E0E0)),
 
      // ── VIDEO CALL ────────────────────────────────────────────────────────
      _serviceRow(
        label   : "Video Call",
        subtitle: "Offline",
        rate    : "₹ ${astrologerData?.perMinVideoCall ?? 0} /min",
        value   : videoEnabled,
        onChanged: (newValue) {
          if (newValue) {
            _confirmToggle(
              title   : "Enable Video Call",
              message : "Are you sure you want to go online for video call?",
              onConfirm: () {
                setState(() => videoEnabled = true);
                ApiService().updateAvailableStatus(isVideoCall: true);
              },
              onCancel: () => setState(() => videoEnabled = false),
            );
          } else {
            setState(() => videoEnabled = false);
            ApiService().updateAvailableStatus(isVideoCall: false);
          }
        },
      ),
 
    ],
  ),
),
 Padding(
                    padding: EdgeInsets.only(
                      bottom: FigmaSize.h(10),
                      left: FigmaSize.w(23),
                    ),
                    child: Text(
                      "Services",
                      style: TextStyle(
                        fontSize: FigmaSize.w(13),
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD41000),
                      ),
                    ),
                  ),
                  HomeIconGrid(),

                  // Paidsessionwithusers(),

                  // ── NEW: Offline For Emergency ─────────────────────────────
                  _OfflineEmergencyCard(
                    chatEnabled: emergencyChatEnabled,
                    callEnabled: emergencyCallEnabled,
                    onChatChanged: (v) =>
                        setState(() => emergencyChatEnabled = v),
                    onCallChanged: (v) =>
                        setState(() => emergencyCallEnabled = v),
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── NEW: Today's Progress ──────────────────────────────────
                 _TodaysProgressCard(
                    perf: _perf,
                    onCheckTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TodayPerformanceScreen()),
                    ),
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── NEW: Feedback to CEO Office ────────────────────────────
                  _CeoBanner(),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── NEW: Auto Boost Your Profile ───────────────────────────
                  _AutoBoostCard(
                    chatEnabled: autoBoostChat,
                    callEnabled: autoBoostCall,
                    onChatChanged: (v) => setState(() => autoBoostChat = v),
                    onCallChanged: (v) => setState(() => autoBoostCall = v),
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── NEW: Training Videos ───────────────────────────────────
                  TrainingVideosSection(),

                  SizedBox(height: FigmaSize.h(24)),
                ],
              ),
            ),
          );
  }
  Widget _serviceRow({
  required String label,
  required String subtitle,
  required String rate,
  required bool   value,
  required ValueChanged<bool> onChanged,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
 
      // LEFT — label + subtitle  (takes all remaining space)
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize  : FigmaSize.w(15),
                color     : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: FigmaSize.h(4)),
            Text(
              subtitle,
              style: TextStyle(
                fontSize  : FigmaSize.w(12),
                fontWeight: FontWeight.w500,
                color     : const Color(0xFF343434),
              ),
            ),
          ],
        ),
      ),
 
      // CENTRE — toggle (fixed, doesn't stretch)
      CustomToggleSwitch(value: value, onChanged: onChanged),
 
      SizedBox(width: FigmaSize.w(10)),
 
      // RIGHT — rate text (fixed width so all three rows align perfectly)
      SizedBox(
        width: FigmaSize.w(90),
        child: Text(
          rate,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize  : FigmaSize.w(13),
            color     : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
 
    ],
  );
}


  Widget SVGIconHome(
    String iconPath,
    double height,
    double width,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(iconPath),
      ),
    );
  }
}

// =============================================================================
// NEW WIDGETS — added below, original HomeScreen code above is unchanged
// =============================================================================

// ── Offline For Emergency ─────────────────────────────────────────────────────

class _OfflineEmergencyCard extends StatelessWidget {
  final bool chatEnabled;
  final bool callEnabled;
  final ValueChanged<bool> onChatChanged;
  final ValueChanged<bool> onCallChanged;

  const _OfflineEmergencyCard({
    required this.chatEnabled,
    required this.callEnabled,
    required this.onChatChanged,
    required this.onCallChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      padding: EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
        border: Border.all(color: const Color(0xFFFCD417), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Offline For Emergency",
                style: TextStyle(
                  fontSize: FigmaSize.w(14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD41000),
                ),
              ),
              Container(
                width: FigmaSize.w(20),
                height: FigmaSize.h(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFD41000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: FigmaSize.w(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(14)),
          _emergencyRow(
            label: "Chat",
            price: "₹ 8.0 /min",
            value: chatEnabled,
            onChanged: onChatChanged,
          ),
          SizedBox(height: FigmaSize.h(12)),
          _emergencyRow(
            label: "Call",
            price: "₹ 12.0 /min",
            value: callEnabled,
            onChanged: onCallChanged,
          ),
        ],
      ),
    );
  }

  

  Widget _emergencyRow({
    required String label,
    required String price,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: FigmaSize.w(14),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: FigmaSize.h(2)),
            Text(
              price,
              style: TextStyle(
                fontSize: FigmaSize.w(13),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        CustomToggleSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ── Today's Progress ──────────────────────────────────────────────────────────

class _TodaysProgressCard extends StatelessWidget {
  final PerfData   perf;
  final VoidCallback onCheckTap;
 
  const _TodaysProgressCard({
    required this.perf,
    required this.onCheckTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final remaining = perf.progress >= 1.0
        ? 'Target Completed! 🎉'
        : 'Only ${perf.remainingStr} Left To Complete Your 14 Hours Online Target.';
 
    return Container(
      margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      padding: EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
        border      : Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          // ── Left side ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontSize  : FigmaSize.w(15),
                    fontWeight: FontWeight.w600,
                    color     : const Color(0xFFD41000),
                  ),
                ),
                SizedBox(height: FigmaSize.h(6)),
                Text(
                  remaining,
                  style: TextStyle(
                    fontSize: FigmaSize.w(12),
                    color   : const Color(0xFF898989),
                  ),
                ),
                SizedBox(height: FigmaSize.h(14)),
                GestureDetector(
                  onTap: onCheckTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(16),
                      vertical  : FigmaSize.h(8),
                    ),
                    decoration: BoxDecoration(
                      color       : const Color(0xFFFCD417),
                      borderRadius: BorderRadius.circular(FigmaSize.w(6)),
                    ),
                    child: Text(
                      "Check Performance",
                      style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.w600,
                        color     : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
 
          SizedBox(width: FigmaSize.w(16)),
 
          // ── Right side — circular progress ──────────────────────────────
          SizedBox(
            width : FigmaSize.w(90),
            height: FigmaSize.h(90),
            child : Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width : FigmaSize.w(90),
                  height: FigmaSize.h(90),
                  child : CircularProgressIndicator(
                    value          : perf.progress,
                    strokeWidth    : 6,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor     : AlwaysStoppedAnimation<Color>(
                      perf.progress >= 1.0
                          ? Colors.green
                          : const Color(0xFFD41000),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      perf.onlineTimeStr,
                      style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.bold,
                        color     : Colors.black,
                      ),
                    ),
                    Text(
                      perf.centerLabel,
                      style: TextStyle(
                        fontSize: FigmaSize.w(10),
                        color   : const Color(0xFF898989),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ── Feedback to CEO Office ────────────────────────────────────────────────────

class _CeoBanner extends StatelessWidget {
  const _CeoBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackCeoScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: FigmaSize.h(15),
          horizontal: FigmaSize.w(18),
        ),
        decoration: const BoxDecoration(color: Color(0xFFFEF8D9)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.feedback_outlined,
                        color: Color(0xFFD41000),
                        size: 20,
                      ),
                      SizedBox(width: FigmaSize.w(8)),
                      Text(
                        "Feedback to the CEO Office!",
                        style: TextStyle(
                          fontSize: FigmaSize.w(14),
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FigmaSize.h(6)),
                  Text(
                    "Please share your honest feedback to help us Improve",
                    style: TextStyle(
                      fontSize: FigmaSize.w(12),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF898989),
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset("assets/images/right_arrow.svg"),
          ],
        ),
      ),
    );
  }
}

// ── Auto Boost Your Profile ───────────────────────────────────────────────────

class _AutoBoostCard extends StatelessWidget {
  final bool chatEnabled;
  final bool callEnabled;
  final ValueChanged<bool> onChatChanged;
  final ValueChanged<bool> onCallChanged;

  const _AutoBoostCard({
    required this.chatEnabled,
    required this.callEnabled,
    required this.onChatChanged,
    required this.onCallChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      padding: EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Auto Boost Your Profile",
                style: TextStyle(
                  fontSize: FigmaSize.w(15),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.grey, size: 20),
                  SizedBox(width: FigmaSize.w(8)),
                  const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(16)),
          _boostRow(
            iconPath: "assets/images/chat.svg",
            label: "Chat",
            value: chatEnabled,
            onChanged: onChatChanged,
          ),
          SizedBox(height: FigmaSize.h(14)),
          _boostRow(
            iconPath: "assets/images/phone.svg",
            label: "Call",
            value: callEnabled,
            onChanged: onCallChanged,
          ),
        ],
      ),
    );
  }

  Widget _boostRow({
    required String iconPath,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: FigmaSize.w(36),
          height: FigmaSize.h(36),
          decoration: BoxDecoration(
            color: const Color(0xFFFCD417).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              iconPath,
              width: FigmaSize.w(18),
              height: FigmaSize.h(18),
            ),
          ),
        ),
        SizedBox(width: FigmaSize.w(12)),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: FigmaSize.w(14),
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        CustomToggleSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ── Training Videos ───────────────────────────────────────────────────────────

class TrainingVideosSection extends StatefulWidget {
  const TrainingVideosSection({super.key});
 
  @override
  State<TrainingVideosSection> createState() => _TrainingVideosSectionState();
}
 
class _TrainingVideosSectionState extends State<TrainingVideosSection> {
  final _client = ApiClient();
 
  List<TrainingVideo> _videos = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    try {
      final res  = await _client.post(
        'astrologer_api/training_videos',
        {},
        isAuthRequired: true,
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (json['result'] == true) {
        setState(() {
          _videos  = (json['data'] as List)
              .map((e) => TrainingVideo.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // Open YouTube in external app
  Future<void> _open(TrainingVideo v) async {
    final uri = Uri.parse(v.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    // Hide entirely while loading or if no videos
    if (_loading || _videos.isEmpty) return const SizedBox.shrink();
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row (unchanged UI) ──────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: Color(0xFFD41000),
                    size : 22,
                  ),
                  SizedBox(width: FigmaSize.w(8)),
                  Text(
                    "Training Videos",
                    style: TextStyle(
                      fontSize  : FigmaSize.w(15),
                      fontWeight: FontWeight.w600,
                      color     : Colors.black,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingVideosScreen()),
                ),
                child: Text(
                  "View All",
                  style: TextStyle(
                    fontSize  : FigmaSize.w(14),
                    fontWeight: FontWeight.w500,
                    color     : const Color(0xFFD41000),
                  ),
                ),
              ),
            ],
          ),
        ),
 
        SizedBox(height: FigmaSize.h(12)),
 
        // ── Horizontal scroll list (same height/card as original) ──────────
        SizedBox(
          height: FigmaSize.h(160),
          child : ListView.separated(
            scrollDirection : Axis.horizontal,
            padding         : EdgeInsets.symmetric(
                horizontal: FigmaSize.w(16)),
            itemCount       : _videos.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: FigmaSize.w(12)),
            itemBuilder: (context, index) {
              final video = _videos[index];
              return GestureDetector(
                onTap: () => _open(video),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(FigmaSize.w(10)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Thumbnail (network) ──────────────────────────
                      Image.network(
                        video.autoThumbnail,
                        width    : FigmaSize.w(160),
                        height   : FigmaSize.h(160),
                        fit      : BoxFit.cover,
                        // Fallback while loading
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    width : FigmaSize.w(160),
                                    height: FigmaSize.h(160),
                                    color : const Color(0xFFF3F3F3),
                                    child : const Center(
                                      child: CircularProgressIndicator(
                                        color     : Color(0xFFFCD417),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                        // Fallback on error
                        errorBuilder: (_, __, ___) => Container(
                          width : FigmaSize.w(160),
                          height: FigmaSize.h(160),
                          color : const Color(0xFFF3F3F3),
                          child : const Icon(
                            Icons.video_library,
                            color: Colors.grey,
                            size : 40,
                          ),
                        ),
                      ),
 
                      // ── Gradient overlay (unchanged) ─────────────────
                      Container(
                        width     : FigmaSize.w(160),
                        height    : FigmaSize.h(160),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end  : Alignment.topCenter,
                          ),
                        ),
                      ),
 
                      // ── Play icon (unchanged) ────────────────────────
                      Icon(
                        Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.85),
                        size : FigmaSize.w(40),
                      ),
 
                      // ── Title at bottom (bonus — shows video title) ──
                      Positioned(
                        bottom: FigmaSize.h(8),
                        left  : FigmaSize.w(8),
                        right : FigmaSize.w(8),
                        child : Text(
                          video.title,
                          maxLines : 2,
                          overflow : TextOverflow.ellipsis,
                          style    : TextStyle(
                            color     : Colors.white,
                            fontSize  : FigmaSize.w(10),
                            fontWeight: FontWeight.w500,
                            height    : 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}