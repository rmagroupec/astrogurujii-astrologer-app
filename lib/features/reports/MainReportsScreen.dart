// lib/features/reports/MainReportsScreen.dart
// ── Full dark / light theme via AppColors extension (context.colors / context.isDark)
// ── Responsive via LayoutBuilder + MediaQuery

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/reports/HistoryCard.dart';
import 'package:flutter/material.dart';

import 'package:astrologer_app/features/reports/HistoryCard.dart';
import 'package:astrologer_app/features/service/AstrologerGistScreen.dart';// ← adjust path to match where you saved it
import 'package:flutter/material.dart';
class MainReportsScreen extends StatefulWidget {
  final String page;
  const MainReportsScreen({super.key, required this.page});

  @override
  State<MainReportsScreen> createState() => _MainReportsScreenState();
}

class _MainReportsScreenState extends State<MainReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _TabMeta(key: 'chat',      label: 'Chat',      icon: Icons.chat_bubble_outline_rounded),
    _TabMeta(key: 'audio',     label: 'Call',       icon: Icons.phone_outlined),
    _TabMeta(key: 'video',     label: 'Video Call', icon: Icons.videocam_outlined),
    _TabMeta(key: 'Gift', label: 'Gift', icon: Icons.card_giftcard_outlined),
  ];

  int _initialIndex() {
    final idx = _tabs.indexWhere((t) => t.key == widget.page);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _initialIndex(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c       = context.colors;
    final isDark  = context.isDark;
    final primary = Theme.of(context).colorScheme.primary; // #FCD417

    // On small screens: text-only tabs; on wider screens: icon + text
    final isWide  = MediaQuery.sizeOf(context).width > 480;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Inherits backgroundColor / foregroundColor from AppTheme
        title: Text(
          'Orders',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        leading: BackButton(
          color: isDark ? Colors.white : Colors.black,
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: isDark
                ? const Color(0xFF1A1A1A)   // dark: slightly lighter than bg
                : primary,                   // light: brand yellow
            child: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? primary : Colors.black,
              indicatorWeight: 3,
              labelColor: isDark ? primary : Colors.black,
              unselectedLabelColor:
                  isDark ? Colors.white38 : Colors.black54,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: _tabs.map((t) {
                return isWide
                    ? Tab(
                        height: 44,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 15),
                            const SizedBox(width: 5),
                            Text(t.label),
                          ],
                        ),
                      )
                    : Tab(text: t.label);
              }).toList(),
            ),
          ),
        ),
      ),
                 body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) {
          if (t.key == 'Gift') {
            return const AstrologerGiftScreen(showAppBar: false);
          }
          return HistoryCard(page: t.key);
        }).toList(),
      ),
    );
  }
}

// ── Simple data class for tab metadata ───────────────────────────────────────
class _TabMeta {
  final String   key;
  final String   label;
  final IconData icon;
  const _TabMeta({required this.key, required this.label, required this.icon});
}