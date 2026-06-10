import 'package:astrologer_app/model/VideoCallHistoryModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

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
    fetchHistoryList();
  }

  void fetchHistoryList() async {
    try {
      setState(() => isLoading = true);
      var response = await ApiService().VideoCallHistoryList(widget.page);
      setState(() {
        history = response.data2;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Map raw API status → readable label + color
  ({String label, Color color, Color bg}) _statusStyle(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'end_user':
        return (label: 'Completed', color: Colors.green.shade700, bg: Colors.green.shade50);
      case 'accept_astro':
        return (label: 'Accepted', color: Colors.blue.shade700, bg: Colors.blue.shade50);
      case 'reject_astro':
        return (label: 'Rejected', color: Colors.red.shade700, bg: Colors.red.shade50);
       case 'end_astro':
        return (label: 'Rejected', color: Colors.red.shade700, bg: Colors.red.shade50);
      case 'missed':
        return (label: 'Missed', color: Colors.orange.shade700, bg: Colors.orange.shade50);
      default:
        return (label: raw ?? 'Unknown', color: Colors.grey.shade700, bg: Colors.grey.shade100);
    }
  }

  /// Map callType → icon
  IconData _typeIcon(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'audio': return Icons.phone_rounded;
      case 'video': return Icons.videocam_rounded;
      case 'chat':  return Icons.chat_bubble_rounded;
      default:      return Icons.receipt_long_rounded;
    }
  }

  Color _typeColor(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'audio': return const Color(0xFF2196F3);
      case 'video': return const Color(0xFF9C27B0);
      case 'chat':  return const Color(0xFF4CAF50);
      default:      return const Color(0xFFFFD600);
    }
  }

  String _formatDuration(String? min) {
    final m = int.tryParse(min ?? '') ?? 0;
    if (m == 0) return '< 1 min';
    if (m >= 60) {
      final h = m ~/ 60;
      final rem = m % 60;
      return rem > 0 ? '${h}h ${rem}m' : '${h}h';
    }
    return '${m} min';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD600)),
      );
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No orders yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final st = _statusStyle(item.status);
        final typeColor = _typeColor(item.callType);
        final typeIcon = _typeIcon(item.callType);
        final hasAmount = (item.totalAmount ?? '').isNotEmpty && item.totalAmount != '0';
        final hasImage = (item.userImage ?? '').isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 3),
                color: Colors.black.withOpacity(0.07),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── TOP COLOUR STRIP ─────────────────────────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── HEADER ROW ──────────────────────────────────────────
                    Row(
                      children: [
                        // User avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: typeColor.withOpacity(0.12),
                          backgroundImage: hasImage ? NetworkImage(item.userImage!) : null,
                          child: hasImage
                              ? null
                              : Icon(Icons.person_rounded, color: typeColor, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.userName ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(typeIcon, size: 12, color: typeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    (item.callType ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: typeColor,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: st.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            st.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: st.color,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),

                    // ── ORDER ID ────────────────────────────────────────────
                    Text(
                      'Order #${(item.id ?? '').length > 12 ? item.id!.substring(0, 12) + '…' : item.id ?? ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                    const SizedBox(height: 10),

                    // ── STATS ROW ───────────────────────────────────────────
                    Row(
                      children: [
                        _statChip(Icons.access_time_rounded, _formatDuration(item.callMin), Colors.teal),
                        const SizedBox(width: 8),
                        _statChip(Icons.currency_rupee_rounded, '${item.callRate ?? "0"}/min', Colors.orange),
                        const SizedBox(width: 8),
                        if (hasAmount)
                          _statChip(Icons.account_balance_wallet_rounded, '₹${item.totalAmount}', Colors.green),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── ORDER TIME ──────────────────────────────────────────
                    if ((item.orderTime ?? '').isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.black38),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.orderTime!,
                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 14),

                    // ── ACTION BUTTONS ──────────────────────────────────────
                    Row(
                      children: [
                        _actionBtn('Remedy', Icons.local_pharmacy_rounded, const Color(0xFF6A1B9A)),
                        const SizedBox(width: 8),
                        _actionBtn('Kundli', Icons.auto_awesome_rounded, const Color(0xFFE65100)),
                        const SizedBox(width: 8),
                        _actionBtn('Assistant', Icons.smart_toy_rounded, const Color(0xFF0277BD)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {}, // wire up your actions here
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}