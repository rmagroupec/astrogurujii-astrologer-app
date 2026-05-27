import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';



class WeeklyRankingScreen extends StatelessWidget {
  const WeeklyRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryYellow = Color(0xFFFFD700);
    const Color lightYellow = Color(0xFFFFF9C4);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: lightYellow,
          elevation: 0,
          leading: const Icon(Icons.arrow_back, color: Colors.black),
          title: const Text(
            'Weekly Ranking',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(20), vertical: FigmaSize.h(0)),
              color: Colors.white,
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: const BoxDecoration(color: primaryYellow),
                labelColor: Colors.black,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelColor: Colors.black,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Astrogurujii"),
                  Tab(text: "Astromall"),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Info Bar
                Container(
                  width: double.infinity,
                  padding:  EdgeInsets.symmetric(vertical: FigmaSize.h(8), horizontal: FigmaSize.w(16)),
                  color: lightYellow.withOpacity(0.5),
                  child:  Text(
                    "Earning from Astromall in this week ( Monday to Sunday)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: FigmaSize.w(12), fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                ),
                // Table Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16), vertical: FigmaSize.h(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:  [
                      Text("Rank", style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(16), color: Colors.black)),
                      Text("Earning", style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(16), color: Colors.black  )),
                    ],
                  ),
                ),
                // Ranking List
                Expanded(
                  child: ListView.builder(
                    padding:  EdgeInsets.only(bottom: FigmaSize.h(100)), // Space for floating card
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      int rank = index + 1;
                      return RankingRow(rank: rank);
                    },
                  ),
                ),
              ],
            ),
            // Floating Rank Card at Bottom
            Positioned(
              bottom: FigmaSize.h(20),
              left: FigmaSize.w(16),
              right: FigmaSize.w(16),
              child: _buildUserRankCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard() {
    return Container(
      padding: EdgeInsets.all(FigmaSize.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FigmaSize.w(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children:  [
                Text("Weekly Earnings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(15))),
                SizedBox(height: FigmaSize.h(4)),
                Text("₹ 0", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: FigmaSize.w(22)))  ,
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children:  [
              Text("Your Rank", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: FigmaSize.w(14))),
              Text("13552", style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(22))) ,
            ],
          ),
           SizedBox(width: FigmaSize.w(8)),
           Icon(Icons.chevron_right, size: FigmaSize.w(30)),
        ],
      ),
    );
  }
}

class RankingRow extends StatelessWidget {
  final int rank;
  const RankingRow({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    bool isTopRank = rank <= 9;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank % 2 == 0 ? Colors.white : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isTopRank)
                 Padding(
                  padding: EdgeInsets.only(right: FigmaSize.w(8)),
                  child: Icon(Icons.emoji_events, color: Colors.amber, size: FigmaSize.w(18)),
                ),
              SizedBox(
                width: FigmaSize.w(30),
                child: Text(
                  "$rank",
                  style: TextStyle(
                    fontWeight: isTopRank ? FontWeight.bold : FontWeight.normal,
                    fontSize: FigmaSize.w(15),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
               Text(
                "₹ 76,372",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(14)),
              ),
              SizedBox(width: FigmaSize.w(4)),
              Icon(Icons.arrow_drop_up, color: Colors.green, size: FigmaSize.w(20)) ,
            ],
          ),
        ],
      ),
    );
  }
}