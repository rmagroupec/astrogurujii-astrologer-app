import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/model/OfferListModel.dart';
import 'package:astrologer_app/service/apiService.dart';
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

  // ── State ──────────────────────────────────────────────────────
  bool              isLoading = true;
  List<OfferItem>   offers    = [];
  String            _filter   = 'All';

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

  // ── API ────────────────────────────────────────────────────────
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

  // ── Filter chips logic ─────────────────────────────────────────
  List<OfferItem> get _filteredOffers {
    if (_filter == 'All') return offers;
    return offers.where((o) {
      // filter by title containing the chip text
      return o.title.toLowerCase().contains(
            _filter.toLowerCase().replaceAll(' off', '').trim(),
          );
    }).toList();
  }

  // ── Derive unique chip labels from offer titles ─────────────────
  List<String> get _chips {
    final Set<String> extras = {};
    for (final o in offers) {
      if (o.title.isNotEmpty) extras.add(o.title);
    }
    return ['All', ...extras];
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Offers",
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Info text ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(FigmaSize.w(12)),
            child: Text(
              "Loyal - Customers who have spoken with you for more than 15 min "
              "(including both call and chat)",
              style: TextStyle(
                fontSize: FigmaSize.w(11),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Tabs ─────────────────────────────────────────────
          Container(
            color: const Color(0xFFFCD417).withOpacity(0.25),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderSide:
                    BorderSide(color: Color(0xFFFCD417), width: 2),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: "ALL OFFERS"),
                Tab(text: "HISTORY"),
              ],
            ),
          ),

          // ── Filter chips ─────────────────────────────────────
          if (!isLoading && offers.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(FigmaSize.w(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _chips
                      .map((c) => _Chip(
                            label:    c,
                            selected: _filter == c,
                            onTap:    () => setState(() => _filter = c),
                          ))
                      .toList(),
                ),
              ),
            ),

          // ── Tab views ────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _AllOffersTab(offers: _filteredOffers),
                      _HistoryTab(offers: offers),
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
  const _AllOffersTab({required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const Center(
        child: Text("No offers available",
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(FigmaSize.w(12)),
      itemCount: offers.length,
      itemBuilder: (_, i) => _OfferCard(offer: offers[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HISTORY TAB  (same offers — shows created/active status)
// ─────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<OfferItem> offers;
  const _HistoryTab({required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const Center(
        child: Text("No history yet",
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(FigmaSize.w(12)),
      itemCount: offers.length,
      itemBuilder: (_, i) => _HistoryCard(offer: offers[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// OFFER CARD
// ─────────────────────────────────────────────────────────────────
class _OfferCard extends StatefulWidget {
  final OfferItem offer;
  const _OfferCard({required this.offer});

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
    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.offer.title.isNotEmpty
                    ? widget.offer.title
                    : "Offer",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: FigmaSize.w(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  CustomToggleSwitch(
                    value: _active,
                    onChanged: (val) => setState(() => _active = val),
                  ),
                  SizedBox(width: FigmaSize.w(8)),
                  Text(
                    _active ? "Active" : "Inactive",
                    style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      color: _active ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(10)),

          // ── Chat price block ─────────────────────────────────
          _PriceBlock(
            title:       "Chat",
            price:       widget.offer.chatPrice,
            icon:        Icons.chat_bubble_outline,
          ),

          SizedBox(height: FigmaSize.h(8)),

          // ── Audio price block ────────────────────────────────
          _PriceBlock(
            title:       "Voice Call",
            price:       widget.offer.audioPrice,
            icon:        Icons.call_outlined,
          ),

          SizedBox(height: FigmaSize.h(8)),

          // ── Video price block ────────────────────────────────
          _PriceBlock(
            title:       "Video Call",
            price:       widget.offer.videoPrice,
            icon:        Icons.videocam_outlined,
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
  final String title;
  final String price;
  final IconData icon;

  const _PriceBlock({
    required this.title,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double priceVal = double.tryParse(price) ?? 0;

    return Container(
      padding: EdgeInsets.all(FigmaSize.w(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + price summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: FigmaSize.w(13), color: Colors.black54),
                  SizedBox(width: FigmaSize.w(5)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                "₹ $price / min",
                style: TextStyle(
                  fontSize: FigmaSize.w(11),
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(6)),

          // 3 price boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceBox(
                label: "You Share",
                value: "₹ ${(priceVal * 0.5).toStringAsFixed(1)}",
              ),
              _PriceBox(
                label: "At Share",
                value: "₹ ${(priceVal * 0.5).toStringAsFixed(1)}",
              ),
              _PriceBox(
                label: "Customer pays",
                value: "₹ $price",
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
  final String label;
  final String value;
  const _PriceBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FigmaSize.w(90),
      padding: EdgeInsets.all(FigmaSize.w(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: FigmaSize.w(10),
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: FigmaSize.w(12),
              fontWeight: FontWeight.w600,
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
  const _HistoryCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final completed = offer.status == 'Active';

    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offer.title.isNotEmpty ? offer.title : "Offer",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: FigmaSize.w(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(10),
                  vertical: FigmaSize.h(4),
                ),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  offer.status,
                  style: TextStyle(
                    fontSize: FigmaSize.w(11),
                    color: completed ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(10)),

          // Time boxes
          Row(
            children: [
              _TimeBox(title: "Created", value: offer.createdDate),
              SizedBox(width: FigmaSize.w(8)),
              _TimeBox(
                title: "Updated",
                value: offer.updatedAt.isNotEmpty
                    ? offer.updatedAt
                    : "—",
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(8)),

          // Price summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniPriceTag(label: "Chat",  value: "₹ ${offer.chatPrice}"),
              _MiniPriceTag(label: "Voice", value: "₹ ${offer.audioPrice}"),
              _MiniPriceTag(label: "Video", value: "₹ ${offer.videoPrice}"),
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
  final String title;
  final String value;
  const _TimeBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(FigmaSize.w(10)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: FigmaSize.w(10), color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: FigmaSize.w(11),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// MINI PRICE TAG  (used in history)
// ─────────────────────────────────────────────────────────────────
class _MiniPriceTag extends StatelessWidget {
  final String label;
  final String value;
  const _MiniPriceTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: FigmaSize.w(10), color: Colors.black45)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: FigmaSize.w(12),
                fontWeight: FontWeight.w600,
                color: Colors.green)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: FigmaSize.w(8)),
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(14),
          vertical: FigmaSize.h(6),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFCD417)),
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? const Color(0xFFFCD417).withOpacity(0.20)
              : Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: FigmaSize.w(11),
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}