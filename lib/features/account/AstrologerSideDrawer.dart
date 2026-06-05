// lib/features/account/AstrologerSideDrawer.dart
// Zero UI changes. Added:
//   - Logout menu item at the bottom of the list
//   - _logout() method that calls the API, clears all local storage, navigates to LoginScreen

import 'dart:convert';

import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/Settings/MainSettingScreen.dart';
import 'package:astrologer_app/features/Settings/MyCommunityScreen.dart';
import 'package:astrologer_app/features/Settings/MyReviewScreen.dart';
import 'package:astrologer_app/features/account/CompleteProfileScreen.dart';
import 'package:astrologer_app/features/account/LoginScreen.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/features/account/ThemeAppearanceScreen.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/features/account/WeeklyRankingScreen.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:flutter/material.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
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
  bool isLoading  = true;
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
      print("Exception: $e");
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    // 1. Confirm
    final confirmed = await showDialog<bool>(
      context           : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title  : const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child    : const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _loggingOut = true);

    try {
      // 2. Tell the server — sets all online statuses to "off"
      await _client.post(
        'astrologer_api/astrologer_logout',
        {
          'is_chat_online' : 'off',
          'is_voice_online': 'off',
          'is_video_online': 'off',
        },
        isAuthRequired: true,
      );
    } catch (_) {
      // proceed with local logout even if API fails
    }

    // 3. Clear JWT token from secure storage
    await _storage.delete(key: 'auth_token');

    // 4. Clear all SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 5. Delete FCM token so notifications stop
    await NotificationService().deleteToken();

    if (!mounted) return;
    setState(() => _loggingOut = false);

    // 6. Navigate to LoginScreen, remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar          : AppBar(
        title          : const Text("Astrologer Profile"),
        backgroundColor: const Color(0xFFFCD417),
        foregroundColor: Colors.black,
        elevation      : 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// PROFILE HEADER
                Container(
                  width  : double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(16),
                    vertical  : FigmaSize.h(14),
                  ),
                  color: const Color(0xFFFFF7D6),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        height    : FigmaSize.h(56),
                        width     : FigmaSize.w(56),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFCD417), width: 2),
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
                              ),
                            ),
                            SizedBox(height: FigmaSize.h(4)),
                            Text(
                              '${astrologerData?.email}',
                              style: TextStyle(
                                  fontSize: FigmaSize.w(12),
                                  color   : Colors.black54),
                            ),
                            SizedBox(height: FigmaSize.h(2)),
                            Text(
                              '${astrologerData?.number}',
                              style: TextStyle(
                                  fontSize: FigmaSize.w(12),
                                  color   : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, color: Colors.red, size: 20),
                    ],
                  ),
                ),

                /// MENU LIST
                Expanded(
                  child: ListView(
                    children: [
                      _menuItem(
                        Icons.person_outline,
                        'Complete Your Profile',
                        context,
                        CompleteProfileScreen(
                            astrologerData: astrologerData!),
                      ),
                      _menuItem(
                        Icons.account_balance_wallet_outlined,
                        'Wallet',
                        context,
                        WalletScreen(),
                      ),
                      _menuItem(
                        Icons.support_agent_outlined,
                        'Support Chat',
                        context,
                        SupportChatScreen(),
                      ),
                      _menuItem(Icons.star_border,     'My Reviews',  context, MyReviewsScreen()),
                      _menuItem(Icons.group_outlined,  'My Community',context, MyCommunityFollowers()),
                      _menuItem(Icons.settings_outlined,'Settings',   context, Mainsettingscreen()),
                      _menuItem(Icons.dark_mode_outlined,'Dark Mode',  context, AppearanceScreen()),

                      // ── Divider before logout ─────────────────────────
                      Divider(
                          height: FigmaSize.h(20),
                          color : Colors.black.withOpacity(0.08)),

                      // ── Logout tile ───────────────────────────────────
                      _loggingOut
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: FigmaSize.h(16)),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFD41000)),
                              ),
                            )
                          : ListTile(
                              leading: const Icon(Icons.logout,
                                  color: Color(0xFFD41000)),
                              title: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize  : FigmaSize.w(13),
                                  fontWeight: FontWeight.w500,
                                  color     : const Color(0xFFD41000),
                                ),
                              ),
                              onTap: _logout,
                            ),
                    ],
                  ),
                ),

                /// VERSION
                Padding(
                  padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
                  child: Text(
                    'Version 11.424',
                    style: TextStyle(
                        fontSize: FigmaSize.w(11), color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }

  /// MENU TILE (unchanged)
  Widget _menuItem(
    IconData icon,
    String title,
    BuildContext context,
    dynamic pageName,
  ) {
    return Column(
      children: [
        ListTile(
          leading : Icon(icon, color: Colors.grey[700]),
          title   : Text(
            title,
            style: TextStyle(
              fontSize  : FigmaSize.w(13),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap   : () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => pageName),
          ),
        ),
        Divider(height: 1, color: Colors.black.withOpacity(0.05)),
      ],
    );
  }
}