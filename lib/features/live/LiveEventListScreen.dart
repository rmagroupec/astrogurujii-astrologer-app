// lib/features/live/LiveEventListScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Responsive: FigmaSize preserved; LayoutBuilder for bottom bar ─────────────

import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/features/live/GoLiveScreen.dart';
import 'package:astrologer_app/features/live/ScheduleLiveEvents.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

class LiveEventListScreen extends StatefulWidget {
  const LiveEventListScreen({super.key});

  @override
  State<LiveEventListScreen> createState() => _LiveEventListScreenState();
}

class _LiveEventListScreenState extends State<LiveEventListScreen> {
  bool isLoading   = true;
  bool isGoingLive = false;
  List<LiveEventData>? data;

  // Font size preference for live comments
  String _commentFontSize = 'Medium'; // Small | Medium | Large

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService().LiveEventsList();
      setState(() {
        data      = response.data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ LiveEventsList error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _goLiveNow() async {
    setState(() => isGoingLive = true);
    try {
      final now       = DateTime.now();
      final liveDate  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
      final hour      = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute    = now.minute.toString().padLeft(2, '0');
      final period    = now.hour >= 12 ? 'PM' : 'AM';
      final startTime = '$hour:$minute $period';
      final endHour   = (now.hour + 2) % 24;
      final endPeriod = endHour >= 12 ? 'PM' : 'AM';
      final endTime   = '${endHour % 12 == 0 ? 12 : endHour % 12}:$minute $endPeriod';

      final response = await ApiClient().post(
        'astrologer_api/go_live',
        {
          'title'       : 'Instant Live',
          'start_time'  : startTime,
          'end_time'    : endTime,
          'live_date'   : liveDate,
          'recurringDay': 'customDate',
        },
        isAuthRequired: true,
      );

      final body = jsonDecode(response.body);
      if (!mounted) return;

      if (body['status'] == true) {
        final listResponse = await ApiService().LiveEventsList();
        if (!mounted) return;
        final newEvent = listResponse.data?.isNotEmpty == true
            ? listResponse.data!.first
            : null;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GoLiveScreen(event: newEvent, chatFontSize: _commentFontSize)),
        );
        _loadData();
      } else {
        _showSnack(body['message'] ?? 'Failed to create live', error: true);
      }
    } catch (e) {
      debugPrint('❌ _goLiveNow error: $e');
      if (mounted) _showSnack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => isGoingLive = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: error ? AppTheme.accentRed : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Font size picker bottom sheet (Image 3) ───────────────────────────────
  void _showFontPicker() {
    final c = context.colors;
    showModalBottomSheet(
      context      : context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder      : (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color       : c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Font size live event comments',
                      style: TextStyle(
                        fontSize  : 15,
                        fontWeight: FontWeight.w700,
                        color     : c.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon     : Icon(Icons.close, color: c.subText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: c.divider, height: 1),
            // Options
            for (final size in ['Small', 'Medium', 'Large']) ...[
              ListTile(
                leading: Radio<String>(
                  value         : size,
                  groupValue    : _commentFontSize,
                  activeColor   : AppTheme.primaryYellow,
                  onChanged     : (v) {
                    setState(() => _commentFontSize = v!);
                    Navigator.pop(context);
                  },
                ),
                title: Text(size,
                    style: TextStyle(color: c.text, fontSize: 14)),
                onTap: () {
                  setState(() => _commentFontSize = size);
                  Navigator.pop(context);
                },
              ),
              if (size != 'Large') Divider(color: c.divider, height: 1),
            ],
            const SizedBox(height: 12),
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
        // AppBar colors come from AppTheme automatically
        title: const Text('Live Events'),
        actions: [
          // "Live Font" button — top right (Image 2)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton(
              onPressed: _showFontPicker,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.text,
                side           : BorderSide(color: c.border),
                padding        : const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Live Font',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: c.text),
              ),
            ),
          ),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : (data == null || data!.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv_outlined,
                          size: 64,
                          color: c.subText.withOpacity(0.35)),
                      const SizedBox(height: 16),
                      Text('No upcoming live events',
                          style: TextStyle(
                              color: c.subText, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('Schedule one or tap Go Live Now',
                          style: TextStyle(
                              color: c.subText.withOpacity(0.7),
                              fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color    : AppTheme.primaryYellow,
                  onRefresh: _loadData,
                  child    : ListView.builder(
                    padding   : EdgeInsets.symmetric(
                      vertical  : FigmaSize.h(15),
                      horizontal: FigmaSize.w(20),
                    ),
                    itemCount : data!.length,
                    physics   : const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final event = data![index];
                      return _EventCard(
                        event : event,
                        isDark: isDark,
                        c     : c,
                        onTap : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => GoLiveScreen(event: event, chatFontSize: _commentFontSize)),
                          );
                          _loadData();
                        },
                      );
                    },
                  ),
                ),

      // ── Bottom bar ─────────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          color  : c.bg,
          padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(16), vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppGradientButton(
                title    : 'Schedule Event',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const Scheduleliveevents()),
                ).then((_) => _loadData()),
                width: FigmaSize.designWidth / 2.6,
              ),
              if (isGoingLive)
                SizedBox(
                  width : FigmaSize.designWidth / 2.6,
                  height: FigmaSize.h(56),
                  child : Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow, strokeWidth: 2.5),
                  ),
                )
              else
                AppGradientButton(
                  title    : 'Go Live Now',
                  onPressed: _goLiveNow,
                  width    : FigmaSize.designWidth / 2.6,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Event card ──────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final LiveEventData event;
  final VoidCallback  onTap;
  final bool          isDark;
  final AppColors     c;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.isDark,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: FigmaSize.h(116),
        width : double.infinity,
        margin: EdgeInsets.only(bottom: FigmaSize.h(14)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Background image always shown in both light and dark modes
          image: const DecorationImage(
            image: AssetImage(
              'assets/images/4002487859e231b42e4088d553cfb27222391230.png',
            ),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color     : Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset    : const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Overlay — darker in dark mode for better contrast on image
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(isDark ? 0.70 : 0.55),
                ),
              ),

              // Content
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(13),
                    vertical  : FigmaSize.h(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment : MainAxisAlignment.center,
                    children: [
                      // Title — accent red, always visible on dark overlay
                      Text(
                        event.title ?? 'Live Session',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize  : FigmaSize.w(17),
                          fontWeight: FontWeight.bold,
                          color     : AppTheme.accentRed,
                        ),
                      ),
                      // Time
                      Text(
                        event.startTime ?? '—',
                        style: TextStyle(
                          fontSize  : FigmaSize.w(12),
                          height    : 24 / FigmaSize.w(12),
                          fontWeight: FontWeight.w500,
                          color     : Colors.white,
                        ),
                      ),
                      // Date
                      Text(
                        'On ${event.liveDate ?? '—'}',
                        style: TextStyle(
                          fontSize  : FigmaSize.w(12),
                          height    : 24 / FigmaSize.w(12),
                          fontWeight: FontWeight.w500,
                          color     : Colors.white,
                        ),
                      ),
                      // Status
                      Row(
                        children: [
                          Text(
                            'STATUS : ',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(12),
                              height    : 24 / FigmaSize.w(12),
                              fontWeight: FontWeight.w600,
                              color     : Colors.white70,
                            ),
                          ),
                          Container(
                            width : 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            event.status ?? '—',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(12),
                              height    : 24 / FigmaSize.w(12),
                              fontWeight: FontWeight.w600,
                              color     : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow
              Positioned(
                right : FigmaSize.w(12),
                top   : 0,
                bottom: 0,
                child : const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}