import 'package:astrologer_app/features/Settings/components/commonWidget.dart';
import 'package:flutter/material.dart';

class MyCommunityFollowers extends StatefulWidget {
  const MyCommunityFollowers({super.key});

  @override
  State<MyCommunityFollowers> createState() => _MyCommunityFollowersState();
}

class _MyCommunityFollowersState extends State<MyCommunityFollowers> {
  int selectedCommunityTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: yellowAppBar("My Community"),
      body: Column(
        children: [
          communityTabs(
            selectedIndex: selectedCommunityTab,
            onTabChange: (index) {
              setState(() {
                selectedCommunityTab = index;
              });
            },
          ),

          // 🔥 SWITCH UI HERE
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedCommunityTab) {
      case 0: // Followers
        return Column(
          children: [
            searchField(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                itemBuilder: (_, __) => communityUserCard(),
              ),
            ),
          ],
        );

      case 1: // Favourites
        return Column(
          children: [
            searchField(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 2,
                itemBuilder: (_, __) => communityUserCard(),
              ),
            ),
          ],
        );

      case 2: // Always Online
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            alwaysOnlineInfo(),
            searchAndSort(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                itemBuilder: (_, __) => alwaysOnlineCard(),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
