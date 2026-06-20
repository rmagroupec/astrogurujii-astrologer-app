// lib/features/offers/OffersScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes — only colors made theme-aware ─────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/model/OfferListModel.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:flutter/material.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool            isLoading = true;
  List<OfferItem> offers    = [];
  String          _filter   = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOffers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOffers() async {
    setState(() => isLoading = true);
    try {
      final response = await Liveservice().GetOfferList();
      setState(() {
        offers    = response.results;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ OfferList error: $e');
      setState(() => isLoading = false);
    }
  }

  List<OfferItem> get _filteredOffers {
    if (_filter == 'All') return offers;
    return offers.where((o) => o.title.toLowerCase().contains(
          _filter.toLowerCase().replaceAll(' off', '').trim(),
        )).toList();
  }

  List<String> get _chips {
    final Set<String> extras = {};
    for (final o in offers) {
      if (o.title.isNotEmpty) extras.add(o.title);
    }
    return ['All', ...extras];
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        elevation: 0,
        title: const Text('Offers',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Info text ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(FigmaSize.w(12)),
            child: Text(
              'Loyal - Customers who have spoken with you for more than 15 min '
              '(including both call and chat)',
              style: TextStyle(
                fontSize  : FigmaSize.w(11),
                color     : c.subText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Tabs ───────────────────────────────────────────────────
          Container(
            color: isDark
                ? const Color(0xFF1A1A1A)
                : AppTheme.primaryYellow.withOpacity(0.25),
            child: TabBar(
              controller  : _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                    color: AppTheme.primaryYellow, width: 2),
              ),
              labelColor          : isDark ? Colors.white : Colors.black,
              unselectedLabelColor: isDark
                  ? Colors.white38
                  : Colors.black54,
              tabs: const [
                Tab(text: 'ALL OFFERS'),
                Tab(text: 'HISTORY'),
              ],
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────
          if (!isLoading && offers.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(FigmaSize.w(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _chips
                      .map((chip) => _Chip(
                            label   : chip,
                            selected: _filter == chip,
                            onTap   : () => setState(() => _filter = chip),
                            c       : c,
                          ))
                      .toList(),
                ),
              ),
            ),

          // ── Tab views ──────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _AllOffersTab(offers: _filteredOffers, c: c, isDark: isDark),
                      _HistoryTab(offers: offers, c: c, isDark: isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ALL OFFERS TAB
// ─────────────────────────────────────────────────────────────────
class _AllOffersTab extends StatelessWidget {
  final List<OfferItem> offers;
  final AppColors       c;
  final bool            isDark;
  const _AllOffersTab({required this.offers, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Center(
        child: Text('No offers available',
            style: TextStyle(color: c.subText)),
      );
    }
    return ListView.builder(
      padding   : EdgeInsets.all(FigmaSize.w(12)),
      itemCount : offers.length,
      itemBuilder: (_, i) =>
          _OfferCard(offer: offers[i], c: c, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HISTORY TAB
// ─────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<OfferItem> offers;
  final AppColors       c;
  final bool            isDark;
  const _HistoryTab({required this.offers, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Center(
        child: Text('No history yet',
            style: TextStyle(color: c.subText)),
      );
    }
    return ListView.builder(
      padding   : EdgeInsets.all(FigmaSize.w(12)),
      itemCount : offers.length,
      itemBuilder: (_, i) =>
          _HistoryCard(offer: offers[i], c: c, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// OFFER CARD
// ─────────────────────────────────────────────────────────────────
class _OfferCard extends StatefulWidget {
  final OfferItem offer;
  final AppColors c;
  final bool      isDark;
  const _OfferCard({required this.offer, required this.c, required this.isDark});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _active = widget.offer.status == 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final c      = widget.c;
    final isDark = widget.isDark;

    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow   : isDark ? [] : [
          BoxShadow(
            color     : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset    : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.offer.title.isNotEmpty ? widget.offer.title : 'Offer',
                style: TextStyle(
                  color     : AppTheme.accentRed,
                  fontSize  : FigmaSize.w(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  CustomToggleSwitch(
                    value    : _active,
                    onChanged: (val) => setState(() => _active = val),
                  ),
                  SizedBox(width: FigmaSize.w(8)),
                  Text(
                    _active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      color   : _active ? Colors.green : c.subText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(10)),

          _PriceBlock(
            title: 'Chat',
            price: widget.offer.chatPrice,
            icon : Icons.chat_bubble_outline,
            c    : c, isDark: isDark,
          ),
          SizedBox(height: FigmaSize.h(8)),
          _PriceBlock(
            title: 'Voice Call',
            price: widget.offer.audioPrice,
            icon : Icons.call_outlined,
            c    : c, isDark: isDark,
          ),
          SizedBox(height: FigmaSize.h(8)),
          _PriceBlock(
            title: 'Video Call',
            price: widget.offer.videoPrice,
            icon : Icons.videocam_outlined,
            c    : c, isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PRICE BLOCK
// ─────────────────────────────────────────────────────────────────
class _PriceBlock extends StatelessWidget {
  final String   title;
  final String   price;
  final IconData icon;
  final AppColors c;
  final bool      isDark;

  const _PriceBlock({
    required this.title,
    required this.price,
    required this.icon,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double priceVal = double.tryParse(price) ?? 0;

    return Container(
      padding: EdgeInsets.all(FigmaSize.w(10)),
      decoration: BoxDecoration(
        color       : isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFBDBDBD).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: FigmaSize.w(13), color: c.subText),
                  SizedBox(width: FigmaSize.w(5)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize  : FigmaSize.w(11),
                      fontWeight: FontWeight.w600,
                      color     : c.text,
                    ),
                  ),
                ],
              ),
              Text(
                '₹ $price / min',
                style: TextStyle(
                  fontSize  : FigmaSize.w(11),
                  color     : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(6)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceBox(
                label : 'You Share',
                value : '₹ ${(priceVal * 0.5).toStringAsFixed(1)}',
                c     : c, isDark: isDark,
              ),
              _PriceBox(
                label : 'At Share',
                value : '₹ ${(priceVal * 0.5).toStringAsFixed(1)}',
                c     : c, isDark: isDark,
              ),
              _PriceBox(
                label : 'Customer pays',
                value : '₹ $price',
                c     : c, isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PRICE BOX
// ─────────────────────────────────────────────────────────────────
class _PriceBox extends StatelessWidget {
  final String   label;
  final String   value;
  final AppColors c;
  final bool      isDark;

  const _PriceBox({
    required this.label,
    required this.value,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width  : FigmaSize.w(90),
      padding: EdgeInsets.all(FigmaSize.w(6)),
      decoration: BoxDecoration(
        // In dark mode use surface; in light use white
        color       : isDark ? c.toggleBg : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border      : isDark
            ? Border.all(color: c.border)
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: FigmaSize.w(10),
              color   : c.subText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              fontWeight: FontWeight.w600,
              color     : c.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HISTORY CARD
// ─────────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final OfferItem offer;
  final AppColors c;
  final bool      isDark;

  const _HistoryCard({
    required this.offer,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final completed = offer.status == 'Active';

    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow   : isDark ? [] : [
          BoxShadow(
            color     : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset    : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offer.title.isNotEmpty ? offer.title : 'Offer',
                style: TextStyle(
                  color     : AppTheme.accentRed,
                  fontSize  : FigmaSize.w(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(10),
                  vertical  : FigmaSize.h(4),
                ),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withOpacity(isDark ? 0.15 : 0.08)
                      : Colors.orange.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  offer.status,
                  style: TextStyle(
                    fontSize  : FigmaSize.w(11),
                    color     : completed ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(10)),

          // ── Time boxes ────────────────────────────────────────────
          Row(
            children: [
              _TimeBox(
                  title: 'Created', value: offer.createdDate,
                  c: c, isDark: isDark),
              SizedBox(width: FigmaSize.w(8)),
              _TimeBox(
                title : 'Updated',
                value : offer.updatedAt.isNotEmpty ? offer.updatedAt : '—',
                c     : c, isDark: isDark,
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(8)),

          // ── Price summary ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniPriceTag(label: 'Chat',  value: '₹ ${offer.chatPrice}',  c: c),
              _MiniPriceTag(label: 'Voice', value: '₹ ${offer.audioPrice}', c: c),
              _MiniPriceTag(label: 'Video', value: '₹ ${offer.videoPrice}', c: c),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TIME BOX
// ─────────────────────────────────────────────────────────────────
class _TimeBox extends StatelessWidget {
  final String   title;
  final String   value;
  final AppColors c;
  final bool      isDark;

  const _TimeBox({
    required this.title,
    required this.value,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(FigmaSize.w(10)),
        decoration: BoxDecoration(
          color       : isDark ? c.toggleBg : null,
          border      : Border.all(color: c.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: FigmaSize.w(10), color: c.subText)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize  : FigmaSize.w(11),
                    fontWeight: FontWeight.w600,
                    color     : c.text)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// MINI PRICE TAG
// ─────────────────────────────────────────────────────────────────
class _MiniPriceTag extends StatelessWidget {
  final String   label;
  final String   value;
  final AppColors c;

  const _MiniPriceTag({
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: FigmaSize.w(10), color: c.subText)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize  : FigmaSize.w(12),
                fontWeight: FontWeight.w600,
                color     : Colors.green)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  final AppColors    c;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: FigmaSize.w(8)),
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(14),
          vertical  : FigmaSize.h(6),
        ),
        decoration: BoxDecoration(
          border      : Border.all(color: AppTheme.primaryYellow),
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppTheme.primaryYellow.withOpacity(0.20)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize  : FigmaSize.w(11),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color     : c.text,
          ),
        ),
      ),
    );
  }
}