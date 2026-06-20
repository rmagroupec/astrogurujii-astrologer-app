// lib/features/Settings/MyCommunityScreen.dart
// ── Theme-aware: uses updated commonWidget functions that accept BuildContext ──
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
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
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: yellowAppBar('My Community'),
      body: Column(
        children: [
          communityTabs(
            context,
            selectedIndex: selectedCommunityTab,
            onTabChange: (index) {
              setState(() => selectedCommunityTab = index);
            },
          ),
          Expanded(
            child: _buildTabContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (selectedCommunityTab) {
      case 0: // Followers
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: searchField(context),
            ),
            Expanded(
              child: ListView.builder(
                padding   : const EdgeInsets.all(12),
                itemCount : 4,
                itemBuilder: (ctx, __) => communityUserCard(ctx),
              ),
            ),
          ],
        );

      case 1: // Favourites
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: searchField(context),
            ),
            Expanded(
              child: ListView.builder(
                padding   : const EdgeInsets.all(12),
                itemCount : 2,
                itemBuilder: (ctx, __) => communityUserCard(ctx),
              ),
            ),
          ],
        );

      case 2: // Always Online
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            alwaysOnlineInfo(context),
            searchAndSort(context),
            Expanded(
              child: ListView.builder(
                padding   : const EdgeInsets.all(12),
                itemCount : 4,
                itemBuilder: (ctx, __) => alwaysOnlineCard(ctx),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}