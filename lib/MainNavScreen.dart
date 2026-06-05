import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/Settings/ImmprtantNoticeScreen.dart';
import 'package:astrologer_app/features/account/AstrologerSideDrawer.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/features/reports/MainReportsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ---------------------------------------------------------------------------
// Replace the import below with your actual Orders screen import once ready
// import 'package:astrologer_app/features/orders/OrdersScreen.dart';
// ---------------------------------------------------------------------------

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  // ── Pages ──────────────────────────────────────────────────────────────────
  final List<Widget> _pages = const [
    HomeScreen(),
    // Replace with your actual OrdersScreen() when available
   MainReportsScreen(page: '',),
    WalletScreen(),
    ImportantNoticeScreen(),
    AstrologerProfileScreen(),
  ];

  // ── Nav items ──────────────────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Home',
      activeIcon: Icons.home,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItem(
      label: 'Orders',
      activeIcon: Icons.shopping_cart,
      inactiveIcon: Icons.shopping_cart_outlined,
    ),
    _NavItem(
      label: 'Wallet',
      activeIcon: Icons.account_balance_wallet,
      inactiveIcon: Icons.account_balance_wallet_outlined,
    ),
    _NavItem(
      label: 'Notice',
      activeIcon: Icons.notifications,
      inactiveIcon: Icons.notifications_outlined,
    ),
    _NavItem(
      label: 'Profile',
      activeIcon: Icons.person,
      inactiveIcon: Icons.person_outline,
    ),
  ];

  static const Color _activeColor   = Color(0xFFD41000);
  static const Color _inactiveColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        activeColor: _activeColor,
        inactiveColor: _inactiveColor,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom nav widget
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final Color activeColor;
  final Color inactiveColor;
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
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
        ),
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
                item: items[i],
                isActive: i == currentIndex,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single nav tile
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: FigmaSize.w(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.inactiveIcon,
              color: color,
              size: FigmaSize.w(24),
            ),
            SizedBox(height: FigmaSize.h(4)),
            Text(
              item.label,
              style: TextStyle(
                fontSize: FigmaSize.w(11),
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Temporary placeholder — remove once real OrdersScreen is ready
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Text(
          '$label Screen',
          style: TextStyle(
            fontSize: FigmaSize.w(16),
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}