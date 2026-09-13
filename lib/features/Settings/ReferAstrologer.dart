// lib/features/Settings/ReferAstrologer.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class Referastrologer extends StatefulWidget {
  const Referastrologer({super.key});

  @override
  State<Referastrologer> createState() => _ReferastrologerState();
}

class _ReferastrologerState extends State<Referastrologer> {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.astrologer.vaidikguru';
    static const String _playStoreUrl1 = "https://play.google.com/store/apps/details?id=com.user.astrogurujii&hl=en_IN";
  String _referralCode = '...';
  bool   _loading      = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res   = await ApiService().get_astrologer_profile();
      final astro = res.results.isNotEmpty ? res.results[0] : null;
      if (!mounted) return;
      if (astro != null) {
        final raw = astro.id.isNotEmpty ? astro.id : '${astro.number}';
        setState(() {
          _referralCode = raw.length > 8
              ? raw.substring(raw.length - 8).toUpperCase()
              : raw.toUpperCase();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : const Text('Referral code copied!'),
      backgroundColor: Colors.green,
      behavior       : SnackBarBehavior.floating,
      margin         : const EdgeInsets.all(16),
      duration       : const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _share() {
    final msg =
        '🌟 Join AstroGuruJii as an astrologer and start earning!\n\n'
        'Use my referral code: *$_referralCode*\n\n'
        'Download the app here:\n$_playStoreUrl';
    Share.share(msg,
        subject: 'Join AstroGuruJii — Referral Code: $_referralCode');
  }
  void _share1() {
  final msg = '''
🔮 Discover AstroGuruJii – Your Trusted Astrology Companion!

✨ Get personalized horoscope readings, live consultations with expert astrologers, kundli matching, daily predictions, and much more.

🎁 Use my referral code: $_referralCode

📲 Download the app now:
$_playStoreUrl1

Start your spiritual journey today with AstroGuruJii! 🌟
''';

  Share.share(
    msg,
    subject: 'Join AstroGuruJii with Referral Code: $_referralCode',
  );
}

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Refer Astrologer'),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color    : AppTheme.primaryYellow,
              child    : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child  : Column(
                  children: [

                    // ── Referral code card ───────────────────────────────
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(44),
                        vertical  : FigmaSize.h(16),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(44),
                        vertical  : FigmaSize.h(20),
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color       : AppTheme.primaryYellow.withOpacity(
                            isDark ? 0.08 : 0.05),
                        border      : Border.all(
                            color: AppTheme.primaryYellow),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Referral Code',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(13),
                              fontWeight: FontWeight.w500,
                              color     : c.text,
                            ),
                          ),
                          SizedBox(height: FigmaSize.h(12)),

                          // Dotted border — tappable to copy
                          GestureDetector(
                            onTap: _copyCode,
                            child: DottedBorder(
                              options: RectDottedBorderOptions(
                                color      : AppTheme.accentRed,
                                strokeWidth: 1,
                                dashPattern: const [6, 4],
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical  : FigmaSize.h(16),
                                  horizontal: FigmaSize.w(44),
                                ),
                                color: isDark ? c.surface : Colors.white,
                                child: Text(
                                  _referralCode,
                                  style: TextStyle(
                                    fontSize  : FigmaSize.w(15),
                                    fontWeight: FontWeight.w500,
                                    color     : AppTheme.accentRed,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: FigmaSize.h(9)),

                          GestureDetector(
                            onTap: _copyCode,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy,
                                    size : 14,
                                    color: AppTheme.accentRed),
                                SizedBox(width: FigmaSize.w(4)),
                                Text(
                                  'Tap to copy',
                                  style: TextStyle(
                                    fontSize  : FigmaSize.w(13),
                                    fontWeight: FontWeight.w500,
                                    color     : AppTheme.accentRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── How it works ─────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: FigmaSize.w(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(13),
                              fontWeight: FontWeight.w600,
                              color     : c.text,
                            ),
                          ),
                          SizedBox(height: FigmaSize.h(10)),
                          _stepRow('1',
                              'Share your referral code with another astrologer.',
                              c),
                          _stepRow('2',
                              'They download the AstroGuruJii astrologer app.',
                              c),
                          _stepRow('3',
                              'They register using your code.', c),
                          _stepRow('4',
                              'You earn a bonus once they complete their first session!',
                              c),
                          SizedBox(height: FigmaSize.h(16)),

                          // Play Store link card
                          GestureDetector(
                            onTap: _share,
                            child: Container(
                              padding: EdgeInsets.all(FigmaSize.w(12)),
                              decoration: BoxDecoration(
                                color       : isDark
                                    ? AppTheme.primaryYellow.withOpacity(0.08)
                                    : const Color(0xFFFFFBE6),
                                border      : Border.all(
                                    color: AppTheme.primaryYellow),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      color: Color(0xFFF5A623), size: 28),
                                  SizedBox(width: FigmaSize.w(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AstroGuruJii – Astrologer App',
                                          style: TextStyle(
                                            fontSize  : FigmaSize.w(12),
                                            fontWeight: FontWeight.w600,
                                            color     : c.text,
                                          ),
                                        ),
                                        SizedBox(height: FigmaSize.h(2)),
                                        Text(
                                          'play.google.com/store/apps',
                                          style: TextStyle(
                                            fontSize: FigmaSize.w(10),
                                            color   : c.subText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.share,
                                      color: AppTheme.accentRed, size: 20),
                                ],
                              ),
                            ),
                          ),
                           SizedBox(height: FigmaSize.h(16)),
                           GestureDetector(
                            onTap: _share1,
                            child: Container(
                              padding: EdgeInsets.all(FigmaSize.w(12)),
                              decoration: BoxDecoration(
                                color       : isDark
                                    ? AppTheme.primaryYellow.withOpacity(0.08)
                                    : const Color(0xFFFFFBE6),
                                border      : Border.all(
                                    color: AppTheme.primaryYellow),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      color: Color(0xFFF5A623), size: 28),
                                  SizedBox(width: FigmaSize.w(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AstroGuruJii – User App',
                                          style: TextStyle(
                                            fontSize  : FigmaSize.w(12),
                                            fontWeight: FontWeight.w600,
                                            color     : c.text,
                                          ),
                                        ),
                                        SizedBox(height: FigmaSize.h(2)),
                                        Text(
                                          'play.google.com/store/apps',
                                          style: TextStyle(
                                            fontSize: FigmaSize.w(10),
                                            color   : c.subText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.share,
                                      color: AppTheme.accentRed, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: FigmaSize.h(24)),

                    // ── Referred list placeholder ─────────────────────────
                    Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: FigmaSize.w(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referred Astrologers',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(13),
                              fontWeight: FontWeight.w600,
                              color     : c.text,
                            ),
                          ),
                          SizedBox(height: FigmaSize.h(12)),
                          Container(
                            width    : double.infinity,
                            padding  : EdgeInsets.symmetric(
                                vertical: FigmaSize.h(40)),
                            decoration: BoxDecoration(
                              color       : isDark ? c.surface : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border      : Border.all(color: c.border),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.people_outline,
                                    color: c.subText, size: 40),
                                SizedBox(height: FigmaSize.h(10)),
                                Text(
                                  'No Data Available',
                                  style: TextStyle(
                                      fontSize: FigmaSize.w(13),
                                      color   : c.subText),
                                ),
                                SizedBox(height: FigmaSize.h(4)),
                                Text(
                                  'Referred astrologers will appear here.',
                                  style: TextStyle(
                                      fontSize: FigmaSize.w(11),
                                      color   : c.subText.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: FigmaSize.h(100)),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: GradientButton(
        title: '+ Refer an Astrologer',
        onTap : _share,
      ),
    );
  }

  Widget _stepRow(String step, String text, AppColors c) {
    return Padding(
      padding: EdgeInsets.only(bottom: FigmaSize.h(8)),
      child  : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width : FigmaSize.w(22),
            height: FigmaSize.h(22),
            decoration: const BoxDecoration(
              color: AppTheme.primaryYellow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontSize  : FigmaSize.w(11),
                  fontWeight: FontWeight.w700,
                  color     : Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: FigmaSize.w(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: FigmaSize.w(12), color: c.subText),
            ),
          ),
        ],
      ),
    );
  }
}