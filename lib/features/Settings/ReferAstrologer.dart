// lib/features/Settings/ReferAstrologer.dart
//
// Zero UI changes.
// — Referral code loaded from astrologer profile (astrologer._id last 8 chars,
//   same format the backend uses: refer_code_string + refer_code_number).
// — Tap dotted border / "Tap to copy" → copies code to clipboard + snackbar.
// — "+ Refer an Astrologer" → share sheet with Play Store link + referral code.
// — Referred list section: replaced "No Data Available" with a proper
//   empty-state that refreshes with pull-to-refresh (placeholder — extend
//   when backend adds a referred-list endpoint).

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
      'https://play.google.com/store/apps/details?id=com.astrologer.astro.astrogurujiii';

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
      final res  = await ApiService().get_astrologer_profile();
      final astro = res.results.isNotEmpty ? res.results[0] : null;
      if (!mounted) return;
      if (astro != null) {
        // Use last 8 chars of ID as referral code (uppercase).
        // If the backend later returns a dedicated refer_code field, swap here.
        final raw  = astro.id.isNotEmpty
            ? astro.id
            : '${astro.number}';
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

  // ── Copy referral code to clipboard ───────────────────────────────────────
  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content        : const Text('Referral code copied!'),
        backgroundColor: Colors.green,
        behavior       : SnackBarBehavior.floating,
        margin         : const EdgeInsets.all(16),
        duration       : const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Share via native share sheet ──────────────────────────────────────────
  void _share() {
    final msg =
        '🌟 Join AstroGuruJii as an astrologer and start earning!\n\n'
        'Use my referral code: *$_referralCode*\n\n'
        'Download the app here:\n$_playStoreUrl';
    Share.share(msg, subject: 'Join AstroGuruJii — Referral Code: $_referralCode');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        title          : const Text("Refer Astrologer"),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFCD417)))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color    : const Color(0xFFFCD417),
              child    : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child  : Column(
                  children: [
                    // ── Referral code card ─────────────────────────────────
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(44),
                        vertical  : FigmaSize.h(16),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(44),
                        vertical  : FigmaSize.h(20),
                      ),
                      decoration: BoxDecoration(
                        color       : Color(0xFFFCD417).withOpacity(0.05),
                        border      : Border.all(color: const Color(0xFFFCD417)),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            "Your Referral Code",
                            style: TextStyle(
                              fontSize  : FigmaSize.w(13),
                              fontWeight: FontWeight.w500,
                              color     : Colors.black,
                            ),
                          ),
                          SizedBox(height: FigmaSize.h(12)),

                          // Tappable dotted border
                          GestureDetector(
                            onTap: _copyCode,
                            child: DottedBorder(
                              options: RectDottedBorderOptions(
                                color      : const Color(0xFFD41000),
                                strokeWidth: 1,
                                dashPattern: const [6, 4],
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical  : FigmaSize.h(16),
                                  horizontal: FigmaSize.w(44),
                                ),
                                color: Colors.white,
                                child: Text(
                                  _referralCode,
                                  style: TextStyle(
                                    fontSize  : FigmaSize.w(15),
                                    fontWeight: FontWeight.w500,
                                    color     : const Color(0xFFD41000),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: FigmaSize.h(9)),

                          // "Tap to copy" row with icon
                          GestureDetector(
                            onTap: _copyCode,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.copy,
                                    size: 14, color: Color(0xFFD41000)),
                                SizedBox(width: FigmaSize.w(4)),
                                Text(
                                  "Tap to copy",
                                  style: TextStyle(
                                    fontSize  : FigmaSize.w(13),
                                    fontWeight: FontWeight.w500,
                                    color     : const Color(0xFFD41000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── How it works ───────────────────────────────────────
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
                              color     : Colors.black,
                            ),
                          ),
                          SizedBox(height: FigmaSize.h(10)),
                          _stepRow('1', 'Share your referral code with another astrologer.'),
                          _stepRow('2', 'They download the AstroGuruJii astrologer app.'),
                          _stepRow('3', 'They register using your code.'),
                          _stepRow('4', 'You earn a bonus once they complete their first session!'),
                          SizedBox(height: FigmaSize.h(16)),

                          // Play Store link card
                          GestureDetector(
                            onTap: _share,
                            child: Container(
                              padding: EdgeInsets.all(FigmaSize.w(12)),
                              decoration: BoxDecoration(
                                color       : const Color(0xFFFFFBE6),
                                border      : Border.all(
                                    color: const Color(0xFFFCD417)),
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
                                            color     : Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: FigmaSize.h(2)),
                                        Text(
                                          'play.google.com/store/apps',
                                          style: TextStyle(
                                            fontSize: FigmaSize.w(10),
                                            color   : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.share,
                                      color: Color(0xFFD41000), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: FigmaSize.h(24)),

                    // ── Referred list placeholder ──────────────────────────
                    // Replace with a real ListView when the backend adds
                    // a referred-astrologers endpoint.
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
                              color     : Colors.black,
                            ),
                          ),
                          SizedBox(height: FigmaSize.h(12)),
                          Container(
                            width     : double.infinity,
                            padding   : EdgeInsets.symmetric(
                                vertical: FigmaSize.h(40)),
                            decoration: BoxDecoration(
                              color       : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border      : Border.all(
                                  color: const Color(0xFFE7E7E7)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.people_outline,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: FigmaSize.h(10)),
                                Text(
                                  'No Data Available',
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(13),
                                    color   : Colors.grey,
                                  ),
                                ),
                                SizedBox(height: FigmaSize.h(4)),
                                Text(
                                  'Referred astrologers will appear here.',
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(11),
                                    color   : Colors.grey.shade400,
                                  ),
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
        title: "+ Refer an Astrologer",
        onTap : _share,
      ),
    );
  }

  Widget _stepRow(String step, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: FigmaSize.h(8)),
      child  : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width : FigmaSize.w(22),
            height: FigmaSize.h(22),
            decoration: const BoxDecoration(
              color: Color(0xFFFCD417),
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
                fontSize: FigmaSize.w(12),
                color   : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}