// lib/features/Settings/BoostHistoryScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens ──────────────────────────────────
// ── Fetches boost history from API ───────────────────────────────────────────

import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class BoostHistoryItem {
  final String id;
  final String astrologerName;
  final String boostId;
  final String status;      // 'Complete' | 'Active' | 'Pending'
  final String startTime;   // raw ISO / formatted from server
  final String endTime;
  final String serviceType; // 'chat' | 'audio' | 'video'
  final String creationTime;

  const BoostHistoryItem({
    required this.id,
    required this.astrologerName,
    required this.boostId,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.serviceType,
    required this.creationTime,
  });

  factory BoostHistoryItem.fromJson(Map<String, dynamic> j) =>
      BoostHistoryItem(
        id            : j['_id']?.toString()          ?? j['id']?.toString() ?? '',
        astrologerName: j['astrologer_name']?.toString() ?? 'Astrologer',
        boostId       : j['boost_id']?.toString()     ?? j['_id']?.toString() ?? '',
        status        : j['status']?.toString()        ?? 'Complete',
        startTime     : j['start_time']?.toString()    ?? '',
        endTime       : j['end_time']?.toString()      ?? '',
        serviceType   : j['service_type']?.toString()  ?? j['call_type']?.toString() ?? 'chat',
        creationTime  : j['Created_date']?.toString()  ?? j['created_at']?.toString() ?? '',
      );

  /// Duration string: "02:40 PM - 03:10 PM"
  String get durationLabel {
    final s = _fmtTime(startTime);
    final e = _fmtTime(endTime);
    if (s.isEmpty && e.isEmpty) return '—';
    if (e.isEmpty) return s;
    return '$s - $e';
  }

  /// Creation label: "24 Jun 26, 02:40 PM"
  String get creationLabel => _fmtFull(creationTime);

  static String _fmtTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final am = dt.hour >= 12 ? 'PM' : 'AM';
      final m  = dt.minute.toString().padLeft(2, '0');
      return '${h.toString().padLeft(2, '0')}:$m $am';
    } catch (_) {
      return raw;
    }
  }

  static String _fmtFull(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final am = dt.hour >= 12 ? 'PM' : 'AM';
      final m  = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${mo[dt.month - 1]} ${dt.year % 100}, '
             '${h.toString().padLeft(2, '0')}:$m $am';
    } catch (_) {
      return raw;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BoostHistoryScreen extends StatefulWidget {
  const BoostHistoryScreen({super.key});

  @override
  State<BoostHistoryScreen> createState() => _BoostHistoryScreenState();
}

class _BoostHistoryScreenState extends State<BoostHistoryScreen> {
  bool                  _loading = true;
  String?               _error;
  List<BoostHistoryItem> _items  = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await ApiClient().post(
        'astrologer_api/boost_history',
        {},
        isAuthRequired: true,
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] ?? body['results'] ?? []) as List<dynamic>;
      setState(() {
        _items   = list.map((e) => BoostHistoryItem.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Boost History'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _fetch)
              : _items.isEmpty
                  ? _EmptyState(c: c)
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color    : AppTheme.primaryYellow,
                      child    : ListView.builder(
                        padding    : EdgeInsets.symmetric(
                          vertical  : FigmaSize.h(12),
                          horizontal: FigmaSize.w(14),
                        ),
                        itemCount  : _items.length,
                        itemBuilder: (_, i) =>
                            _BoostCard(item: _items[i], c: c),
                      ),
                    ),
    );
  }
}

// ── Boost card — matches Image 2 exactly ──────────────────────────────────────

class _BoostCard extends StatelessWidget {
  final BoostHistoryItem item;
  final AppColors        c;

  const _BoostCard({required this.item, required this.c});

  Color get _statusColor {
    switch (item.status.toLowerCase()) {
      case 'complete': return Colors.green;
      case 'active'  : return AppTheme.primaryYellow;
      default        : return c.subText;
    }
  }

  String get _serviceLabel => item.serviceType.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      margin    : EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding   : EdgeInsets.all(FigmaSize.w(16)),
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

          // Astrologer name (bold, large)
          Text(
            item.astrologerName,
            style: TextStyle(
              fontSize  : FigmaSize.w(16),
              fontWeight: FontWeight.w700,
              color     : c.text,
            ),
          ),

          SizedBox(height: FigmaSize.h(4)),

          // Boost ID (bold)
          Text(
            'Boost Id: ${item.boostId}',
            style: TextStyle(
              fontSize  : FigmaSize.w(14),
              fontWeight: FontWeight.w700,
              color     : c.text,
            ),
          ),

          SizedBox(height: FigmaSize.h(10)),

          // Status
          _Row(
            label: 'Status: ',
            c    : c,
            child: Text(
              item.status,
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w500,
                color     : _statusColor,
              ),
            ),
          ),

          SizedBox(height: FigmaSize.h(4)),

          // Duration
          _Row(
            label: 'Duration: ',
            c    : c,
            child: Text(
              item.durationLabel,
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w400,
                color     : c.text,
              ),
            ),
          ),

          SizedBox(height: FigmaSize.h(4)),

          // Service Type (blue like screenshot)
          _Row(
            label: 'Service Type: ',
            c    : c,
            child: Text(
              _serviceLabel,
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w600,
                color     : const Color(0xFF4A90D9),
              ),
            ),
          ),

          SizedBox(height: FigmaSize.h(4)),

          // Creation Time
          _Row(
            label: 'Creation Time: ',
            c    : c,
            child: Text(
              item.creationLabel,
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w400,
                color     : c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String    label;
  final AppColors c;
  final Widget    child;

  const _Row({required this.label, required this.c, required this.child});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize  : FigmaSize.w(14),
              fontWeight: FontWeight.w400,
              color     : c.text,
            ),
          ),
          Expanded(child: child),
        ],
      );
}

// ── Empty & error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColors c;
  const _EmptyState({required this.c});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch_outlined,
                size : 56,
                color: c.subText.withOpacity(0.35)),
            SizedBox(height: FigmaSize.h(12)),
            Text('No boost history yet.',
                style: TextStyle(color: c.subText, fontSize: FigmaSize.w(14))),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String        error;
  final VoidCallback  onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: AppTheme.accentRed, size: 40),
            SizedBox(height: FigmaSize.h(12)),
            Text(error,
                style    : TextStyle(color: AppTheme.accentRed),
                textAlign: TextAlign.center),
            SizedBox(height: FigmaSize.h(12)),
            TextButton.icon(
              onPressed: onRetry,
              icon : Icon(Icons.refresh, color: AppTheme.primaryYellow),
              label: Text('Retry',
                  style: TextStyle(color: AppTheme.primaryYellow)),
            ),
          ],
        ),
      );
}