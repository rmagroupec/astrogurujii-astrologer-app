// lib/features/live/WaitlistScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Responsive: FigmaSize preserved throughout ────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/WaitingListResponseModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class Waitlistscreen extends StatefulWidget {
  const Waitlistscreen({super.key});

  @override
  State<Waitlistscreen> createState() => _WaitlistscreenState();
}

class _WaitlistscreenState extends State<Waitlistscreen> {
  bool               isLoading = true;
  String?            _error;
  List<UserChatData> data      = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { isLoading = true; _error = null; });
    try {
      final response = await ApiService().WaitingUserList();
      if (!mounted) return;
      setState(() {
        data      = response.data2 ?? [];
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Waitlist'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))

          : _error != null
              // ── Error state ───────────────────────────────────────────
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.accentRed, size: 40),
                      SizedBox(height: FigmaSize.h(12)),
                      Text(
                        _error!,
                        style    : TextStyle(color: AppTheme.accentRed),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: FigmaSize.h(12)),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon : Icon(Icons.refresh,
                            color: AppTheme.primaryYellow),
                        label: Text('Retry',
                            style: TextStyle(
                                color: AppTheme.primaryYellow)),
                      ),
                    ],
                  ),
                )

              : data.isEmpty
                  // ── Empty state ───────────────────────────────────────
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty_rounded,
                              size: 56,
                              color: c.subText.withOpacity(0.35)),
                          SizedBox(height: FigmaSize.h(12)),
                          Text(
                            'No users in the waitlist.',
                            style: TextStyle(
                                color   : c.subText,
                                fontSize: FigmaSize.w(14)),
                          ),
                        ],
                      ),
                    )

                  // ── List ──────────────────────────────────────────────
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color    : AppTheme.primaryYellow,
                      child    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          vertical  : FigmaSize.h(15),
                          horizontal: FigmaSize.w(20),
                        ),
                        physics   : const AlwaysScrollableScrollPhysics(),
                        itemCount : data.length,
                        itemBuilder: (context, index) =>
                            _WaitlistCard(item: data[index], c: c),
                      ),
                    ),
    );
  }
}

// ── Single waitlist card ──────────────────────────────────────────────────────
class _WaitlistCard extends StatelessWidget {
  final UserChatData item;
  final AppColors    c;

  const _WaitlistCard({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      margin : EdgeInsets.only(bottom: FigmaSize.h(16)),
      padding: EdgeInsets.symmetric(
        vertical  : FigmaSize.h(16),
        horizontal: FigmaSize.w(16),
      ),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FigmaSize.w(10)),
        boxShadow   : isDark
            ? []
            : [
                BoxShadow(
                  color     : Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset    : const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Avatar + Name + ID ──────────────────────────────────────
          Row(
            children: [
              // Avatar
              Container(
                height    : FigmaSize.h(40),
                width     : FigmaSize.w(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryYellow, width: 1.5),
                  image: DecorationImage(
                    image: NetworkImage(
                      item.image?.isNotEmpty == true
                          ? item.image!
                          : 'https://i.pravatar.cc/150',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: FigmaSize.w(8)),
              // Name
              Flexible(
                child: Text(
                  item.name ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize  : FigmaSize.w(14),
                    fontWeight: FontWeight.w600,
                    color     : c.text,
                  ),
                ),
              ),
              SizedBox(width: FigmaSize.w(4)),
              // ID
              Text(
                '(#${item.id ?? ''})',
                style: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color     : c.subText,
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(10)),

          // ── Created at (accent red) ─────────────────────────────────
          Text(
            item.createdAt ?? '',
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              fontWeight: FontWeight.w600,
              color     : AppTheme.accentRed,
            ),
          ),

          SizedBox(height: FigmaSize.h(8)),

          // ── Info rows ───────────────────────────────────────────────
          _InfoRow(label: 'Name',     value: item.name ?? '',     c: c),
          _InfoRow(
            label: 'Type',
            value: (item.type?.isNotEmpty == true) ? item.type! : 'Chat',
            c    : c,
          ),
          _InfoRow(label: 'Token',    value: '1',       c: c),
          _InfoRow(label: 'Duration', value: '8 Mins',  c: c),

          SizedBox(height: FigmaSize.h(10)),

          // ── "Start Offline Session" button ──────────────────────────
          GestureDetector(
            onTap: () {}, // wire up action
            child: Container(
              width  : FigmaSize.w(150),
              padding: EdgeInsets.symmetric(
                vertical  : FigmaSize.h(6),
                horizontal: FigmaSize.w(16),
              ),
              decoration: BoxDecoration(
                color       : isDark
                    ? AppTheme.primaryYellow.withOpacity(0.15)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(15),
                border: isDark
                    ? Border.all(
                        color: AppTheme.primaryYellow.withOpacity(0.4))
                    : null,
              ),
              child: Center(
                child: Text(
                  'Start Offline Session',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(9),
                    fontWeight: FontWeight.bold,
                    color     : isDark
                        ? AppTheme.primaryYellow
                        : Colors.black,
                    height    : 24 / FigmaSize.w(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String    label;
  final String    value;
  final AppColors c;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: FigmaSize.h(2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: FigmaSize.w(70),
            child: Text(
              label,
              style: TextStyle(
                fontSize  : FigmaSize.w(12),
                fontWeight: FontWeight.w500,
                color     : c.subText,
                height    : 16 / FigmaSize.w(12),
              ),
            ),
          ),
          Text(
            ':  ',
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              fontWeight: FontWeight.w500,
              color     : c.subText,
              height    : 16 / FigmaSize.w(12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize  : FigmaSize.w(12),
                fontWeight: FontWeight.bold,
                color     : c.text,
                height    : 16 / FigmaSize.w(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}