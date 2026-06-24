// lib/features/Settings/PriceChangeRequest.dart
//
// FULLY CONNECTED to real APIs:
//  - price_increase_eligibility  → loads current rates + busy minutes
//  - submit_price_increase       → submits request with validation
//  - chat_call_request_list      → history tab
// All hardcoded strings replaced with live data.

import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/PriceIncreaseRequestModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

// ── Eligibility model ─────────────────────────────────────────────────────────
class _EligibilityData {
  final int    perMinChat;
  final int    perMinVoice;
  final int    perMinVideo;
  final double busyMinutes;
  final double requiredMinutes;
  final double remainingMinutes;
  final bool   isEligible;
  final List<Map<String, dynamic>> pendingRequests;

  const _EligibilityData({
    required this.perMinChat,
    required this.perMinVoice,
    required this.perMinVideo,
    required this.busyMinutes,
    required this.requiredMinutes,
    required this.remainingMinutes,
    required this.isEligible,
    required this.pendingRequests,
  });

  factory _EligibilityData.fromJson(Map<String, dynamic> j) => _EligibilityData(
    perMinChat      : _i(j['per_min_chat']),
    perMinVoice     : _i(j['per_min_voice_call']),
    perMinVideo     : _i(j['per_min_video_call']),
    busyMinutes     : _d(j['busy_minutes_30_days']),
    requiredMinutes : _d(j['required_minutes']),
    remainingMinutes: _d(j['remaining_minutes']),
    isEligible      : j['is_eligible'] == true,
    pendingRequests : (j['pending_requests'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
  );

  static int    _i(dynamic v) => int.tryParse(v?.toString()    ?? '0') ?? 0;
  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  double get progressPercent =>
      (busyMinutes / requiredMinutes).clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
class Pricechangerequest extends StatefulWidget {
  const Pricechangerequest({super.key});

  @override
  State<Pricechangerequest> createState() => _PricechangerequestState();
}

class _PricechangerequestState extends State<Pricechangerequest> {
  bool               _isLoading   = true;
  _EligibilityData?  _eligibility;
  List<ChatCallRequest>? _history;
  String?            _error;

  // Selected type for submit dialog
  String _selectedType = 'chat';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Load both tabs' data in parallel ─────────────────────────────────────
  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiClient().post(
          'astrologer_api/price_increase_eligibility', {},
          isAuthRequired: true,
        ),
        ApiService().PriceIncreaseRequestList(),
      ]);

      final eligRes = results[0] as dynamic;
      final histRes = results[1] as ChatCallResponse;

      if (!mounted) return;

      final eligJson = jsonDecode(eligRes.body) as Map<String, dynamic>;
      setState(() {
        if (eligJson['result'] == true) {
          _eligibility = _EligibilityData.fromJson(
              eligJson['data'] as Map<String, dynamic>);
        }
        _history    = histRes.chatCallRequest ?? [];
        _isLoading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Submit price increase request ─────────────────────────────────────────
  Future<void> _submitRequest(String type, int price) async {
    try {
      final res = await ApiClient().post(
        'astrologer_api/submit_price_increase',
        {'type': type, 'price': price},
        isAuthRequired: true,
      );
      if (!mounted) return;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final ok   = json['result'] == true;
      _showSnack(
        json['message']?.toString() ??
            (ok ? 'Request submitted!' : 'Failed to submit'),
        error: !ok,
      );
      if (ok) _loadAll(); // refresh both tabs
    } catch (e) {
      if (mounted) _showSnack('Network error. Please try again.', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Show price-input dialog ───────────────────────────────────────────────
  void _showPriceDialog(String type, int currentRate) {
    final c      = context.colors;
    final ctrl   = TextEditingController(text: (currentRate + 5).toString());
    bool  loading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Request ${type[0].toUpperCase()}${type.substring(1)} Price Increase',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: c.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current: ₹$currentRate/min',
                  style: TextStyle(color: c.subText, fontSize: 13)),
              const SizedBox(height: 12),
              TextFormField(
                controller  : ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style       : TextStyle(color: c.text),
                decoration  : InputDecoration(
                  labelText: 'New price (₹/min)',
                  border   : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide  : BorderSide(
                        color: AppTheme.primaryYellow, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: c.subText)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final price = int.tryParse(ctrl.text.trim()) ?? 0;
                      if (price <= currentRate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'New price must be higher than current rate')),
                        );
                        return;
                      }
                      setDialog(() => loading = true);
                      Navigator.pop(ctx);
                      await _submitRequest(type, price);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
        title: const Text('Price Increase'),
        actions: [
          IconButton(
            icon     : Icon(Icons.refresh, color: c.text),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : _error != null
              ? _buildError(c)
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // ── Tab bar ─────────────────────────────────────────
                      Container(
                        color : c.surface,
                        child : TabBar(
                          dividerColor        : Colors.transparent,
                          labelColor          : Colors.black,
                          unselectedLabelColor: isDark
                              ? Colors.white54
                              : Colors.black54,
                          indicator: BoxDecoration(
                              color: AppTheme.primaryYellow),
                          tabs: const [
                            Tab(text: 'Increase Price'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildIncreasePriceTab(c, isDark),
                            _buildHistoryTab(c, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(AppColors c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: c.subText),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: c.subText), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon : const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Increase Price Tab ────────────────────────────────────────────────────
  Widget _buildIncreasePriceTab(AppColors c, bool isDark) {
    final e = _eligibility;
    if (e == null) {
      return Center(child: Text('No data available', style: TextStyle(color: c.subText)));
    }

    final rates = [
      (type: 'chat',  label: 'Chat',       rate: e.perMinChat,  icon: Icons.chat_bubble_rounded),
      (type: 'audio', label: 'Voice Call', rate: e.perMinVoice, icon: Icons.phone_rounded),
      (type: 'video', label: 'Video Call', rate: e.perMinVideo, icon: Icons.videocam_rounded),
    ];

    return RefreshIndicator(
      onRefresh: _loadAll,
      color    : AppTheme.primaryYellow,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: FigmaSize.h(18)),

            // ── Rate cards ─────────────────────────────────────────────
            ...rates.map((r) => _rateCard(r.type, r.label, r.rate, r.icon, e, c, isDark)),

            SizedBox(height: FigmaSize.h(24)),

            // ── Progress card ──────────────────────────────────────────
            _progressCard(e, c, isDark),

            SizedBox(height: FigmaSize.h(24)),

            // ── T&C ───────────────────────────────────────────────────
            Text('Terms & Conditions',
                style: TextStyle(
                    fontSize  : FigmaSize.w(14),
                    color     : c.text,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: FigmaSize.h(12)),
            _tcCard(c, isDark),

            SizedBox(height: FigmaSize.h(32)),
          ],
        ),
      ),
    );
  }

  // ── Rate card with Increase Price button ──────────────────────────────────
  Widget _rateCard(
    String     type,
    String     label,
    int        rate,
    IconData   icon,
    _EligibilityData e,
    AppColors  c,
    bool       isDark,
  ) {
    final hasPending = e.pendingRequests
        .any((r) => r['type']?.toString() == type);

    return Container(
      margin : EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16), vertical: FigmaSize.h(14)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: const Color(0xFFFED402)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width : 32, height: 32,
                decoration: BoxDecoration(
                  color       : AppTheme.primaryYellow.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: Colors.orange.shade800),
              ),
              SizedBox(width: FigmaSize.w(10)),
              Text(label,
                  style: TextStyle(
                      fontSize  : FigmaSize.w(13),
                      color     : c.subText,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹ $rate/min',
                style: TextStyle(
                    fontSize  : FigmaSize.w(22),
                    fontWeight: FontWeight.w700,
                    color     : c.text),
              ),
              hasPending
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color       : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border      : Border.all(
                            color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                            color     : Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize  : 13),
                      ),
                    )
                  : GestureDetector(
                      onTap: e.isEligible
                          ? () => _showPriceDialog(type, rate)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: e.isEligible
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFCD417),
                                    Color(0xFFFFE569)
                                  ])
                              : null,
                          color       : e.isEligible
                              ? null
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Increase Price',
                          style: TextStyle(
                            color     : e.isEligible
                                ? Colors.black
                                : Colors.grey.shade500,
                            fontSize  : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress card ─────────────────────────────────────────────────────────
  Widget _progressCard(_EligibilityData e, AppColors c, bool isDark) {
    final pct     = (e.progressPercent * 100).toStringAsFixed(0);
    final busy    = e.busyMinutes.toStringAsFixed(0);
    final required= e.requiredMinutes.toStringAsFixed(0);
    final remain  = e.remainingMinutes.toStringAsFixed(0);

    return Container(
      padding   : EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(12),
        border      : Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                e.isEligible
                    ? Icons.check_circle_rounded
                    : Icons.timer_outlined,
                color: e.isEligible ? Colors.green : Colors.orange,
                size : 18,
              ),
              SizedBox(width: FigmaSize.w(8)),
              Expanded(
                child: Text(
                  e.isEligible
                      ? 'You are eligible for a price increase! 🎉'
                      : 'You need $remain more minutes to be eligible.',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(13),
                    color     : e.isEligible ? Colors.green : c.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(14)),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value          : e.progressPercent,
              minHeight      : 10,
              backgroundColor: Colors.grey.shade200,
              valueColor     : AlwaysStoppedAnimation<Color>(
                  e.isEligible ? Colors.green : AppTheme.primaryYellow),
            ),
          ),

          SizedBox(height: FigmaSize.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$busy / $required mins  ($pct%)',
                  style: TextStyle(
                      fontSize: FigmaSize.w(12), color: c.subText)),
              Text('Last 30 days',
                  style: TextStyle(
                      fontSize: FigmaSize.w(11), color: c.subText)),
            ],
          ),

          SizedBox(height: FigmaSize.h(16)),

          // Progress table
          Row(children: [
            _tabItem('My Busy Time',   c, isDark, topLeft : true),
            _tabItem('Required Time',  c, isDark),
            _tabItem('Status',         c, isDark, topRight: true),
          ]),
          Row(children: [
            _tabItem('$busy min',  c, isDark, isHeader: false),
            _tabItem('$required min', c, isDark, isHeader: false),
            _tabItem(
              e.isEligible ? 'Eligible ✅' : 'Not yet',
              c, isDark,
              isHeader: false,
              valueColor: e.isEligible ? Colors.green : Colors.orange,
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color       : e.isEligible
                  ? Colors.green.withOpacity(0.08)
                  : Colors.orange.withOpacity(0.08),
              border      : Border.all(color: c.border),
              borderRadius: const BorderRadius.only(
                bottomLeft : Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                e.isEligible
                    ? 'Congratulations! Tap "Increase Price" to submit a request.'
                    : 'Only $remain mins more to be eligible for price increase.',
                style: TextStyle(
                  color     : e.isEligible ? Colors.green : c.text,
                  fontSize  : 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── T&C card ──────────────────────────────────────────────────────────────
  Widget _tcCard(AppColors c, bool isDark) {
    final terms = [
      'The astrologer must have completed at least 500 minutes of consultation in the last 30 days to be eligible for a price increase.',
      'Only one price increase request per service type (chat / audio / video) can be pending at a time.',
      'Price increase requests are subject to admin approval and may take 2-5 business days.',
    ];

    return Container(
      padding   : EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(10),
        border      : Border.all(color: c.border),
      ),
      child: Column(
        children: terms.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: e.key < terms.length - 1 ? 12 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width : 22, height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${e.key + 1}',
                      style: const TextStyle(
                          fontSize  : 11,
                          fontWeight: FontWeight.w700,
                          color     : Colors.black)),
                ),
              ),
              SizedBox(width: FigmaSize.w(10)),
              Expanded(
                child: Text(
                  e.value,
                  style: TextStyle(
                      fontSize  : FigmaSize.w(12),
                      color     : c.subText,
                      height    : 1.5),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────
  Widget _buildHistoryTab(AppColors c, bool isDark) {
    if (_history == null || _history!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 48,
                color: c.subText.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text('No requests yet',
                style: TextStyle(color: c.subText, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color    : AppTheme.primaryYellow,
      child    : ListView.builder(
        padding  : EdgeInsets.all(FigmaSize.w(16)),
        itemCount: _history!.length,
        itemBuilder: (context, index) {
          final item = _history![index];
          final status = item.status?.toLowerCase() ?? '';
          final statusColor = status == 'approved'
              ? Colors.green
              : status == 'rejected'
                  ? Colors.red
                  : Colors.orange;
          final statusIcon = status == 'approved'
              ? Icons.check_circle
              : status == 'rejected'
                  ? Icons.cancel
                  : Icons.hourglass_empty;

          return Container(
            margin : EdgeInsets.only(bottom: FigmaSize.h(12)),
            padding: EdgeInsets.all(FigmaSize.w(14)),
            decoration: BoxDecoration(
              color       : c.surface,
              borderRadius: BorderRadius.circular(10),
              border      : Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        (item.type ?? '').toString().toUpperCase(),
                        style: TextStyle(
                            fontSize  : FigmaSize.w(13),
                            fontWeight: FontWeight.w700,
                            color     : c.text),
                      ),
                      SizedBox(width: FigmaSize.w(6)),
                      Icon(Icons.arrow_forward,
                          size: 14, color: c.subText),
                      SizedBox(width: FigmaSize.w(6)),
                      Text(
                        '₹ ${item.price}',
                        style: TextStyle(
                            fontSize  : FigmaSize.w(13),
                            fontWeight: FontWeight.w700,
                            color     : c.text),
                      ),
                    ]),
                    SizedBox(height: FigmaSize.h(6)),
                    Text(
                      item.createdAt ?? '',
                      style: TextStyle(
                          fontSize  : FigmaSize.w(11),
                          color     : c.subText),
                    ),
                    if ((item.adminComment ?? '').isNotEmpty) ...[
                      SizedBox(height: FigmaSize.h(4)),
                      Text(
                        'Admin: ${item.adminComment}',
                        style: TextStyle(
                            fontSize : FigmaSize.w(11),
                            color    : c.subText,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                Row(children: [
                  Icon(statusIcon, size: 15, color: statusColor),
                  SizedBox(width: FigmaSize.w(4)),
                  Text(
                    item.status?.toString() ?? '',
                    style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.w600,
                        color     : statusColor),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Table cell ────────────────────────────────────────────────────────────
  Widget _tabItem(
    String    title,
    AppColors c,
    bool      isDark, {
    bool   topLeft   = false,
    bool   topRight  = false,
    bool   isHeader  = true,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        decoration: BoxDecoration(
          color : isDark
              ? c.toggleBg
              : (isHeader ? const Color(0xFFFFFCF0) : Colors.white),
          border: Border.all(color: c.border),
          borderRadius: topLeft
              ? const BorderRadius.only(topLeft : Radius.circular(10))
              : topRight
                  ? const BorderRadius.only(topRight: Radius.circular(10))
                  : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize  : FigmaSize.w(11),
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
              color     : valueColor ?? c.text,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}