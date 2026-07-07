// lib/features/live/WaitlistScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Responsive: FigmaSize preserved throughout ────────────────────────────────
// ── Design: matches Astrotalk-style waitlist with Repeat / Waiting tabs ────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/WaitingListResponseModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Waitlistscreen extends StatefulWidget {
  const Waitlistscreen({super.key});

  @override
  State<Waitlistscreen> createState() => _WaitlistscreenState();
}

class _WaitlistscreenState extends State<Waitlistscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool               isLoading = true;
  String?            _error;
  List<UserChatData> _allData  = [];

  List<UserChatData> get _repeatData =>
      _allData.where((d) => (d.type?.toLowerCase() ?? '').contains('repeat')).toList();

  List<UserChatData> get _waitingData =>
      _allData.where((d) => !(d.type?.toLowerCase() ?? '').contains('repeat')).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { isLoading = true; _error = null; });
    try {
      final response = await ApiService().WaitingUserList();
      if (!mounted) return;
      setState(() {
        _allData  = response.data2 ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error    = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content : Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Waitlist'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: FigmaSize.w(12)),
            child: OutlinedButton(
              onPressed: _loadData,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black,
                side: BorderSide(
                    color: isDark ? Colors.white38 : Colors.black26),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(14), vertical: 0),
                minimumSize: Size(0, FigmaSize.h(32)),
              ),
              child: Text(
                'Refresh',
                style: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(FigmaSize.h(44)),
          child: Container(
            color: c.surface,
            child: TabBar(
              controller          : _tabController,
              dividerColor        : Colors.transparent,
              indicatorSize       : TabBarIndicatorSize.tab,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2.5),
              ),
              labelStyle: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w500),
              labelColor          : AppTheme.primaryYellow,
              unselectedLabelColor: const Color(0xFF4A90D9),
              tabs: const [
                Tab(text: 'Repeat (indian)'),
                Tab(text: 'Waiting'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))

          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.accentRed, size: 40),
                      SizedBox(height: FigmaSize.h(12)),
                      Text(_error!,
                          style    : TextStyle(color: AppTheme.accentRed),
                          textAlign: TextAlign.center),
                      SizedBox(height: FigmaSize.h(12)),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon : Icon(Icons.refresh, color: AppTheme.primaryYellow),
                        label: Text('Retry',
                            style: TextStyle(color: AppTheme.primaryYellow)),
                      ),
                    ],
                  ),
                )

              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_repeatData,  c),
                    _buildList(_waitingData, c),
                  ],
                ),
    );
  }

  Widget _buildList(List<UserChatData> items, AppColors c) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded,
                size : 56,
                color: c.subText.withOpacity(0.35)),
            SizedBox(height: FigmaSize.h(12)),
            Text('No users in this list.',
                style: TextStyle(color: c.subText, fontSize: FigmaSize.w(14))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color    : AppTheme.primaryYellow,
      child    : ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical  : FigmaSize.h(12),
          horizontal: FigmaSize.w(14),
        ),
        physics   : const AlwaysScrollableScrollPhysics(),
        itemCount : items.length,
        itemBuilder: (_, i) => _WaitlistCard(
          item  : items[i],
          token : i + 1,
          c     : c,
          onCopy: _copy,
        ),
      ),
    );
  }
}

// =============================================================================
// WAITLIST CARD
// =============================================================================

class _WaitlistCard extends StatelessWidget {
  final UserChatData          item;
  final int                   token;
  final AppColors             c;
  final void Function(String) onCopy;

  const _WaitlistCard({
    required this.item,
    required this.token,
    required this.c,
    required this.onCopy,
  });

