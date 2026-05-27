import 'package:astrologer_app/features/Settings/components/commonWidget.dart';
import 'package:flutter/material.dart';

class OffersHistoryScreen extends StatelessWidget {
  const OffersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: yellowAppBar("Offers"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          offersInfo(),
          offersTabBar(),
          offerFilterChips(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 4,
              itemBuilder: (_, i) => historyOfferCard(i == 0),
            ),
          )
        ],
      ),
    );
  }
 

}
class AlwaysOnlineScreen extends StatefulWidget {
  const AlwaysOnlineScreen({super.key});

  @override
  State<AlwaysOnlineScreen> createState() => _AlwaysOnlineScreenState();
}

class _AlwaysOnlineScreenState extends State<AlwaysOnlineScreen> {
  int selectedCommunityTab = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: yellowAppBar("My Community"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          communityTabs(
            selectedIndex: selectedCommunityTab,
            onTabChange: (index) {
              setState(() {
                selectedCommunityTab = index;
              });
            },
          ),
          // alwaysOnlineInfo(),
          // searchAndSort(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 4,
              itemBuilder: (_, __) => alwaysOnlineCard(),
            ),
          ),
        ],
      ),
    );
  }
}


