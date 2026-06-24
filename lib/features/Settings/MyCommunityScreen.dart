// lib/features/Settings/MyCommunityScreen.dart
// ── Full API-connected community screen ──────────────────────────────────────
// Tabs: Followers · Favourites · Always Online (Loyal)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/Settings/components/commonWidget.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class CommunityUser {
  final String userId;
  final String name;
  final String profileImg;
  final int totalSessions;
  final double totalMinutes;
  final double totalSpent;
  final String lastSession;
  final bool isLoyal;
  bool isFavourite;
  bool isAlwaysOnline;

  CommunityUser({
    required this.userId,
    required this.name,
    required this.profileImg,
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalSpent,
    required this.lastSession,
    required this.isLoyal,
    this.isFavourite = false,
    this.isAlwaysOnline = false,
  });

  factory CommunityUser.fromFollowerJson(Map<String, dynamic> j) =>
      CommunityUser(
        userId        : j['user_id']?.toString()        ?? '',
        name          : j['name']?.toString()           ?? 'Unknown',
        profileImg    : j['profile_img']?.toString()    ?? '',
        totalSessions : (j['total_sessions'] as num?)?.toInt()    ?? 0,
        totalMinutes  : (j['total_minutes']  as num?)?.toDouble() ?? 0,
        totalSpent    : (j['total_spent']    as num?)?.toDouble() ?? 0,
        lastSession   : j['last_session']?.toString()   ?? '',
        isLoyal       : j['is_loyal']  == true,
        isFavourite   : j['is_favourite'] == true,
        isAlwaysOnline: j['is_always_online'] == true,
      );

  factory CommunityUser.fromFavouriteJson(Map<String, dynamic> j) =>
      CommunityUser(
        userId        : j['user_id']?.toString()        ?? '',
        name          : j['name']?.toString()           ?? 'Unknown',
        profileImg    : j['profile_img']?.toString()    ?? '',
        totalSessions : (j['total_sessions'] as num?)?.toInt()    ?? 0,
        totalMinutes  : (j['total_minutes']  as num?)?.toDouble() ?? 0,
        totalSpent    : (j['total_spent']    as num?)?.toDouble() ?? 0,
        lastSession   : j['last_session']?.toString()   ?? '',
        isLoyal       : j['is_loyal']  == true,
        isFavourite   : true,
        isAlwaysOnline: j['is_always_online'] == true,
      );

  factory CommunityUser.fromAlwaysOnlineJson(Map<String, dynamic> j) =>
      CommunityUser(
        userId        : j['user_id']?.toString()        ?? '',
        name          : j['name']?.toString()           ?? 'Unknown',
        profileImg    : j['profile_img']?.toString()    ?? '',
        totalSessions : (j['total_sessions'] as num?)?.toInt()    ?? 0,
        totalMinutes  : (j['total_minutes']  as num?)?.toDouble() ?? 0,
        totalSpent    : (j['total_spent']    as num?)?.toDouble() ?? 0,
        lastSession   : j['last_session']?.toString()   ?? '',
        isLoyal       : true,
        isAlwaysOnline: j['is_always_online'] == true,
      );
}

// ─── API Service ─────────────────────────────────────────────────────────────

class CommunityApiService {
  static const String _base = 'https://admin.astrogurujii.com/astrologer_api';
   static  ApiClient _client = ApiClient();

 




  // ── Followers ──────────────────────────────────────────────────────────────
  static Future<List<CommunityUser>> fetchFollowers({String search = ''}) async {
    
    final resp = await _client.post(
     'astrologer_api/community_followers',{'search': search},
    );
    final data = jsonDecode(resp.body);
    if (data['result'] == true) {
      return (data['data'] as List)
          .map((e) => CommunityUser.fromFollowerJson(e))
          .toList();
    }
    return [];
  }

  // ── Favourites ─────────────────────────────────────────────────────────────
  static Future<List<CommunityUser>> fetchFavourites({String search = ''}) async {
    
    final resp = await _client.post(
    'astrologer_api/community_favourites',{'search': search},
    );
    final data = jsonDecode(resp.body);
    if (data['result'] == true) {
      return (data['data'] as List)
          .map((e) => CommunityUser.fromFavouriteJson(e))
          .toList();
    }
    return [];
  }

