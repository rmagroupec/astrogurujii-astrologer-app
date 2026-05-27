import 'dart:convert';

import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/Settings/MainSettingScreen.dart';
import 'package:astrologer_app/features/Settings/MyCommunityScreen.dart';
import 'package:astrologer_app/features/Settings/MyReviewScreen.dart';
import 'package:astrologer_app/features/account/CompleteProfileScreen.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/features/account/ThemeAppearanceScreen.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/features/account/WeeklyRankingScreen.dart';
import 'package:astrologer_app/features/live/GoLiveScreen.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:astrologer_app/core/utils/size_config.dart';

class AstrologerProfileScreen extends StatefulWidget {
  const AstrologerProfileScreen({super.key});

  @override
  State<AstrologerProfileScreen> createState() =>
      _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen> {
Astrologer? astrologerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAstrologerProfile();
  }

  void fetchAstrologerProfile() async {
    try {
      var response = await ApiService().get_astrologer_profile();

     
      setState(() {
        astrologerData = response.results.isNotEmpty ? response.results[0] : null;
        isLoading = false;
      }); 
    } catch (e) {
      setState(() => isLoading = false);
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Astrologer Profile"),
        backgroundColor: const Color(0xFFFCD417),
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: isLoading ? Center(child: CircularProgressIndicator(),) : Column(
        children: [
          /// PROFILE HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(16),
              vertical: FigmaSize.h(14),
            ),
            color: const Color(0xFFFFF7D6),
            child: Row(
              children: [
                Container(
                  height: FigmaSize.h(56),
                  width: FigmaSize.w(56),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCD417),
                      width: 2,
                    ),
                    image:  DecorationImage(
                      image: NetworkImage(astrologerData?.profileImg ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: FigmaSize.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${astrologerData?.displayname}",
                        style: TextStyle(
                          fontSize: FigmaSize.w(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: FigmaSize.h(4)),
                      Text(
                        "${astrologerData?.email}",
                        style: TextStyle(
                          fontSize: FigmaSize.w(12),
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: FigmaSize.h(2)),
                      Text(
                        "${astrologerData?.number}",
                        style: TextStyle(
                          fontSize: FigmaSize.w(12),
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: Colors.red, size: 20),
              ],
            ),
          ),

          /// MENU LIST
          Expanded(
            child: ListView(
              children: [
                _menuItem(
                  Icons.person_outline,
                  "Complete Your Profile",
                  context,
                  CompleteProfileScreen(astrologerData: astrologerData!,)
                ),
                _menuItem(
                  Icons.account_balance_wallet_outlined,
                  "Wallet",
                  context,
                  WalletScreen()
                ),
                _menuItem(
                  Icons.support_agent_outlined,
                  "Support Chat",
                  context,
                  SupportChatScreen()
                ),
                _menuItem(
                  Icons.wifi_tethering_outlined,
                  "Go Live Now!",
                  context,
                  GoLiveScreen()
                ),
                _menuItem(Icons.star_border, "My Reviews", context, MyReviewsScreen()),
                _menuItem(Icons.chat_bubble_outline, "Assistant Chat", context, SupportChatScreen()),
                _menuItem(Icons.group_outlined, "My Community", context, MyCommunityFollowers()),
                _menuItem(Icons.settings_outlined, "Settings", context, Mainsettingscreen()),
                _menuItem(Icons.dark_mode_outlined, "Dark Mode", context, AppearanceScreen()),
              ],
            ),
          ),

          /// VERSION
          Padding(
            padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
            child: Text(
              "Version 11.424",
              style: TextStyle(fontSize: FigmaSize.w(11), color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// MENU TILE
  Widget _menuItem(IconData icon, String title, BuildContext context, dynamic pageName) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[700]),
          title: Text(
            title,
            style: TextStyle(
              fontSize: FigmaSize.w(13),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => pageName),
            );
          },
        ),
        Divider(height: 1, color: Colors.black.withOpacity(0.05)),
      ],
    );
  }
}
