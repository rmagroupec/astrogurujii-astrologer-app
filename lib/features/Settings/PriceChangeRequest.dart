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

  bool isLoading = true;
  List<ChatCallRequest>? data;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().PriceIncreaseRequestList(); // your API
      setState(() {
        data = response.chatCallRequest;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Price Increase"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading ? Center(child: CircularProgressIndicator(),) : Expanded(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: FigmaSize.h(6)),
                padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
                color: Colors.white,
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black,
                  indicator: BoxDecoration(
                    color: Color(0xFFFCD417), // selected tab bg
                  ),
                  tabs: [
                    Tab(text: "Increase Price"),
                    Tab(text: "History"),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [_buildIncreasePriceTab(), _buildHistoryTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncreasePriceTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: FigmaSize.h(18)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: FigmaSize.w(16),
                vertical: FigmaSize.h(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFFED402)),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Earnings",
                    style: TextStyle(
                      fontSize: FigmaSize.w(12),
                      color: Color(0xFF929292),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹ 20/min",
                        style: TextStyle(
                          fontSize: FigmaSize.w(22),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // verify action
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFFCD417), Color(0xFFFFE569)],
                            ),
                            borderRadius: BorderRadius.circular(FigmaSize.w(10)),
                          ),
                          child: const Text(
                            "Increase Price",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
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
                        "assets/images/information-button.svg",
                        height: FigmaSize.h(18),
                        width: FigmaSize.w(18),
                      ),
                      SizedBox(width: FigmaSize.w(8)),
                      Text(
                        "You’re not eligible yet. Keep going!",
                        style: TextStyle(
                          fontSize: FigmaSize.w(11),
                          color: Colors.black,
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
              "You’re not eligible yet. Keep going!",
              style: TextStyle(
                fontSize: FigmaSize.w(14),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: FigmaSize.h(17)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 Top Tabs (3 items)
                Container(
                  decoration: BoxDecoration(
                    // border: Border.all(color: Color(0xFFD5D5D5)),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      _tabItem("My Busy Time", Color(0xFFFFFCF0), 0),
                      _tabItem("Required Time", Color(0xFFFFFCF0), 1),
                      _tabItem("Price Increase", Color(0xFFFFFCF0), 2),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    // border: Border.all(color: Color(0xFFD5D5D5)),
                  ),
                  child: Row(
                    children: [
                      _tabItem("My Busy Time", Colors.white, 3),
                      _tabItem("Required Time", Colors.white, 4),
                      _tabItem("Price Increase", Colors.white, 5),
                    ],
                  ),
                ),
        
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF34A853).withOpacity(0.08),
                    border: Border.all(color: Color(0xFFD5D5D5)),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Only 235 mins more to be eligible for price increase.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        
            SizedBox(height: FigmaSize.h(30)),
            Text(
              "Terms & Conditions",
              style: TextStyle(
                fontSize: FigmaSize.w(14),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: FigmaSize.h(17)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: FigmaSize.w(15),
                vertical: FigmaSize.h(15),
              ),
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF).withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFDADADA)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(FigmaSize.w(10)),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/images/gallery_1.svg",
                          height: FigmaSize.h(48),
                          width: FigmaSize.w(48),
                        ),
                        SizedBox(width: FigmaSize.w(17)),
                        Expanded(
                          child: Text(
                            "1. The astrologer must have completed at least 500 minutes of consultation time in the last 30 days to be eligible for a price increase.",
                            style: TextStyle(
                              fontSize: FigmaSize.w(12),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(FigmaSize.w(10)),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/images/gallery_1.svg",
                          height: FigmaSize.h(48),
                          width: FigmaSize.w(48),
                        ),
                        SizedBox(width: FigmaSize.w(17)),
                        Expanded(
                          child: Text(
                            "1. The astrologer must have completed at least 500 minutes of consultation time in the last 30 days to be eligible for a price increase.",
                            style: TextStyle(
                              fontSize: FigmaSize.w(12),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(FigmaSize.w(10)),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/images/gallery_1.svg",
                          height: FigmaSize.h(48),
                          width: FigmaSize.w(48),
                        ),
                        SizedBox(width: FigmaSize.w(17)),
                        Expanded(
                          child: Text(
                            "1. The astrologer must have completed at least 500 minutes of consultation time in the last 30 days to be eligible for a price increase.",
                            style: TextStyle(
                              fontSize: FigmaSize.w(12),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
      child: Column(
        children: [
          SizedBox(height: FigmaSize.h(51)),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: FigmaSize.h(11)),
                padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(19),
                  vertical: FigmaSize.h(11),
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFBDBDBD).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(FigmaSize.w(10)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: FigmaSize.w(6),
                              children: [
                                Text(
                                  data![index].type.toString(),
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(12),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                SvgPicture.asset(
                                  "assets/images/right-arrow.svg",
                                ),
                                Text(
                                  "₹ ${data![index].price.toString()}",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(12),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: FigmaSize.h(8)),
                            Text(
                        data![index].createdAt.toString(),
                              style: TextStyle(
                                fontSize: FigmaSize.w(12),
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF838383),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.verified, size: 15, color: Colors.green),
                            SizedBox(width: FigmaSize.w(4)),
                            Text(
                             data![index].status.toString(),
                              style: TextStyle(
                                fontSize: FigmaSize.w(13),
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            itemCount: data!.length,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String title, Color color, int index) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),

        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFD5D5D5)),
          borderRadius: index == 0
              ? BorderRadius.only(topLeft: Radius.circular(10))
              : index == 2
              ? BorderRadius.only(topRight: Radius.circular(10))
              : null,
          color: color,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: FigmaSize.w(12),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
