// lib/features/reports/HistoryCard.dart
// ── Full dark / light theme support via AppColors extension ──────────────────
// ── Responsive layout using LayoutBuilder + MediaQuery ───────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/model/VideoCallHistoryModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryCard extends StatefulWidget {
  final String page;
  const HistoryCard({super.key, required this.page});

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  List<VideoCallHistory> history = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      setState(() => isLoading = true);
      final response = await ApiService().VideoCallHistoryList(widget.page);
      setState(() {
        history = response.data2;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // ── Status ──────────────────────────────────────────────────────────────────
  ({String label, Color color, IconData icon}) _statusMeta(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'end_user':
        return (
          label: 'Completed',
          color: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case 'accept_astro':
        return (
          label: 'Accepted',
          color: const Color(0xFF1565C0),
          icon: Icons.check_circle_rounded,
        );
      case 'reject_astro':
      case 'end_astro':
        return (
          label: 'Rejected',
          color: const Color(0xFFC62828),
          icon: Icons.cancel_rounded,
        );
      case 'disconnect_user':
        return (
          label: 'Completed',
          color: const Color(0xFF2E7D32),
          icon: Icons.cancel_rounded,
        );
      case 'missed':
        return (
          label: 'Missed',
          color: const Color(0xFFE65100),
          icon: Icons.phone_missed_rounded,
        );
      default:
        return (
          label: raw ?? 'Unknown',
          color: const Color(0xFF757575),
          icon: Icons.info_outline_rounded,
        );
    }
  }

  // ── Call type ────────────────────────────────────────────────────────────────
  ({IconData icon, Color color, String label}) _callTypeMeta(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'audio':
        return (
          icon: Icons.phone_rounded,
          color: const Color(0xFF1976D2),
          label: 'AUDIO',
        );
      case 'video':
        return (
          icon: Icons.videocam_rounded,
          color: const Color(0xFF7B1FA2),
          label: 'VIDEO',
        );
      case 'chat':
        return (
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF2E7D32),
          label: 'CHAT',
        );
      default:
        return (
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFF9A825),
          label: (type ?? 'UNKNOWN').toUpperCase(),
        );
    }
  }

  // ── Duration ─────────────────────────────────────────────────────────────────
  String _duration(String? min) {
    final m = int.tryParse(min ?? '') ?? 0;
    if (m == 0) return '< 1 Min';
    if (m >= 60) {
      final h = m ~/ 60;
      final r = m % 60;
      return r > 0 ? '${h}h ${r} Min' : '${h}h';
    }
    return '$m Minutes';
  }

  // ── Short order ID ────────────────────────────────────────────────────────────
  String _shortId(String? id) =>
      id == null || id.isEmpty ? '—' : '#${id.length > 14 ? '${id.substring(0, 14)}…' : id}';

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: c.subText.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No history yet',
              style: TextStyle(fontSize: 16, color: c.subText),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding: narrow on small screens, wider on tablets
        final isTablet = constraints.maxWidth > 600;
        final hPad = isTablet ? 24.0 : 14.0;

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: _fetchHistory,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
            itemCount: history.length,
            itemBuilder: (context, index) =>
                _HistoryItem(
                  item: history[index],
                  c: c,
                  statusMeta: _statusMeta(history[index].status),
                  callTypeMeta: _callTypeMeta(history[index].callType),
                  duration: _duration(history[index].callMin),
                  shortId: _shortId(history[index].id),
                  isTablet: isTablet,
                ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single card widget — extracted for clean rebuild scoping
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final VideoCallHistory item;
  final AppColors c;
  final ({String label, Color color, IconData icon}) statusMeta;
  final ({IconData icon, Color color, String label}) callTypeMeta;
  final String duration;
  final String shortId;
  final bool isTablet;

  const _HistoryItem({
    required this.item,
    required this.c,
    required this.statusMeta,
    required this.callTypeMeta,
    required this.duration,
    required this.shortId,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = (item.userImage ?? '').isNotEmpty;
    final hasAmount = (item.totalAmount ?? '').isNotEmpty && item.totalAmount != '0';
    final hasRemedy = (item.remedy ?? '').isNotEmpty;

    // Top accent stripe colour follows call type
    final stripeColor = callTypeMeta.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Colour accent stripe ─────────────────────────────────────
            Container(height: 4, color: stripeColor),

            // ── TOP HEADER BAR ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "New" chip
                  _Chip(
                    label: 'New',
                    bg: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                    textColor: c.text,
                  ),
                  const SizedBox(width: 5),
                  // Country / group
                  if ((item.groupId ?? '').isNotEmpty) ...[
                    _Chip(
                      label: item.groupId!,
                      bg: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE),
                      textColor: c.subText,
                    ),
                    const SizedBox(width: 5),
                  ],
                  // LOYAL badge
                  _Chip(
                    label: 'LOYAL',
                    bg: const Color(0xFFFCD417),
                    textColor: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  // Status text
                  Text(
                    statusMeta.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusMeta.color,
                    ),
                  ),
                  const Spacer(),
                  // Status icon
                  Icon(statusMeta.icon, color: statusMeta.color, size: 18),
                  const SizedBox(width: 8),
                  // Report icon
                  Icon(Icons.description_outlined, size: 18, color: c.subText),
                  const SizedBox(width: 8),
                  // Favourite
                  Icon(Icons.favorite_border_rounded,
                      size: 18, color: Colors.redAccent),
                ],
              ),
            ),

            Divider(height: 1, color: c.divider),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── ORDER ID ROW ─────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar circle with call-type icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: callTypeMeta.color.withOpacity(0.6),
                            width: 2,
                          ),
                          color: callTypeMeta.color.withOpacity(
                              isDark ? 0.15 : 0.08),
                        ),
                        child: hasImage
                            ? ClipOval(
                                child: Image.network(
                                  item.userImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    callTypeMeta.icon,
                                    size: 18,
                                    color: callTypeMeta.color,
                                  ),
                                ),
                              )
                            : Icon(callTypeMeta.icon,
                                size: 18, color: callTypeMeta.color),
                      ),
                      const SizedBox(width: 10),

                      // Order ID + time
                      Expanded(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [

      // ── Left: order id + time ──────────────────────────────────
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Order id : ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                Flexible(
                  child: Text(
                    '($shortId)',
                    style: TextStyle(fontSize: 11, color: c.subText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Clipboard.setData(
                      ClipboardData(text: item.id ?? '')),
                  child: Icon(Icons.copy_rounded,
                      size: 13, color: c.subText),
                ),
              ],
            ),
            if ((item.orderTime ?? '').isNotEmpty)
              Text(
                item.orderTime!,
                style: TextStyle(fontSize: 10, color: c.subText),
              ),
          ],
        ),
      ),

      // ── Right: amount ──────────────────────────────────────────
      // if ((item.totalAmount ?? '').isNotEmpty) ...[
        const SizedBox(width: 12),
        Text(
          '₹ ${item.totalAmount} 10',
          style: TextStyle(
            fontSize  : 20,
            fontWeight: FontWeight.w700,
            color     : c.subText,
          ),
        ),
      // ],
    ],
  ),
),

                      // Total amount
                      if (hasAmount)
                        Text(
                          '₹${item.totalAmount}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: c.divider),
                  const SizedBox(height: 10),

                  // ── DETAIL TABLE ─────────────────────────────────────────
                  _Row(label: 'Name',
                      value: '${item.userName ?? 'Unknown'} (${item.userId ?? ''})',
                      c: c),
                  _Row(label: 'Gender', value: '—', c: c),
                  _Row(label: 'DOB',    value: '—', c: c),
                  _Row(label: 'POB',    value: '—', c: c),
                  _Row(label: 'Duration',
                      value: duration, c: c),
                  _Row(label: 'Rate',
                      value: '₹ ${item.callRate ?? '0'}/min', c: c),
                  _Row(label: 'Offer',
                      value: hasAmount
                          ? '${item.totalAmount} (Flat)'
                          : '—',
                      c: c),
                 

                  const SizedBox(height: 12),

                  // ── ACTION BUTTONS ────────────────────────────────────────
                  Row(
                    children: [
                      _ActionBtn(
                        label: 'Suggest Remedy',
                        color: const Color(0xFFD81B60),
                        isDark: isDark,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Open Kundli',
                        color: const Color(0xFFD81B60),
                        isDark: isDark,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Chat Assistant',
                        icon: Icons.smart_toy_rounded,
                        color: const Color(0xFF0277BD),
                        isDark: isDark,
                        onTap: () {},
                      ),
                    ],
                  ),

                  // ── REMEDY / SESSION LABEL ────────────────────────────────
                  if (hasRemedy) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.remedy!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Chip(
      {required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final AppColors c;
  const _Row(
      {required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                )),
          ),
          Text('  :  ',
              style: TextStyle(fontSize: 12, color: c.subText)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: c.subText),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? color.withOpacity(0.12)
                : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}