  static Future<bool?> toggleFavourite(String userId) async {
   
    final resp= await _client.post(
    'astrologer_api/community_toggle_favourite',{'user_id': userId},
    );
    final data = jsonDecode(resp.body);
    if (data['result'] == true) return data['is_favourite'] as bool?;
    return null;
  }

  // ── Always Online ──────────────────────────────────────────────────────────
  static Future<List<CommunityUser>> fetchAlwaysOnline({
    String search = '',
    String sortBy = 'spent_desc',
  }) async {
    
    final resp = await _client.post(
      'astrologer_api/community_always_online',{'search': search, 'sort_by': sortBy},
    );
    final data = jsonDecode(resp.body);
    if (data['result'] == true) {
      return (data['data'] as List)
          .map((e) => CommunityUser.fromAlwaysOnlineJson(e))
          .toList();
    }
    return [];
  }

  static Future<bool?> toggleAlwaysOnline(String userId) async {
   
    final resp = await _client.post(
      'astrologer_api/community_toggle_always_online',
     {'user_id': userId},
    );
    final data = jsonDecode(resp.body);
    if (data['result'] == true) return data['is_enabled'] as bool?;
    return null;
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class MyCommunityFollowers extends StatefulWidget {
  const MyCommunityFollowers({super.key});

  @override
  State<MyCommunityFollowers> createState() => _MyCommunityFollowersState();
}

class _MyCommunityFollowersState extends State<MyCommunityFollowers> {
  int _tab = 0;

  // Followers state
  List<CommunityUser> _followers    = [];
  bool _followersLoading            = true;
  String _followersSearch           = '';
  final _followersSearchCtrl        = TextEditingController();

  // Favourites state
  List<CommunityUser> _favourites   = [];
  bool _favouritesLoading           = true;
  String _favouritesSearch          = '';
  final _favouritesSearchCtrl       = TextEditingController();

  // Always Online state
  List<CommunityUser> _alwaysOnline = [];
  bool _aoLoading                   = true;
  String _aoSearch                  = '';
  String _aoSort                    = 'spent_desc';
  final _aoSearchCtrl               = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFollowers();
    _loadFavourites();
    _loadAlwaysOnline();
  }

  @override
  void dispose() {
    _followersSearchCtrl.dispose();
    _favouritesSearchCtrl.dispose();
    _aoSearchCtrl.dispose();
    super.dispose();
  }

  // ── Loaders ────────────────────────────────────────────────────────────────

  Future<void> _loadFollowers() async {
    setState(() => _followersLoading = true);
    final data = await CommunityApiService.fetchFollowers(search: _followersSearch);
    if (mounted) setState(() { _followers = data; _followersLoading = false; });
  }

  Future<void> _loadFavourites() async {
    setState(() => _favouritesLoading = true);
    final data = await CommunityApiService.fetchFavourites(search: _favouritesSearch);
    if (mounted) setState(() { _favourites = data; _favouritesLoading = false; });
  }

  Future<void> _loadAlwaysOnline() async {
    setState(() => _aoLoading = true);
    final data = await CommunityApiService.fetchAlwaysOnline(
      search: _aoSearch, sortBy: _aoSort,
    );
    if (mounted) setState(() { _alwaysOnline = data; _aoLoading = false; });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggleFavourite(CommunityUser user) async {
    final newVal = await CommunityApiService.toggleFavourite(user.userId);
    if (newVal == null || !mounted) return;

    setState(() {
      // Update in followers list
      for (final u in _followers) {
        if (u.userId == user.userId) u.isFavourite = newVal;
      }
      // Add/remove from favourites list
      if (newVal) {
        if (!_favourites.any((u) => u.userId == user.userId)) {
          _favourites.insert(0, CommunityUser.fromFollowerJson({
            'user_id'      : user.userId,
            'name'         : user.name,
            'profile_img'  : user.profileImg,
            'total_sessions': user.totalSessions,
            'total_minutes' : user.totalMinutes,
            'total_spent'   : user.totalSpent,
            'last_session'  : user.lastSession,
            'is_loyal'      : user.isLoyal,
            'is_favourite'  : true,
            'is_always_online': user.isAlwaysOnline,
          }));
        }
      } else {
        _favourites.removeWhere((u) => u.userId == user.userId);
      }
    });

    _showSnack(newVal ? '❤️ Added to favourites' : 'Removed from favourites');
  }

  Future<void> _toggleAlwaysOnline(CommunityUser user, bool currentVal) async {
    final newVal = await CommunityApiService.toggleAlwaysOnline(user.userId);
    if (newVal == null || !mounted) return;

    setState(() {
      for (final u in _alwaysOnline) {
        if (u.userId == user.userId) u.isAlwaysOnline = newVal;
      }
      for (final u in _favourites) {
        if (u.userId == user.userId) u.isAlwaysOnline = newVal;
      }
    });

    _showSnack(newVal
        ? '✅ Always-online enabled for ${user.name}'
        : 'Always-online disabled for ${user.name}');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ── Sort Bottom Sheet ──────────────────────────────────────────────────────

  void _showSortSheet() {
    final options = {
      'spent_desc': 'Highest Spent',
      'spent_asc' : 'Lowest Spent',
      'recent'    : 'Most Recent',
      'name_asc'  : 'Name (A–Z)',
    };
    showModalBottomSheet(
      context: context,
      shape  : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child  : Text('Sort By',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...options.entries.map((e) => ListTile(
            title   : Text(e.value),
            trailing: _aoSort == e.key
                ? const Icon(Icons.check, color: AppTheme.primaryYellow)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _aoSort = e.key);
              _loadAlwaysOnline();
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: yellowAppBar('My Community'),
      body  : Column(
        children: [
          _CommunityTabBar(
            selectedIndex: _tab,
            followerCount: _followers.length,
            favouriteCount: _favourites.length,
            alwaysOnlineCount: _alwaysOnline.length,
            onTabChange: (i) {
              setState(() => _tab = i);
            },
          ),
          Expanded(child: _buildTabContent(context)),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_tab) {
      case 0: return _FollowersTab(
          users         : _followers,
          loading       : _followersLoading,
          searchCtrl    : _followersSearchCtrl,
          onSearch      : (v) { _followersSearch = v; _loadFollowers(); },
          onToggleFav   : _toggleFavourite,
        );
      case 1: return _FavouritesTab(
          users         : _favourites,
          loading       : _favouritesLoading,
          searchCtrl    : _favouritesSearchCtrl,
          onSearch      : (v) { _favouritesSearch = v; _loadFavourites(); },
          onToggleFav   : _toggleFavourite,
          onToggleAO    : _toggleAlwaysOnline,
        );
      case 2: return _AlwaysOnlineTab(
          users      : _alwaysOnline,
          loading    : _aoLoading,
          searchCtrl : _aoSearchCtrl,
          sortBy     : _aoSort,
          onSearch   : (v) { _aoSearch = v; _loadAlwaysOnline(); },
          onShowSort : _showSortSheet,
          onToggleAO : _toggleAlwaysOnline,
        );
      default: return const SizedBox();
    }
  }
}

// ─── Tab Bar ─────────────────────────────────────────────────────────────────

class _CommunityTabBar extends StatelessWidget {
  final int    selectedIndex;
  final int    followerCount;
  final int    favouriteCount;
  final int    alwaysOnlineCount;
  final void Function(int) onTabChange;

  const _CommunityTabBar({
    required this.selectedIndex,
    required this.followerCount,
    required this.favouriteCount,
    required this.alwaysOnlineCount,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    final tabs = [
      {'title': 'Followers',     'count': followerCount.toString()},
      {'title': 'Favourites',    'count': favouriteCount.toString()},
      {'title': 'Always Online', 'count': alwaysOnlineCount.toString()},
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
                          fontSize  : 12,
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
                    color : isSelected
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
}

// ─── Followers Tab ────────────────────────────────────────────────────────────

class _FollowersTab extends StatelessWidget {
  final List<CommunityUser>            users;
  final bool                           loading;
  final TextEditingController          searchCtrl;
  final void Function(String)          onSearch;
  final Future<void> Function(CommunityUser) onToggleFav;

  const _FollowersTab({
    required this.users,
    required this.loading,
    required this.searchCtrl,
    required this.onSearch,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child  : _SearchBar(ctrl: searchCtrl, onSearch: onSearch),
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (users.isEmpty)
          const Expanded(child: _EmptyState(message: 'No followers yet'))
        else
          Expanded(
            child: ListView.builder(
              padding    : const EdgeInsets.all(12),
              itemCount  : users.length,
              itemBuilder: (ctx, i) => _UserCard(
                user        : users[i],
                showFavIcon : true,
                onToggleFav : () => onToggleFav(users[i]),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Favourites Tab ───────────────────────────────────────────────────────────

class _FavouritesTab extends StatelessWidget {
  final List<CommunityUser>                     users;
  final bool                                    loading;
  final TextEditingController                   searchCtrl;
  final void Function(String)                   onSearch;
  final Future<void> Function(CommunityUser)    onToggleFav;
  final Future<void> Function(CommunityUser, bool) onToggleAO;

  const _FavouritesTab({
    required this.users,
    required this.loading,
    required this.searchCtrl,
    required this.onSearch,
    required this.onToggleFav,
    required this.onToggleAO,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child  : _SearchBar(ctrl: searchCtrl, onSearch: onSearch),
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (users.isEmpty)
          const Expanded(
            child: _EmptyState(
              message: 'No favourites yet.\nTap ❤️ on a follower to add them here.',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding    : const EdgeInsets.all(12),
              itemCount  : users.length,
              itemBuilder: (ctx, i) => _UserCard(
                user          : users[i],
                showFavIcon   : true,
                showAOToggle  : true,
                onToggleFav   : () => onToggleFav(users[i]),
                onToggleAO    : (val) => onToggleAO(users[i], val),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Always Online Tab ────────────────────────────────────────────────────────

class _AlwaysOnlineTab extends StatelessWidget {
  final List<CommunityUser>                     users;
  final bool                                    loading;
  final TextEditingController                   searchCtrl;
  final String                                  sortBy;
  final void Function(String)                   onSearch;
  final VoidCallback                            onShowSort;
  final Future<void> Function(CommunityUser, bool) onToggleAO;

  const _AlwaysOnlineTab({
    required this.users,
    required this.loading,
    required this.searchCtrl,
    required this.sortBy,
    required this.onSearch,
    required this.onShowSort,
    required this.onToggleAO,
  });

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          width  : double.infinity,
          color  : isDark
              ? AppTheme.primaryYellow.withOpacity(0.10)
              : const Color(0xFFFFF8E1),
          padding: const EdgeInsets.all(12),
          child  : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.wifi, color: AppTheme.accentRed, size: 18),
                const SizedBox(width: 6),
                Text('Always Online',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize  : 13,
                        color     : c.text)),
              ]),
              const SizedBox(height: 6),
              Text(
                'Loyal customers (spoken ≥ 15 min with you) appear here. '
                'Toggle ON to let them start a session even when you are offline.',
                style: TextStyle(fontSize: 11, color: c.subText),
              ),
            ],
          ),
        ),

        // Search + Sort
        Padding(
          padding: const EdgeInsets.all(12),
          child  : Row(
            children: [
              Expanded(child: _SearchBar(ctrl: searchCtrl, onSearch: onSearch)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onShowSort,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
              ),
            ],
          ),
        ),

        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (users.isEmpty)
          const Expanded(
            child: _EmptyState(
              message:
                  'No loyal customers yet.\nCustomers who have spoken ≥ 15 min with you will appear here.',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding    : const EdgeInsets.symmetric(horizontal: 12),
              itemCount  : users.length,
              itemBuilder: (ctx, i) => _AlwaysOnlineCard(
                user      : users[i],
                onToggleAO: (val) => onToggleAO(users[i], val),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Reusable Search Bar ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final void Function(String) onSearch;

  const _SearchBar({required this.ctrl, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return TextField(
      controller: ctrl,
      style     : TextStyle(color: c.text),
      onChanged : onSearch,
      decoration: InputDecoration(
        hintText       : 'Search by Name',
        hintStyle      : TextStyle(color: c.subText),
        filled         : true,
        fillColor      : isDark ? c.toggleBg : Colors.grey.shade50,
        prefixIcon     : Icon(Icons.search, color: c.subText),
        suffixIcon     : ctrl.text.isNotEmpty
            ? IconButton(
                icon    : Icon(Icons.clear, color: c.subText),
                onPressed: () { ctrl.clear(); onSearch(''); },
              )
            : null,
        contentPadding : const EdgeInsets.symmetric(vertical: 0),
        border         : OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide  : BorderSide(color: c.border)),
        enabledBorder  : OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide  : BorderSide(color: c.border)),
        focusedBorder  : OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide  : BorderSide(color: AppTheme.primaryYellow, width: 2)),
      ),
    );
  }
}

// ─── User Card (Followers & Favourites) ──────────────────────────────────────

class _UserCard extends StatelessWidget {
  final CommunityUser user;
  final bool          showFavIcon;
  final bool          showAOToggle;
  final VoidCallback? onToggleFav;
  final void Function(bool)? onToggleAO;

  const _UserCard({
    required this.user,
    this.showFavIcon  = false,
    this.showAOToggle = false,
    this.onToggleFav,
    this.onToggleAO,
  });

  @override
  Widget build(BuildContext context) {
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
          // ── Header row ──
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius         : 20,
                backgroundImage: user.profileImg.isNotEmpty
                    ? NetworkImage(user.profileImg)
                    : null,
                backgroundColor: AppTheme.primaryYellow.withOpacity(0.2),
                child          : user.profileImg.isEmpty
                    ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.black))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(user.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color     : c.text)),
                        ),
                        if (user.isLoyal)
                          Container(
                            margin : const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color       : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Loyal',
                                style: TextStyle(
                                    fontSize: 10,
                                    color   : Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                        if (showFavIcon)
                          GestureDetector(
                            onTap: onToggleFav,
                            child: Icon(
                              user.isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: user.isFavourite
                                  ? Colors.red
                                  : c.subText,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    Text('${user.totalSessions} sessions · ${user.totalMinutes.toStringAsFixed(0)} min',
                        style: TextStyle(fontSize: 11, color: c.subText)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Stats row ──
          Row(
            children: [
              _StatBox(context, 'Spent with you', '₹ ${user.totalSpent.toStringAsFixed(0)}'),
              const SizedBox(width: 8),
              _StatBox(context, 'Last Session',
                  user.lastSession.length >= 10
                      ? user.lastSession.substring(0, 10)
                      : user.lastSession.isEmpty ? '—' : user.lastSession),
              const SizedBox(width: 8),
              _StatBox(context, 'Sessions', user.totalSessions.toString()),
            ],
          ),

          // ── Always Online toggle (shown in Favourites tab) ──
          if (showAOToggle) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Always Online',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize  : 12,
                            color     : c.text)),
                    Text('Allow offline session requests',
                        style: TextStyle(fontSize: 10, color: c.subText)),
                  ],
                ),
                user.isLoyal
                    ? Switch(
                        value     : user.isAlwaysOnline,
                        onChanged : onToggleAO,
                        activeColor: AppTheme.primaryYellow,
                      )
                    : Tooltip(
                        message: 'Only loyal customers (≥ 15 min) can be granted this',
                        child   : Switch(
                          value    : false,
                          onChanged: null,
                          activeColor: Colors.grey,
                        ),
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _StatBox(BuildContext context, String label, String value) {
    final c      = context.colors;
    final isDark = context.isDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color       : isDark ? c.toggleBg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style    : TextStyle(fontSize: 10, color: c.subText),
                textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(value,
                style    : TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize  : 12,
                    color     : c.text),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Always Online Card ───────────────────────────────────────────────────────

class _AlwaysOnlineCard extends StatelessWidget {
  final CommunityUser               user;
  final void Function(bool)         onToggleAO;

  const _AlwaysOnlineCard({
    required this.user,
    required this.onToggleAO,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Avatar
          CircleAvatar(
            radius         : 22,
            backgroundImage: user.profileImg.isNotEmpty
                ? NetworkImage(user.profileImg)
                : null,
            backgroundColor: AppTheme.primaryYellow.withOpacity(0.2),
            child          : user.profileImg.isEmpty
                ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.black))
                : null,
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 4),
                Text('Spent — ₹ ${user.totalSpent.toStringAsFixed(0)}',
                    style: TextStyle(color: c.subText, fontSize: 12)),
                Text(
                  'Last session — ${user.lastSession.length >= 10 ? user.lastSession.substring(0, 10) : (user.lastSession.isEmpty ? "—" : user.lastSession)}',
                  style: TextStyle(fontSize: 11, color: c.subText),
                ),
              ],
            ),
          ),

          // Toggle
          Switch(
            value      : user.isAlwaysOnline,
            onChanged  : onToggleAO,
            activeColor: AppTheme.primaryYellow,
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child  : Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            Icon(Icons.people_outline, size: 56, color: c.subText),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style    : TextStyle(color: c.subText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}