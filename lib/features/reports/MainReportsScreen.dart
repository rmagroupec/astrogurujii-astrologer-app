import 'package:astrologer_app/features/reports/HistoryCard.dart';
import 'package:astrologer_app/model/VideoCallHistoryModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class MainReportsScreen extends StatefulWidget {
  final String page;

  const MainReportsScreen({super.key, required this.page});

  @override
  State<MainReportsScreen> createState() => _MainReportsScreenState();
}

class _MainReportsScreenState extends State<MainReportsScreen>
    with SingleTickerProviderStateMixin {

  bool isLoading = false;

  late TabController _tabController;

  final tabs = ["Chat", "Call", "Video Call", "Astromall"];

  // Maps the page string to its tab index
  int _getInitialIndex() {
    switch (widget.page) {
      case "chat":
        return 0;
      case "audio":
        return 1;
      case "video":
        return 2;
      case "Astromall":
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: _getInitialIndex(),
    );
  }

  /// Filter per tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xffFFD600),
        title: const Text(
          "Orders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HistoryCard(page: "chat"),
          HistoryCard(page: "audio"),
          HistoryCard(page: "video"),
          HistoryCard(page: "Astromall"),
        ],
      ),
    );
  }
}