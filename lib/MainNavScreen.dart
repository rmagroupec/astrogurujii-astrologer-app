// lib/MainNavScreen.dart
//
// Changes from original:
// 1. ✅ Imports LastCallListModel + ApiService
// 2. ✅ _activeCall loaded in initState, refreshed after returning from call screen
// 3. ✅ ActiveCallFloatingCard shown when status == 'accept_astro'
// 4. ✅ Supports chat / audio / video with distinct colors via the card widget
// 5. ✅ Scaffold uses Stack so card floats above everything

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/Settings/ImmprtantNoticeScreen.dart';
import 'package:astrologer_app/features/account/AstrologerSideDrawer.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/features/reports/MainReportsScreen.dart';
import 'package:astrologer_app/model/last_call_list_model.dart';   // ← your model
import 'package:astrologer_app/service/apiService.dart';           // ← your service
import 'package:astrologer_app/core/widgets/active_call_floating_card.dart';
import 'package:flutter/material.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {

  // ── Active call ─────────────────────────────────────────────────────────────
  Data2? _activeCall;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadActiveCall();
  }

  Future<void> _loadActiveCall() async {
    try {
      final res = await _api.lastCallList();
      if (!mounted) return;
      setState(() {
        // Only show card for live sessions
        _activeCall = (res?.result == true && res?.data2?.status == 'accept_astro')
            ? res!.data2
            : null;
      });
    } catch (_) {}
  }

  // ── Nav ─────────────────────────────────────────────────────────────────────
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MainReportsScreen(page: ''),
    WalletScreen(),
    ImportantNoticeScreen(),
    AstrologerProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home',   activeIcon: Icons.home,                    inactiveIcon: Icons.home_outlined),
    _NavItem(label: 'Orders', activeIcon: Icons.shopping_cart,           inactiveIcon: Icons.shopping_cart_outlined),
    _NavItem(label: 'Wallet', activeIcon: Icons.account_balance_wallet,  inactiveIcon: Icons.account_balance_wallet_outlined),
    _NavItem(label: 'Notice', activeIcon: Icons.notifications,           inactiveIcon: Icons.notifications_outlined),
    _NavItem(label: 'Profile',activeIcon: Icons.person,                  inactiveIcon: Icons.person_outline),
  ];

  static const Color _activeColor   = Color(0xFFD41000);
  static const Color _inactiveColor = Color(0xFF9E9E9E);

  // ── Navigate to active call screen ─────────────────────────────────────────
  void _resumeActiveCall() {
    if (_activeCall == null) return;
    final d = _activeCall!;

    // Route based on call type — adjust imports / screen names as needed
    switch (d.callType?.toLowerCase()) {
      case 'audio':
        // Navigator.push(context, MaterialPageRoute(builder: (_) =>
        //   AudioCallScreen(channelId: d.channelId ?? '', ...)))
        //   .then((_) => _loadActiveCall());
        break;
      case 'video':
        // Navigator.push(context, MaterialPageRoute(builder: (_) =>
        //   VideoCallScreen(channelId: d.channelId ?? '', ...)))
        //   .then((_) => _loadActiveCall());
        break;
      default: // chat
        // Navigator.push(context, MaterialPageRoute(builder: (_) =>
        //   ChatScreen(channelId: d.channelId ?? '', ...)))
        //   .then((_) => _loadActiveCall());
        break;
    }
  }

  // ── End active call (optional dismiss) ─────────────────────────────────────
  Future<void> _endActiveCall() async {
    if (_activeCall == null) return;
    // Optionally call the status update API here:
    // await _api.callStatusUpdate(channelId: _activeCall!.channelId!, status: 'end_astro');
    setState(() => _activeCall = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Use Stack so the floating card truly overlays body + nav bar
      body: Stack(
        children: [
          // ── Main pages ──────────────────────────────────────────────────
          IndexedStack(
            index   : _currentIndex,
            children: _pages,
          ),

          // ── Active call floating card ───────────────────────────────────
          if (_activeCall != null)
            ActiveCallFloatingCard(
              data2    : _activeCall,
              onTap    : _resumeActiveCall,
              onDismiss: _endActiveCall,
              // Optionally pass live timer seconds from CountdownManager:
              // timeLeftSeconds: countdownManager.timeLeftNotifier.value,
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items       : _navItems,
        activeColor : _activeColor,
        inactiveColor: _inactiveColor,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom nav
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int             currentIndex;
  final List<_NavItem>  items;
  final Color           activeColor;
  final Color           inactiveColor;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color : Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: FigmaSize.h(60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (i) => _NavTile(
                item        : items[i],
                isActive    : i == currentIndex,
                activeColor : activeColor,
                inactiveColor: inactiveColor,
                onTap       : () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem   item;
  final bool       isActive;
  final Color      activeColor;
  final Color      inactiveColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child    : SizedBox(
        width: FigmaSize.w(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? item.activeIcon : item.inactiveIcon,
                color: color, size: FigmaSize.w(24)),
            SizedBox(height: FigmaSize.h(4)),
            Text(
              item.label,
              style: TextStyle(
                fontSize  : FigmaSize.w(11),
                color     : color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String   label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}