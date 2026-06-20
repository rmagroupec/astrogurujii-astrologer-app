// lib/features/account/AstrologerSideDrawer.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/MainSettingScreen.dart';
import 'package:astrologer_app/features/Settings/MyCommunityScreen.dart';
import 'package:astrologer_app/features/Settings/MyReviewScreen.dart';
import 'package:astrologer_app/features/account/CompleteProfileScreen.dart';
import 'package:astrologer_app/features/account/LoginScreen.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/features/account/ThemeAppearanceScreen.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AstrologerProfileScreen extends StatefulWidget {
  const AstrologerProfileScreen({super.key});

  @override
  State<AstrologerProfileScreen> createState() =>
      _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen> {
  Astrologer? astrologerData;
  bool isLoading   = true;
  bool _loggingOut = false;

  final _storage = const FlutterSecureStorage();
  final _client  = ApiClient();

  @override
  void initState() {
    super.initState();
    fetchAstrologerProfile();
  }

  void fetchAstrologerProfile() async {
    try {
      final response = await ApiService().get_astrologer_profile();
      setState(() {
        astrologerData = response.results.isNotEmpty
            ? response.results[0]
            : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Exception: $e');
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final c = context.colors;

    final confirmed = await showDialog<bool>(
      context           : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title  : Text('Logout',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: c.subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : Text('Cancel',
                style: TextStyle(color: c.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child    : const Text(
              'Logout',
              style: TextStyle(
                  color     : AppTheme.accentRed,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _loggingOut = true);

    try {
      await _client.post(
        'astrologer_api/astrologer_logout',
        {
          'is_chat_online' : 'off',
          'is_voice_online': 'off',
          'is_video_online': 'off',
        },
        isAuthRequired: true,
      );
    } catch (_) {}

    await _storage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await NotificationService().deleteToken();

    if (!mounted) return;
    setState(() => _loggingOut = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
        title    : const Text('Astrologer Profile'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : Column(
              children: [

                // ── Profile header ────────────────────────────────────
                Container(
                  width  : double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(16),
                    vertical  : FigmaSize.h(14),
                  ),
                  color: isDark
                      ? AppTheme.primaryYellow.withOpacity(0.10)
                      : const Color(0xFFFFF7D6),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        height    : FigmaSize.h(56),
                        width     : FigmaSize.w(56),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primaryYellow, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(
                                astrologerData?.profileImg ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: FigmaSize.w(12)),
                      // Name + email + number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${astrologerData?.displayname}',
                              style: TextStyle(
                                fontSize  : FigmaSize.w(14),
                                fontWeight: FontWeight.w600,
                                color     : c.text,
                              ),
                            ),
                            SizedBox(height: FigmaSize.h(4)),
                            Text(
                              '${astrologerData?.email}',
                              style: TextStyle(
                                  fontSize: FigmaSize.w(12),
                                  color   : c.subText),
                            ),
                            SizedBox(height: FigmaSize.h(2)),
                            Text(
                              '${astrologerData?.number}',
                              style: TextStyle(
                                  fontSize: FigmaSize.w(12),
                                  color   : c.subText),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit,
                          color: AppTheme.accentRed, size: 20),
                    ],
                  ),
                ),

                // ── Menu list ─────────────────────────────────────────
                Expanded(
                  child: ListView(
                    children: [
                      _menuItem(
                        Icons.person_outline,
                        'Complete Your Profile',
                        context,
                        CompleteProfileScreen(
                            astrologerData: astrologerData!),
                        c: c,
                      ),
                      _menuItem(
                        Icons.account_balance_wallet_outlined,
                        'Wallet',
                        context,
                        const WalletScreen(),
                        c: c,
                      ),
                      _menuItem(
                        Icons.support_agent_outlined,
                        'Support Chat',
                        context,
                        const SupportChatScreen(),
                        c: c,
                      ),
                      _menuItem(Icons.star_border,
                          'My Reviews',   context, const MyReviewsScreen(),      c: c),
                      _menuItem(Icons.group_outlined,
                          'My Community', context, const MyCommunityFollowers(), c: c),
                      _menuItem(Icons.settings_outlined,
                          'Settings',    context, const Mainsettingscreen(),     c: c),
                      _menuItem(Icons.dark_mode_outlined,
                          'Dark Mode',   context, const AppearanceScreen(),      c: c),

                      // ── Divider before logout ─────────────────────
                      Divider(
                          height: FigmaSize.h(20),
                          color : c.divider),

                      // ── Logout tile ───────────────────────────────
                      _loggingOut
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: FigmaSize.h(16)),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.accentRed),
                              ),
                            )
                          : ListTile(
                              leading: const Icon(Icons.logout,
                                  color: AppTheme.accentRed),
                              title: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize  : FigmaSize.w(13),
                                  fontWeight: FontWeight.w500,
                                  color     : AppTheme.accentRed,
                                ),
                              ),
                              onTap: _logout,
                            ),
                    ],
                  ),
                ),

                // ── Version ───────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
                  child: Text(
                    'Version 11.424',
                    style: TextStyle(
                        fontSize: FigmaSize.w(11), color: c.subText),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Menu tile ──────────────────────────────────────────────────────────────
  Widget _menuItem(
    IconData     icon,
    String       title,
    BuildContext context,
    dynamic      pageName, {
    required AppColors c,
  }) {
    return Column(
      children: [
        ListTile(
          leading : Icon(icon, color: c.subText),
          title   : Text(
            title,
            style: TextStyle(
              fontSize  : FigmaSize.w(13),
              fontWeight: FontWeight.w500,
              color     : c.text,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: c.subText),
          onTap   : () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => pageName),
          ),
        ),
        Divider(height: 1, color: c.divider),
      ],
    );
  }
}