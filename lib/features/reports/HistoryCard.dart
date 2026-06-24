// lib/features/reports/HistoryCard.dart
// ── Full dark / light theme support via AppColors extension ──────────────────
// ── Responsive layout using LayoutBuilder + MediaQuery ───────────────────────
// ── Add Note wired to document icon ──────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/reports/AddNoteSheet.dart';
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

  // tracks favourite state per userId
  final Map<String, bool>   _favouriteState = {};
  final Set<String>         _toggling       = {};

  // ✅ tracks notes per channelId (updated locally after save)
  final Map<String, String> _notes          = {};

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
        history   = response.data2;
        isLoading = false;
        for (final item in history) {
          final uid = item.userId ?? '';
          if (uid.isNotEmpty && !_favouriteState.containsKey(uid)) {
            _favouriteState[uid] = false;
          }
          // seed existing notes from API
          final cid = item.channelId ?? '';
          if (cid.isNotEmpty) {
            _notes[cid] = item.note ?? '';
          }
        }
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFavourite(String userId) async {
    if (userId.isEmpty || _toggling.contains(userId)) return;
    setState(() => _toggling.add(userId));
    final newVal = await ApiService().toggle(userId);
    if (!mounted) return;
    setState(() {
      _toggling.remove(userId);
      if (newVal != null) {
        _favouriteState[userId] = newVal;
        _showSnack(newVal ? '❤️ Added to favourites' : 'Removed from favourites');
      } else {
        _showSnack('Could not update favourite. Please try again.');
      }
    });
  }

  // ✅ opens Add Note sheet, updates local state on save
  Future<void> _openNote(String channelId) async {
    final existing = _notes[channelId] ?? '';
    final saved = await AddNoteSheet.show(
      context,
      channelId:    channelId,
      existingNote: existing,
    );
    if (saved != null && mounted) {
      setState(() => _notes[channelId] = saved);
      _showSnack(saved.isEmpty ? 'Note cleared' : '✅ Note saved');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Status ──────────────────────────────────────────────────────────────────
  ({String label, Color color, IconData icon}) _statusMeta(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'end_user':
        return (label: 'Completed',  color: const Color(0xFF2E7D32), icon: Icons.check_circle_rounded);
      case 'accept_astro':
        return (label: 'Accepted',   color: const Color(0xFF1565C0), icon: Icons.check_circle_rounded);
      case 'reject_astro':
      case 'end_astro':
        return (label: 'Rejected',   color: const Color(0xFFC62828), icon: Icons.cancel_rounded);
      case 'disconnect_user':
        return (label: 'Completed',  color: const Color(0xFF2E7D32), icon: Icons.cancel_rounded);
      case 'missed':
        return (label: 'Missed',     color: const Color(0xFFE65100), icon: Icons.phone_missed_rounded);
      default:
        return (label: raw ?? 'Unknown', color: const Color(0xFF757575), icon: Icons.info_outline_rounded);
    }
  }

  // ── Call type ────────────────────────────────────────────────────────────────
  ({IconData icon, Color color, String label}) _callTypeMeta(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'audio':
        return (icon: Icons.phone_rounded,       color: const Color(0xFF1976D2), label: 'AUDIO');
      case 'video':
        return (icon: Icons.videocam_rounded,    color: const Color(0xFF7B1FA2), label: 'VIDEO');
      case 'chat':
        return (icon: Icons.chat_bubble_rounded, color: const Color(0xFF2E7D32), label: 'CHAT');
      default:
        return (icon: Icons.receipt_long_rounded, color: const Color(0xFFF9A825), label: (type ?? 'UNKNOWN').toUpperCase());
    }
  }

  // ── Duration: "5 minutes (02:17 PM-02:22 PM)" ───────────────────────────────
  String _duration(VideoCallHistory item) {
    final m = int.tryParse(item.callMin ?? item.callDuration ?? '') ?? 0;
    String minLabel;
    if (m == 0)       minLabel = '< 1 Min';
    else if (m >= 60) { final h = m ~/ 60; final r = m % 60; minLabel = r > 0 ? '${h}h ${r} Min' : '${h}h'; }
    else              minLabel = '$m minutes';

    final timeRange = (item.callDurationDisplay ?? '').trim();
    if (timeRange.isNotEmpty) return '$minLabel $timeRange';

    final start = _formatTime(item.startTime);
    final end   = _formatTime(item.endTime);
    if (start.isNotEmpty && end.isNotEmpty) return '$minLabel ($start-$end)';
    return minLabel;
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt     = DateTime.parse(raw).toLocal();
      final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min    = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$min $period';
    } catch (_) {
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final h      = int.tryParse(parts[0]) ?? 0;
        final min    = parts[1].padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final hour   = h % 12 == 0 ? 12 : h % 12;
        return '$hour:$min $period';
      }
      return raw;
    }
  }

  // ── "12 Jun 26, 02:17 PM" ────────────────────────────────────────────────────
  String _formatOrderTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt      = DateTime.parse(raw).toLocal();
      const months  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final day     = dt.day.toString().padLeft(2, '0');
      final month   = months[dt.month - 1];
      final year    = dt.year.toString().substring(2);
      final hour    = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min     = dt.minute.toString().padLeft(2, '0');
      final period  = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, ${hour.toString().padLeft(2,'0')}:$min $period';
    } catch (_) {
      return raw;
    }
  }

  String _shortId(String? id) =>
      id == null || id.isEmpty ? '—' : '#${id.length > 14 ? '${id.substring(0, 14)}…' : id}';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: c.subText.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No history yet', style: TextStyle(fontSize: 16, color: c.subText)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final hPad     = isTablet ? 24.0 : 14.0;

        return RefreshIndicator(
          color    : Theme.of(context).colorScheme.primary,
          onRefresh: _fetchHistory,
          child    : ListView.builder(
            padding  : EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item      = history[index];
              final userId    = item.userId    ?? '';
              final channelId = item.channelId ?? '';
              final isFav     = _favouriteState[userId]   ?? false;
              final toggling  = _toggling.contains(userId);
              final note      = _notes[channelId]         ?? '';
              final hasNote   = note.isNotEmpty;

              return _HistoryItem(
                item        : item,
                c           : c,
                statusMeta  : _statusMeta(item.status),
                callTypeMeta: _callTypeMeta(item.callType),
                duration    : _duration(item),
                shortId     : _shortId(item.id),
                orderTime   : _formatOrderTime(item.orderTime ?? item.createdAt),
                isTablet    : isTablet,
                isFavourite : isFav,
                isToggling  : toggling,
                note        : note,
                hasNote     : hasNote,
                onFavTap    : () => _toggleFavourite(userId),
                onNoteTap   : () => _openNote(channelId),   // ✅ document icon tap
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final VideoCallHistory item;
  final AppColors        c;
  final ({String label, Color color, IconData icon}) statusMeta;
  final ({IconData icon, Color color, String label})  callTypeMeta;
  final String           duration;
  final String           shortId;
  final String           orderTime;
  final bool             isTablet;
  final bool             isFavourite;
  final bool             isToggling;
  final String           note;
  final bool             hasNote;
  final VoidCallback     onFavTap;
  final VoidCallback     onNoteTap;   // ✅ new

  const _HistoryItem({
    required this.item,
    required this.c,
    required this.statusMeta,
    required this.callTypeMeta,
    required this.duration,
    required this.shortId,
    required this.orderTime,
    required this.isTablet,
    required this.isFavourite,
    required this.isToggling,
    required this.note,
    required this.hasNote,
    required this.onFavTap,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final hasImage  = (item.userImage   ?? '').isNotEmpty;
    final hasRemedy = (item.remedy      ?? '').isNotEmpty;
    final totalAmt  = (item.totalAmount ?? '').trim();
    final hasAmount = totalAmt.isNotEmpty && totalAmt != '0';
    final offerLabel = (item.offer      ?? '').trim();
    final hasOffer   = offerLabel.isNotEmpty;
    final isRepeat   = item.isRepeat    ?? false;
    final country    = (item.userCountry ?? '').trim();

    return Container(
      margin    : const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: c.border),
        boxShadow   : isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Colour accent stripe ─────────────────────────────────────
            Container(height: 4, color: callTypeMeta.color),

            // ── TOP HEADER BAR ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Repeat / New chip
                  _Chip(
                    label    : isRepeat ? 'Repeat' : 'New',
                    bg       : isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                    textColor: isRepeat ? const Color(0xFF1565C0) : c.text,
                  ),
                  const SizedBox(width: 5),
                  // Country chip
                  if (country.isNotEmpty) ...[
                    _Chip(
                      label    : country,
                      bg       : isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE),
                      textColor: c.subText,
                    ),
                    const SizedBox(width: 5),
                  ],
                  // LOYAL badge
                  _Chip(label: 'LOYAL', bg: const Color(0xFFFCD417), textColor: Colors.black),
                  const SizedBox(width: 8),
                  // Status
                  Text(statusMeta.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusMeta.color)),
                  const Spacer(),
                  Icon(statusMeta.icon, color: statusMeta.color, size: 18),
                  const SizedBox(width: 8),

                  // ✅ Document / Note icon — highlighted if note exists
                  GestureDetector(
                    onTap    : onNoteTap,
                    behavior : HitTestBehavior.opaque,
                    child    : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          hasNote ? Icons.description_rounded : Icons.description_outlined,
                          size : 20,
                          color: hasNote ? const Color(0xFF0277BD) : c.subText,
                        ),
                        // ✅ small dot indicator when note exists
                        if (hasNote)
                          Positioned(
                            top  : -2,
                            right: -2,
                            child: Container(
                              width : 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color : Color(0xFF0277BD),
                                shape : BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ❤️ Favourite toggle
                  GestureDetector(
                    onTap   : onFavTap,
                    behavior: HitTestBehavior.opaque,
                    child   : AnimatedSwitcher(
                      duration        : const Duration(milliseconds: 250),
                      switchInCurve   : Curves.elasticOut,
                      switchOutCurve  : Curves.easeIn,
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: isToggling
                          ? const SizedBox(
                              key   : ValueKey('spinner'),
                              width : 18,
                              height: 18,
                              child : CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                            )
                          : Icon(
                              isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key  : ValueKey(isFavourite),
                              size : 20,
                              color: isFavourite ? Colors.redAccent : c.subText,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: c.divider),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── ORDER ID + AMOUNT ROW ────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width : 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape : BoxShape.circle,
                          border: Border.all(color: callTypeMeta.color.withOpacity(0.6), width: 2),
                          color : callTypeMeta.color.withOpacity(isDark ? 0.15 : 0.08),
                        ),
                        child: hasImage
                            ? ClipOval(
                                child: Image.network(item.userImage!,
                                    fit         : BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(callTypeMeta.icon, size: 18, color: callTypeMeta.color)),
                              )
                            : Icon(callTypeMeta.icon, size: 18, color: callTypeMeta.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Order id : ',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                                Flexible(
                                  child: Text('($shortId)',
                                      style: TextStyle(fontSize: 11, color: c.subText),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => Clipboard.setData(ClipboardData(text: item.id ?? '')),
                                  child: Icon(Icons.copy_rounded, size: 13, color: c.subText),
                                ),
                              ],
                            ),
                            if (orderTime.isNotEmpty)
                              Text(orderTime, style: TextStyle(fontSize: 10, color: c.subText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹ ${hasAmount ? totalAmt : '0'}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.subText),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: c.divider),
                  const SizedBox(height: 10),

                  // ── DETAIL TABLE ─────────────────────────────────────────
                  _Row(label: 'Name',
                      value: '${item.userName ?? 'Unknown'} (${item.userId ?? ''})', c: c),
                  _Row(label: 'DOB',
                      value: (item.userDob ?? '').isNotEmpty ? item.userDob! : '—', c: c),
                  _Row(label: 'Duration', value: duration, c: c),
                  _Row(label: 'Rate',
                      value: '₹ ${item.callRate ?? '0'}/min', c: c),
                  _Row(label: 'offer',
                      value     : hasOffer ? offerLabel : '—',
                      c         : c,
                      valueColor: hasOffer ? const Color(0xFFE65100) : null),
                  _RowWithCopy(label: 'POB',
                      value: (item.userPob ?? '').isNotEmpty ? item.userPob! : '—', c: c),

                  // ✅ Note preview — shown only when note exists
                  if (hasNote) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onNoteTap,
                      child: Container(
                        width      : double.infinity,
                        padding    : const EdgeInsets.all(10),
                        decoration : BoxDecoration(
                          color       : const Color(0xFF0277BD).withOpacity(isDark ? 0.12 : 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border      : Border.all(color: const Color(0xFF0277BD).withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note_alt_rounded, size: 14, color: Color(0xFF0277BD)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                note,
                                maxLines : 2,
                                overflow : TextOverflow.ellipsis,
                                style    : const TextStyle(fontSize: 12, color: Color(0xFF0277BD)),
                              ),
                            ),
                            const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF0277BD)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── ACTION BUTTONS ────────────────────────────────────────
                  Row(
                    children: [
                      _ActionBtn(label: 'Suggest Remedy', color: const Color(0xFFD81B60), isDark: isDark, onTap: () {}),
                      const SizedBox(width: 8),
                      _ActionBtn(label: 'Open Kundli',   color: const Color(0xFFD81B60), isDark: isDark, onTap: () {}),
                      const SizedBox(width: 8),
                      _ActionBtn(label: 'Chat Assistant', icon: Icons.smart_toy_rounded,
                          color: const Color(0xFF0277BD), isDark: isDark, onTap: () {}),
                    ],
                  ),

                  if (hasRemedy) ...[
                    const SizedBox(height: 8),
                    Text(item.remedy!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD81B60))),
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color  bg;
  final Color  textColor;
  const _Chip({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child     : Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _Row extends StatelessWidget {
  final String    label;
  final String    value;
  final AppColors c;
  final Color?    valueColor;
  const _Row({required this.label, required this.value, required this.c, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child  : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 76,
              child: Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text))),
          Text('  :  ', style: TextStyle(fontSize: 12, color: c.subText)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: valueColor ?? c.subText))),
        ],
      ),
    );
  }
}

class _RowWithCopy extends StatelessWidget {
  final String    label;
  final String    value;
  final AppColors c;
  const _RowWithCopy({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child  : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 76,
              child: Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text))),
          Text('  :  ', style: TextStyle(fontSize: 12, color: c.subText)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: c.subText))),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: Icon(Icons.copy_rounded, size: 14, color: c.subText),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final IconData?    icon;
  final Color        color;
  final bool         isDark;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.isDark, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap : onTap,
        child : Container(
          height    : 36,
          decoration: BoxDecoration(
            color       : isDark ? color.withOpacity(0.12) : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border      : Border.all(color: color.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    overflow : TextOverflow.ellipsis,
                    style    : TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}