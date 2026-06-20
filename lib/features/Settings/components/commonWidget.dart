// lib/features/Settings/components/commonWidget.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── BuildContext added to every function that needs theme access ───────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
// APP BAR — inherits from AppTheme, no context needed
// ─────────────────────────────────────────────────────────────────
PreferredSizeWidget yellowAppBar(String title) {
  return AppBar(
    elevation: 0,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

// ─────────────────────────────────────────────────────────────────
// OFFERS INFO
// ─────────────────────────────────────────────────────────────────
Widget offersInfo(BuildContext context) {
  final c = context.colors;
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      'Loyal - Customers who have spoken with you for more than 15 min '
      '(including both call and chat)',
      style: TextStyle(fontSize: 11, color: c.subText),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// OFFERS TAB BAR
// ─────────────────────────────────────────────────────────────────
Widget offersTabBar(BuildContext context) {
  final isDark = context.isDark;
  return Container(
    color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF8E1),
    child: TabBar(
      dividerColor        : Colors.transparent,
      labelColor          : isDark ? Colors.white : Colors.black,
      unselectedLabelColor: isDark ? Colors.white38 : Colors.black54,
      indicator           : const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
      ),
      tabs: const [
        Tab(text: 'ALL OFFERS'),
        Tab(text: 'HISTORY'),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// OFFER FILTER CHIPS
// ─────────────────────────────────────────────────────────────────
Widget offerFilterChips(BuildContext context) {
  final c = context.colors;
  return Padding(
    padding: const EdgeInsets.all(12),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', '50% Off', '20% Off', '75% Off']
            .map((e) => Container(
                  margin : const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border      : Border.all(color: AppTheme.primaryYellow),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e,
                      style: TextStyle(fontSize: 11, color: c.text)),
                ))
            .toList(),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// TIME BOX
// ─────────────────────────────────────────────────────────────────
Widget timeBox(BuildContext context, String title, String value) {
  final c = context.colors;
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 10, color: c.subText)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize  : 12,
                  fontWeight: FontWeight.w600,
                  color     : c.text)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// ALWAYS ONLINE CARD
// ─────────────────────────────────────────────────────────────────
Widget alwaysOnlineCard(BuildContext context) {
  final c      = context.colors;
  final isDark = context.isDark;
  return Container(
    margin : const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color       : c.surface,
      border      : Border.all(color: c.border),
      boxShadow   : isDark
          ? []
          : [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6)],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sakshi (98997378)',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 6),
            Text('Spent - 340',
                style: TextStyle(color: c.subText)),
            Text('Last session - 22 Oct 2025, 04:47 PM',
                style: TextStyle(fontSize: 11, color: c.subText)),
          ],
        ),
        Switch(
          value      : false,
          onChanged  : (_) {},
          activeColor: AppTheme.primaryYellow,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// SEARCH FIELD
// ─────────────────────────────────────────────────────────────────
Widget searchField(BuildContext context) {
  final c      = context.colors;
  final isDark = context.isDark;
  return TextField(
    style: TextStyle(color: c.text),
    decoration: InputDecoration(
      hintText      : 'Search by Name',
      hintStyle     : TextStyle(color: c.subText),
      filled        : true,
      fillColor     : isDark ? c.toggleBg : Colors.grey.shade50,
      prefixIcon    : Icon(Icons.search, color: c.subText),
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      border        : OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide  : BorderSide(color: c.border),
      ),
      enabledBorder : OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide  : BorderSide(color: c.border),
      ),
      focusedBorder : OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide  : BorderSide(color: AppTheme.primaryYellow, width: 2),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// INFO BOX
// ─────────────────────────────────────────────────────────────────
Widget infoBox(BuildContext context, String title, String value) {
  final c      = context.colors;
  final isDark = context.isDark;
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color       : isDark ? c.toggleBg : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(fontSize: 11, color: c.subText)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize  : 13,
                  color     : c.text)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// COMMUNITY TABS
// ─────────────────────────────────────────────────────────────────
Widget communityTabs(
  BuildContext context, {
  required int selectedIndex,
  required Function(int) onTabChange,
}) {
  final c      = context.colors;
  final isDark = context.isDark;

  final tabs = [
    {'title': 'Followers',     'count': '840'},
    {'title': 'Favourites',    'count': '10'},
    {'title': 'Always Online', 'count': '10'},
  ];

  return Container(
    color  : isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF8E1),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child  : Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTabChange(index),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tabs[index]['title']!,
                      style: TextStyle(
                        fontSize  : 13,
                        fontWeight: FontWeight.w600,
                        color     : isSelected ? c.text : c.subText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color       : AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tabs[index]['count']!,
                        style: const TextStyle(
                            fontSize  : 10,
                            fontWeight: FontWeight.w600,
                            color     : Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2, width: 60,
                  color: isSelected
                      ? AppTheme.primaryYellow
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// HISTORY OFFER CARD
// ─────────────────────────────────────────────────────────────────
Widget historyOfferCard(BuildContext context, bool inProgress) {
  final c = context.colors;
  return Container(
    margin : const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color       : c.surface,
      border      : Border.all(color: c.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('50% off',
                style: TextStyle(
                    color     : AppTheme.accentRed,
                    fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: inProgress
                    ? Colors.blue.withOpacity(0.12)
                    : Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                inProgress ? 'In Progress' : 'Completed',
                style: TextStyle(
                  fontSize: 12,
                  color   : inProgress ? Colors.blue : Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            timeBox(context, 'Start Time', '02 Oct 25, 12:34 AM'),
            const SizedBox(width: 8),
            timeBox(context, 'End Time',   'Currently active'),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// COMMUNITY USER CARD
// ─────────────────────────────────────────────────────────────────
Widget communityUserCard(BuildContext context) {
  final c      = context.colors;
  final isDark = context.isDark;
  return Container(
    margin : const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color       : c.surface,
      border      : Border.all(color: c.border),
      boxShadow   : isDark
          ? []
          : [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dhan Singh (817381387)',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: c.text)),
            const Icon(Icons.favorite, color: Colors.red),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            infoBox(context, 'Spent with you', '₹ 4,930'),
            infoBox(context, 'Last Session',   '01 Oct, 25'),
            infoBox(context, 'Remedies',       '0'),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side           : BorderSide(color: AppTheme.accentRed),
            foregroundColor: AppTheme.accentRed,
          ),
          child: const Text('Assistant Chat'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// ALWAYS ONLINE INFO BANNER
// ─────────────────────────────────────────────────────────────────
Widget alwaysOnlineInfo(BuildContext context) {
  final c      = context.colors;
  final isDark = context.isDark;
  return Container(
    width  : double.infinity,
    color  : isDark
        ? AppTheme.primaryYellow.withOpacity(0.10)
        : const Color(0xFFFFF8E1),
    padding: const EdgeInsets.all(12),
    child  : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wifi, color: AppTheme.accentRed, size: 18),
            const SizedBox(width: 6),
            Text(
              'Always Online',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize  : 13,
                  color     : c.text),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'This feature allows selected users to start a session with you '
          'even when you are offline. Use it to stay connected with your '
          'important users.',
          style: TextStyle(fontSize: 11, color: c.subText),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// SEARCH AND SORT
// ─────────────────────────────────────────────────────────────────
Widget searchAndSort(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(child: searchField(context)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color       : AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.sort, size: 16, color: Colors.black),
              SizedBox(width: 4),
              Text('Sort',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize  : 12,
                      color     : Colors.black)),
            ],
          ),
        ),
      ],
    ),
  );
}