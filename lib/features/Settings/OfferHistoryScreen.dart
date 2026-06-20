// lib/features/Settings/OfferHistoryScreen.dart
// ── Theme-aware: context passed to all commonWidget functions ─────────────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/Settings/components/commonWidget.dart';
import 'package:flutter/material.dart';

class OffersHistoryScreen extends StatelessWidget {
  const OffersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: yellowAppBar('Offers'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          offersInfo(context),
          offersTabBar(context),
          offerFilterChips(context),
          Expanded(
            child: ListView.builder(
              padding   : const EdgeInsets.all(12),
              itemCount : 4,
              itemBuilder: (ctx, i) => historyOfferCard(ctx, i == 0),
            ),
          ),
        ],
      ),
    );
  }
}

class AlwaysOnlineScreen extends StatefulWidget {
  const AlwaysOnlineScreen({super.key});

  @override
  State<AlwaysOnlineScreen> createState() => _AlwaysOnlineScreenState();
}

class _AlwaysOnlineScreenState extends State<AlwaysOnlineScreen> {
  int selectedCommunityTab = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: yellowAppBar('My Community'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          communityTabs(
            context,
            selectedIndex: selectedCommunityTab,
            onTabChange  : (index) {
              setState(() => selectedCommunityTab = index);
            },
          ),
          Expanded(
            child: ListView.builder(
              padding   : const EdgeInsets.all(12),
              itemCount : 4,
              itemBuilder: (ctx, __) => alwaysOnlineCard(ctx),
            ),
          ),
        ],
      ),
    );
  }
}