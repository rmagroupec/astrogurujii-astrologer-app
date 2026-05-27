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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
 
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