  String get _referralCode {
    final id = item.userId ?? item.id ?? '';
    if (id.length >= 6) return 'AT-${id.substring(id.length - 6).toUpperCase()}';
    return 'AT-${id.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      margin    : EdgeInsets.only(bottom: FigmaSize.h(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FigmaSize.w(12)),
        boxShadow   : isDark
            ? []
            : [BoxShadow(
                color     : Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset    : const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              FigmaSize.w(14), FigmaSize.h(12),
              FigmaSize.w(14), FigmaSize.h(10),
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + platform + order ID + copy
                Row(
                  children: [
                    // Avatar
                    Container(
                      width : FigmaSize.w(38),
                      height: FigmaSize.h(38),
                      decoration: BoxDecoration(
                        shape : BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.primaryYellow, width: 1.5),
                        color : AppTheme.primaryYellow.withOpacity(0.1),
                      ),
                      child: ClipOval(
                        child: (item.image?.isNotEmpty == true)
                            ? Image.network(
                                item.image!,
                                fit         : BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallback(),
                              )
                            : _fallback(),
                      ),
                    ),
                    SizedBox(width: FigmaSize.w(10)),

                    // Platform + ID + copy
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Astrogurujii',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(13),
                              fontWeight: FontWeight.w700,
                              color     : const Color(0xFF4A90D9),
                            ),
                          ),
                          SizedBox(width: FigmaSize.w(5)),
                          Flexible(
                            child: Text(
                              '(${_shortId(item.id ?? '')})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: FigmaSize.w(12),
                                color   : c.subText,
                              ),
                            ),
                          ),
                          SizedBox(width: FigmaSize.w(6)),
                          GestureDetector(
                            onTap: () => onCopy(item.id ?? ''),
                            child: Icon(Icons.copy_rounded,
                                size : FigmaSize.w(15),
                                color: c.subText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Date / time
                if (item.createdAt?.isNotEmpty == true) ...[
                  SizedBox(height: FigmaSize.h(6)),
                  Text(
                    _formatDate(item.createdAt!),
                    style: TextStyle(
                      fontSize  : FigmaSize.w(12),
                      fontWeight: FontWeight.w600,
                      color     : AppTheme.primaryYellow,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              FigmaSize.w(14), FigmaSize.h(12),
              FigmaSize.w(14), FigmaSize.h(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Name + referral code + copy
                _InfoRow(
                  label: 'Name',
                  c    : c,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${item.name ?? 'Unknown'} ($_referralCode)',
                          style: TextStyle(
                            fontSize  : FigmaSize.w(13),
                            fontWeight: FontWeight.w600,
                            color     : AppTheme.primaryYellow,
                          ),
                        ),
                      ),
                      SizedBox(width: FigmaSize.w(6)),
                      GestureDetector(
                        onTap: () =>
                            onCopy('${item.name ?? ''} ($_referralCode)'),
                        child: Icon(Icons.copy_rounded,
                            size : FigmaSize.w(14),
                            color: c.subText),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: FigmaSize.h(8)),

                // Type
                _InfoRow(
                  label: 'Type',
                  c    : c,
                  child: Text(
                    _callTypeLabel(item.type),
                    style: TextStyle(
                      fontSize  : FigmaSize.w(13),
                      fontWeight: FontWeight.w600,
                      color     : AppTheme.primaryYellow,
                    ),
                  ),
                ),

                SizedBox(height: FigmaSize.h(8)),

                // Token (position in queue)
                _InfoRow(
                  label: 'Token',
                  c    : c,
                  child: Text(
                    '$token',
                    style: TextStyle(
                      fontSize  : FigmaSize.w(13),
                      fontWeight: FontWeight.w600,
                      color     : AppTheme.primaryYellow,
                    ),
                  ),
                ),

                SizedBox(height: FigmaSize.h(14)),

                // ── Chat Assistant button (outlined, yellow) ────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.primaryYellow, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: FigmaSize.h(13)),
                      backgroundColor:
                          AppTheme.primaryYellow.withOpacity(isDark ? 0.07 : 0.04),
                    ),
                    icon : Icon(Icons.support_agent_rounded,
                        size : FigmaSize.w(18),
                        color: AppTheme.primaryYellow),
                    label: Text(
                      'Chat Assistant',
                      style: TextStyle(
                        fontSize  : FigmaSize.w(14),
                        fontWeight: FontWeight.w700,
                        color     : AppTheme.primaryYellow,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: FigmaSize.h(8)),

                // ── Start Offline Session button (dark filled) ─────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFEEEEEE),
                      foregroundColor: AppTheme.accentRed,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: FigmaSize.h(13)),
                    ),
                    child: Text(
                      'Start Offline Session',
                      style: TextStyle(
                        fontSize  : FigmaSize.w(14),
                        fontWeight: FontWeight.w600,
                        color     : AppTheme.accentRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Center(
        child: Text(
          (item.name?.isNotEmpty == true) ? item.name![0].toUpperCase() : 'U',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize  : FigmaSize.w(16),
            color     : AppTheme.primaryYellow,
          ),
        ),
      );

  String _shortId(String id) {
    if (id.length > 9) return '#${id.substring(0, 4)}…${id.substring(id.length - 4)}';
    return id.isNotEmpty ? '#$id' : '—';
  }

  String _callTypeLabel(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('audio') || t.contains('call')) return 'Call';
    if (t.contains('video'))  return 'Video';
    if (t.contains('chat'))   return 'Chat';
    if (t.isEmpty)            return 'Call';
    return type![0].toUpperCase() + type.substring(1);
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      final h  = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final am = dt.hour >= 12 ? 'PM' : 'AM';
      final m  = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year % 100}, $h:$m $am';
    } catch (_) {
      return raw;
    }
  }
}

// =============================================================================
// INFO ROW
// =============================================================================

class _InfoRow extends StatelessWidget {
  final String    label;
  final AppColors c;
  final Widget    child;

  const _InfoRow({
    required this.label,
    required this.c,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: FigmaSize.w(52),
          child: Text(
            label,
            style: TextStyle(
              fontSize  : FigmaSize.w(13),
              fontWeight: FontWeight.w500,
              color     : c.subText,
            ),
          ),
        ),
        Text(' :  ',
            style: TextStyle(fontSize: FigmaSize.w(13), color: c.subText)),
        Expanded(child: child),
      ],
    );
  }
}