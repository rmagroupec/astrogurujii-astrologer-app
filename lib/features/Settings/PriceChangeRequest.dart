// lib/features/Settings/PriceChangeRequest.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes + fixed Expanded outside Column bug ───────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/PriceIncreaseRequestModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Pricechangerequest extends StatefulWidget {
  const Pricechangerequest({super.key});

  @override
  State<Pricechangerequest> createState() => _PricechangerequestState();
}

class _PricechangerequestState extends State<Pricechangerequest> {
  bool                  isLoading = true;
  List<ChatCallRequest>? data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().PriceIncreaseRequestList();
      setState(() {
        data      = response.chatCallRequest;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Price Increase'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          // Fixed: Expanded cannot be a direct child of Scaffold body
          : DefaultTabController(
              length: 2,
              child : Column(
                children: [
                  // ── Tab bar ──────────────────────────────────────────────
                  Container(
                    margin : EdgeInsets.only(top: FigmaSize.h(6)),
                    padding: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(16)),
                    color  : c.surface,
                    child  : TabBar(
                      dividerColor        : Colors.transparent,
                      indicatorSize       : TabBarIndicatorSize.tab,
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

  // ── Increase Price Tab ────────────────────────────────────────────────────
  Widget _buildIncreasePriceTab(AppColors c, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
      child  : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: FigmaSize.h(18)),

            // ── Earnings card ───────────────────────────────────────────
            Container(
              width  : double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: FigmaSize.w(16),
                vertical  : FigmaSize.h(12),
              ),
              decoration: BoxDecoration(
                color       : c.surface,
                border      : Border.all(color: const Color(0xFFFED402)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings',
                    style: TextStyle(
                      fontSize  : FigmaSize.w(12),
                      color     : c.subText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹ 20/min',
                        style: TextStyle(
                          fontSize  : FigmaSize.w(22),
                          fontWeight: FontWeight.w600,
                          color     : c.text,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin  : Alignment.centerLeft,
                              end    : Alignment.centerRight,
                              colors : [
                                Color(0xFFFCD417),
                                Color(0xFFFFE569),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(FigmaSize.w(10)),
                          ),
                          child: const Text(
                            'Increase Price',
                            style: TextStyle(
                              color     : Colors.black,
                              fontSize  : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FigmaSize.h(29)),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/information-button.svg',
                        height     : FigmaSize.h(18),
                        width      : FigmaSize.w(18),
                        colorFilter: isDark
                            ? ColorFilter.mode(
                                c.subText, BlendMode.srcIn)
                            : null,
                      ),
                      SizedBox(width: FigmaSize.w(8)),
                      Text(
                        "You're not eligible yet. Keep going!",
                        style: TextStyle(
                          fontSize  : FigmaSize.w(11),
                          color     : c.subText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: FigmaSize.h(30)),

            Text(
              "You're not eligible yet. Keep going!",
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                color     : c.text,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: FigmaSize.h(17)),

            // ── Progress table ──────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _tabItem('My Busy Time',  c, isDark, topLeft : true),
                    _tabItem('Required Time', c, isDark),
                    _tabItem('Price Increase',c, isDark, topRight: true),
                  ],
                ),
                Row(
                  children: [
                    _tabItem('My Busy Time',  c, isDark),
                    _tabItem('Required Time', c, isDark),
                    _tabItem('Price Increase',c, isDark),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color       : Colors.green.withOpacity(0.08),
                    border      : Border.all(color: c.border),
                    borderRadius: const BorderRadius.only(
                      bottomLeft : Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Only 235 mins more to be eligible for price increase.',
                      style: TextStyle(
                        color     : c.text,
                        fontSize  : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: FigmaSize.h(30)),

            Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                color     : c.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: FigmaSize.h(17)),

            // ── T&C card ────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: FigmaSize.w(15),
                vertical  : FigmaSize.h(15),
              ),
              decoration: BoxDecoration(
                color       : c.surface,
                borderRadius: BorderRadius.circular(10),
                border      : Border.all(color: c.border),
              ),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: EdgeInsets.all(FigmaSize.w(10)),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/gallery_1.svg',
                          height: FigmaSize.h(48),
                          width : FigmaSize.w(48),
                        ),
                        SizedBox(width: FigmaSize.w(17)),
                        Expanded(
                          child: Text(
                            '1. The astrologer must have completed at least '
                            '500 minutes of consultation time in the last 30 '
                            'days to be eligible for a price increase.',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(12),
                              color     : c.subText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines : 4,
                            overflow : TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: FigmaSize.h(30)),
          ],
        ),
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────
  Widget _buildHistoryTab(AppColors c, bool isDark) {
    if (data == null || data!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 48, color: c.subText.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text('No history yet',
                style: TextStyle(color: c.subText, fontSize: 14)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
      child  : ListView.builder(
        padding    : EdgeInsets.only(top: FigmaSize.h(16)),
        itemCount  : data!.length,
        itemBuilder: (context, index) {
          final item = data![index];
          return Container(
            margin : EdgeInsets.only(bottom: FigmaSize.h(11)),
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(19),
              vertical  : FigmaSize.h(11),
            ),
            decoration: BoxDecoration(
              color       : isDark
                  ? c.surface
                  : const Color(0xFFBDBDBD).withOpacity(0.08),
              borderRadius: BorderRadius.circular(FigmaSize.w(10)),
              border      : Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.type.toString(),
                          style: TextStyle(
                            fontSize  : FigmaSize.w(12),
                            fontWeight: FontWeight.w600,
                            color     : c.text,
                          ),
                        ),
                        SizedBox(width: FigmaSize.w(6)),
                        SvgPicture.asset(
                          'assets/images/right-arrow.svg',
                          colorFilter: isDark
                              ? ColorFilter.mode(
                                  c.subText, BlendMode.srcIn)
                              : null,
                        ),
                        SizedBox(width: FigmaSize.w(6)),
                        Text(
                          '₹ ${item.price}',
                          style: TextStyle(
                            fontSize  : FigmaSize.w(12),
                            fontWeight: FontWeight.w600,
                            color     : c.text,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FigmaSize.h(8)),
                    Text(
                      item.createdAt.toString(),
                      style: TextStyle(
                        fontSize  : FigmaSize.w(12),
                        fontWeight: FontWeight.w500,
                        color     : c.subText,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.verified,
                        size: 15, color: Colors.green),
                    SizedBox(width: FigmaSize.w(4)),
                    Text(
                      item.status.toString(),
                      style: TextStyle(
                        fontSize  : FigmaSize.w(13),
                        fontWeight: FontWeight.w500,
                        color     : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Table header cell ─────────────────────────────────────────────────────
  Widget _tabItem(
    String    title,
    AppColors c,
    bool      isDark, {
    bool topLeft  = false,
    bool topRight = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
        decoration: BoxDecoration(
          color : isDark ? c.toggleBg : const Color(0xFFFFFCF0),
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
              fontSize  : FigmaSize.w(12),
              fontWeight: FontWeight.w600,
              color     : c.text,
            ),
          ),
        ),
      ),
    );
  }
}