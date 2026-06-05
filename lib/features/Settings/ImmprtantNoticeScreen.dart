import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/components/commonWidget.dart';
import 'package:astrologer_app/features/Settings/components/NotificationDetailModel.dart';
import 'package:astrologer_app/features/service/model/NotificationModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class ImportantNoticeScreen extends StatefulWidget {
  const ImportantNoticeScreen({super.key});

  @override
  State<ImportantNoticeScreen> createState() => _ImportantNoticeScreenState();
}

class _ImportantNoticeScreenState extends State<ImportantNoticeScreen> {
  int  _selectedTab = 0; // 0 = All, 1 = Unread
  bool _isLoading   = true;
  List<AstroNotification> _all    = [];
  List<AstroNotification> _unread = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().AstrologerNotificatinList();
      setState(() {
        _all    = res.notifications;
        _unread = res.notifications.where((n) => !n.isRead).toList();
      });
    } catch (e) {
      debugPrint('❌ ImportantNotice fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AstroNotification> get _active =>
      _selectedTab == 0 ? _all : _unread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: yellowAppBar("Important Notice"),
      body: Column(
        children: [

          // ── Tab bar ──────────────────────────────────────────
          _TabBar(
            selectedTab: _selectedTab,
            unreadCount: _unread.length,
            onChanged:   (i) => setState(() => _selectedTab = i),
          ),

          const Divider(height: 1),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _active.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          itemCount: _active.length,
                          itemBuilder: (_, i) =>
                              _NoticeTile(
                                notification: _active[i],
                                onTap: () => _openDetail(_active[i]),
                              ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openDetail(AstroNotification n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationDetailModal(notification: n),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: Colors.grey.shade300),
          SizedBox(height: FigmaSize.h(12)),
          Text(
            _selectedTab == 1
                ? "No unread notices"
                : "No notices yet",
            style: TextStyle(
              color: Colors.grey,
              fontSize: FigmaSize.w(14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final int selectedTab;
  final int unreadCount;
  final ValueChanged<int> onChanged;

  const _TabBar({
    required this.selectedTab,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabItem(
          title:    "All",
          index:    0,
          selected: selectedTab == 0,
          onTap:    () => onChanged(0),
        ),
        _TabItem(
          title:      "Unread",
          index:      1,
          selected:   selectedTab == 1,
          onTap:      () => onChanged(1),
          badge:      unreadCount,
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final int    index;
  final bool   selected;
  final VoidCallback onTap;
  final int    badge;

  const _TabItem({
    required this.title,
    required this.index,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(height: FigmaSize.h(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: FigmaSize.w(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                // badge for unread count
                if (badge > 0) ...[
                  SizedBox(width: FigmaSize.w(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(6),
                      vertical:   FigmaSize.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCD417),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.toString(),
                      style: TextStyle(
                        fontSize: FigmaSize.w(10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: FigmaSize.h(10)),
            Container(
              height: FigmaSize.h(2),
              width:  FigmaSize.w(110),
              color:  selected ? const Color(0xFFFCD417) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// NOTICE TILE
// ─────────────────────────────────────────────────────────────────
class _NoticeTile extends StatelessWidget {
  final AstroNotification notification;
  final VoidCallback onTap;

  const _NoticeTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16),
          vertical:   FigmaSize.h(12),
        ),
        decoration: BoxDecoration(
          // highlight unread rows
          color: n.isRead ? Colors.white : const Color(0xFFFCD417).withOpacity(0.07),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar ──────────────────────────────────────
            Container(
              height: FigmaSize.h(42),
              width:  FigmaSize.w(42),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFCD417).withOpacity(0.15),
                border: Border.all(color: const Color(0xFFFCD417)),
              ),
              child: Icon(
                Icons.campaign_outlined,
                color: const Color(0xFFFCD417),
                size: FigmaSize.w(22),
              ),
            ),

            SizedBox(width: FigmaSize.w(12)),

            // ── Text content ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   FigmaSize.w(14),
                      color: n.isRead ? Colors.black87 : Colors.black,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(4)),
                  Text(
                    n.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FigmaSize.w(12),
                      color:    Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: date + unread dot ──────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  n.addedOn,
                  style: TextStyle(
                    fontSize: FigmaSize.w(11),
                    color:    Colors.black54,
                  ),
                ),
                SizedBox(height: FigmaSize.h(8)),
                if (!n.isRead)
                  Container(
                    width:  8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCD417),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}