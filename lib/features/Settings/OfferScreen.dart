import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:flutter/material.dart';
import 'package:astrologer_app/core/utils/size_config.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Offers", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Info text
          Padding(
            padding: EdgeInsets.all(FigmaSize.w(12),),
            child: Text(
              "Loyal - Customers who have spoken with you for more than 15 min "
              "(including both call and chat )",
              style: TextStyle(
                fontSize: FigmaSize.w(11),
                color: Colors.black,
                fontWeight: FontWeight.w500
              ),
            ),
          ),

          // 🔹 Tabs
          Container(
            color: const Color(0xFFFCD417).withOpacity(0.25),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Color(0xFFFCD417),
                  width: 2,
                ),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: "ALL OFFERS"),
                Tab(text: "HISTORY"),
              ],
            ),
          ),

          // 🔹 Filter chips
          Padding(
            padding: EdgeInsets.all(FigmaSize.w(12)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip("All", selected: true),
                  _chip("50% Off"),
                  _chip("20% Off"),
                  _chip("75% Off"),
                ],
              ),
            ),
          ),

          // 🔹 Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _allOffersView(),
                _historyView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ALL OFFERS =================

  Widget _allOffersView() {
    return ListView.builder(
      padding: EdgeInsets.all(FigmaSize.w(12)),
      itemCount: 2,
      itemBuilder: (_, i) => _offerPriceCard(),
    );
  }

  Widget _offerPriceCard() {
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
                "50% off",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: FigmaSize.w(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                 CustomToggleSwitch(value: false, onChanged: (val){}),
                 SizedBox(width: FigmaSize.w(8),),
                  Text(
                    "In active",
                    style: TextStyle(fontSize: FigmaSize.w(11)),
                  )
                ],
              )
            ],
          ),

          const SizedBox(height: 8),

          _priceBlock(
            title: "New Users",
            color: Color(0xFFBDBDBD).withOpacity(0.08),
          ),
          const SizedBox(height: 8),
          _priceBlock(
            title: "Loyal Users",
            color: Color(0xFFBDBDBD).withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  Widget _priceBlock({required String title, required Color color}) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(10)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      fontWeight: FontWeight.w600)),
              Text("₹ 2.5 → ₹ 2.5",
                  style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      color: Colors.green)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priceBox("You Share", "₹ 2.5"),
              _priceBox("At Share", "₹ 2.5"),
              _priceBox("Customer pays", "₹ 5.0"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceBox(String label, String value) {
    return Container(
      width: FigmaSize.w(90),
      padding: EdgeInsets.all(FigmaSize.w(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: FigmaSize.w(10), color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ================= HISTORY =================

  Widget _historyView() {
    return ListView.builder(
      padding: EdgeInsets.all(FigmaSize.w(12)),
      itemCount: 4,
      itemBuilder: (_, i) => _historyCard(completed: i != 0),
    );
  }

  Widget _historyCard({required bool completed}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "50% off",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: FigmaSize.w(14),
                    fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(10),
                    vertical: FigmaSize.h(4)),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  completed ? "Completed" : "In Progress",
                  style: TextStyle(
                    fontSize: FigmaSize.w(11),
                    color: completed ? Colors.green : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _timeBox("Start Time", "02 Oct 25, 12:34 AM"),
              const SizedBox(width: 8),
              _timeBox("End Time", "Currently active"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String title, String value) {
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
                    fontSize: FigmaSize.w(12),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ================= CHIP =================

  Widget _chip(String text, {bool selected = false}) {
    return Container(
      margin: EdgeInsets.only(right: FigmaSize.w(8)),
      padding: EdgeInsets.symmetric(
        horizontal: FigmaSize.w(14),
        vertical: FigmaSize.h(6),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFCD417)),
        borderRadius: BorderRadius.circular(20),
        color: selected ? const Color(0xFFFCD417).withOpacity(0.15) : Colors.white,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: FigmaSize.w(11)),
      ),
    );
  }
}
