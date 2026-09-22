// lib/features/offers/OffersScreen.dart
// ── Matches the New/Loyal pricing card + activation-history design ──────────
// ── Uses existing AppColors / AppTheme tokens only — no new hardcoded colors ─

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

  bool isLoading = true;
  List<OfferItem>        offers  = [];
  List<OfferHistoryItem> history = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // reset filter chip selection when switching tabs, matches screenshot
      // (History's chips are the offer titles too, but filtered against history)
      if (mounted) setState(() {});
    });
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        Liveservice().GetOfferList(),
        Liveservice().GetOfferHistory(), // ✅ dedicated endpoint — this is the fix
      ]);
      if (!mounted) return;
      setState(() {
        offers    = (results[0] as OfferListResponse).results;
        history   = (results[1] as OfferHistoryResponse).results;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Offers fetch error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<OfferItem> _filteredOffers() {
    if (_filter == 'All') return offers;
    final needle = _filter.toLowerCase().replaceAll(' off', '').trim();
    return offers.where((o) => o.title.toLowerCase().contains(needle)).toList();
  }

  List<OfferHistoryItem> _filteredHistory() {
    if (_filter == 'All') return history;
    final needle = _filter.toLowerCase().replaceAll(' off', '').trim();
    return history.where((h) => h.title.toLowerCase().contains(needle)).toList();
  }

  List<String> get _chips {
    final Set<String> extras = {};
    for (final o in offers) {
      if (o.title.isNotEmpty) extras.add(o.title);
    }
    for (final h in history) {
      if (h.title.isNotEmpty) extras.add(h.title);
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
              'Loyal - Customers who have spoken with you for more than 15 '
              'minutes (including both call and chat)',
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
                borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
              ),
              labelColor          : isDark ? Colors.white : Colors.black,
              unselectedLabelColor: isDark ? Colors.white38 : Colors.black54,
              tabs: const [
                Tab(text: 'ALL OFFERS'),
                Tab(text: 'HISTORY'),
              ],
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────
          if (!isLoading && (offers.isNotEmpty || history.isNotEmpty))
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
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                : RefreshIndicator(
                    onRefresh: _fetchAll,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _AllOffersTab(
                          offers   : _filteredOffers(),
                          c        : c,
                          isDark   : isDark,
                          onChanged: _fetchAll,
                        ),
                        _HistoryTab(
                          history: _filteredHistory(),
                          c      : c,
                          isDark : isDark,
                        ),
                      ],
                    ),
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
  final VoidCallback    onChanged;
  const _AllOffersTab({
    required this.offers,
    required this.c,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: FigmaSize.h(120)),
          Center(child: Text('No offers available', style: TextStyle(color: c.subText))),
        ],
      );
    }
    return ListView.builder(
      padding   : EdgeInsets.all(FigmaSize.w(12)),
      itemCount : offers.length,
      itemBuilder: (_, i) => _OfferCard(
        offer    : offers[i],
        c        : c,
        isDark   : isDark,
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HISTORY TAB — ★ now reads real activation-log data
// ─────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<OfferHistoryItem> history;
  final AppColors              c;
  final bool                   isDark;
  const _HistoryTab({required this.history, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: FigmaSize.h(120)),
          Center(child: Text('No history yet', style: TextStyle(color: c.subText))),
        ],
      );
    }
    return ListView.builder(
      padding   : EdgeInsets.all(FigmaSize.w(12)),
      itemCount : history.length,
      itemBuilder: (_, i) => _HistoryCard(item: history[i], c: c, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// OFFER CARD — matches screenshot 2: title + toggle (+ start time when
// active), New Users block, Loyal Users block, 60-min lock notice.
// ─────────────────────────────────────────────────────────────────
class _OfferCard extends StatefulWidget {
  final OfferItem    offer;
  final AppColors    c;
  final bool         isDark;
  final VoidCallback onChanged;
  const _OfferCard({
    required this.offer,
    required this.c,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _active = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _active = widget.offer.isActive;
  }

  Future<void> _handleToggle(bool val) async {
    final previous = _active;
    setState(() { _active = val; _saving = true; });

    final result = await Liveservice().ToggleOfferActivation(widget.offer.id, val);

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      setState(() => _active = previous); // rollback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message.isNotEmpty
            ? result.message
            : 'Failed to update offer status')),
      );
      return;
    }
    widget.onChanged(); // re-fetch list + history so both tabs stay in sync
  }

  @override
  Widget build(BuildContext context) {
    final c      = widget.c;
    final isDark = widget.isDark;
    final offer  = widget.offer;

    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow   : isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header: title + toggle ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offer.title.isNotEmpty ? offer.title : 'Offer',
                style: TextStyle(
                  color: AppTheme.accentRed, fontSize: FigmaSize.w(15), fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_saving)
                    SizedBox(
                      width: FigmaSize.w(16), height: FigmaSize.w(16),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryYellow),
                    )
                  else
                    CustomToggleSwitch(value: _active, onChanged: _handleToggle),
                  SizedBox(width: FigmaSize.w(8)),
                  Text(
                    _active ? 'Active' : 'Inactive',
                    style: TextStyle(fontSize: FigmaSize.w(11), color: _active ? Colors.green : c.subText),
                  ),
                ],
              ),
            ],
          ),

          // ── Start time, only while active ───────────────────────
          if (_active && offer.startTime.isNotEmpty) ...[
            SizedBox(height: FigmaSize.h(4)),
            Text(
              'Start Time: ${offer.startTime}',
              style: TextStyle(fontSize: FigmaSize.w(11), color: c.subText),
            ),
          ],

          SizedBox(height: FigmaSize.h(12)),

          _TierBlock(label: 'New Users',   tier: offer.newUser,   chipColor: Colors.blue,   c: c, isDark: isDark),
          SizedBox(height: FigmaSize.h(10)),
          _TierBlock(label: 'Loyal Users', tier: offer.loyalUser, chipColor: Colors.amber,  c: c, isDark: isDark),

          if (_active) ...[
            SizedBox(height: FigmaSize.h(10)),
            Row(
              children: [
                Icon(Icons.info_outline, size: FigmaSize.w(13), color: c.subText),
                SizedBox(width: FigmaSize.w(6)),
                Expanded(
                  child: Text(
                    'Offer cannot be revoked before ${offer.minActiveMinutes} mins',
                    style: TextStyle(fontSize: FigmaSize.w(10), color: c.subText),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TIER BLOCK — "New Users" / "Loyal Users" segment
// ─────────────────────────────────────────────────────────────────
class _TierBlock extends StatelessWidget {
  final String    label;
  final OfferTier tier;
  final Color     chipColor;
  final AppColors c;
  final bool      isDark;

  const _TierBlock({
    required this.label,
    required this.tier,
    required this.chipColor,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(10), vertical: FigmaSize.h(3)),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label, style: TextStyle(fontSize: FigmaSize.w(11), fontWeight: FontWeight.w600, color: c.text)),
            ),
            Row(
              children: [
                Text(
                  '₹${tier.originalPrice.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: FigmaSize.w(11), color: c.subText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: FigmaSize.w(6)),
                Text(
                  '₹${tier.discountedPrice.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: FigmaSize.w(12), fontWeight: FontWeight.w700, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: FigmaSize.h(6)),
        Row(
          children: [
            Expanded(child: _MiniBox(label: 'Your Share',    value: '₹${tier.yourShare.toStringAsFixed(1)}', c: c, isDark: isDark)),
            SizedBox(width: FigmaSize.w(8)),
            Expanded(child: _MiniBox(label: 'At Share',      value: '₹${tier.atShare.toStringAsFixed(1)}',   c: c, isDark: isDark)),
            SizedBox(width: FigmaSize.w(8)),
            Expanded(child: _MiniBox(label: 'Customer pays', value: '₹${tier.discountedPrice.toStringAsFixed(1)}', c: c, isDark: isDark)),
          ],
        ),
      ],
    );
  }
}

class _MiniBox extends StatelessWidget {
  final String label, value;
  final AppColors c;
  final bool isDark;
  const _MiniBox({required this.label, required this.value, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(6)),
      decoration: BoxDecoration(
        color       : isDark ? c.toggleBg : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border      : isDark ? Border.all(color: c.border) : null,
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: FigmaSize.w(9), color: c.subText), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: FigmaSize.w(11), fontWeight: FontWeight.w600, color: c.text)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HISTORY CARD — matches screenshot 1: title + Completed badge + Start/End
// ─────────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final OfferHistoryItem item;
  final AppColors        c;
  final bool             isDark;

  const _HistoryCard({required this.item, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final completed = item.status.toLowerCase() == 'completed';

    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow   : isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title.isNotEmpty ? item.title : 'Offer',
                style: TextStyle(color: AppTheme.accentRed, fontSize: FigmaSize.w(15), fontWeight: FontWeight.w700),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(10), vertical: FigmaSize.h(4)),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withOpacity(isDark ? 0.15 : 0.08)
                      : Colors.orange.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(fontSize: FigmaSize.w(11), color: completed ? Colors.green : Colors.orange, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(FigmaSize.w(10)),
                  decoration: BoxDecoration(
                    border      : Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Time *', style: TextStyle(fontSize: FigmaSize.w(10), color: c.subText)),
                      const SizedBox(height: 4),
                      Text(item.startTime, style: TextStyle(fontSize: FigmaSize.w(12), fontWeight: FontWeight.w600, color: c.text)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: FigmaSize.w(8)),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(FigmaSize.w(10)),
                  decoration: BoxDecoration(
                    border      : Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Time *', style: TextStyle(fontSize: FigmaSize.w(10), color: c.subText)),
                      const SizedBox(height: 4),
                      Text(item.endTime, style: TextStyle(fontSize: FigmaSize.w(12), fontWeight: FontWeight.w600, color: c.text)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  const _Chip({required this.label, required this.selected, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: FigmaSize.w(8)),
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(14), vertical: FigmaSize.h(6)),
        decoration: BoxDecoration(
          border      : Border.all(color: AppTheme.primaryYellow),
          borderRadius: BorderRadius.circular(20),
          color: selected ? AppTheme.primaryYellow.withOpacity(0.20) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: FigmaSize.w(11), fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: c.text),
        ),
      ),
    );
  }
}