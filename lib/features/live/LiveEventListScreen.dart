import 'dart:ui';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/features/live/GoLiveScreen.dart';
import 'package:astrologer_app/features/live/ScheduleLiveEvents.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:flutter/material.dart';

class LiveEventListScreen extends StatefulWidget {
  const LiveEventListScreen({super.key});

  @override
  State<LiveEventListScreen> createState() => _LiveEventListScreenState();
}

class _LiveEventListScreenState extends State<LiveEventListScreen> {
  bool isLoading = true;
  List<LiveEventData>? data;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().LiveEventsList(); // your API
      setState(() {
        data = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Live Events"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                vertical: FigmaSize.h(15),
                horizontal: FigmaSize.w(20),
              ),
              child: ListView.builder(
                itemCount: 7,
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(
                        height: FigmaSize.h(116),
                        width: double.infinity,
                        child: Stack(
                          children: [
                            /// 🔹 Background Image
                            Container(
                              height: FigmaSize.h(116),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    "assets/images/4002487859e231b42e4088d553cfb27222391230.png",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black.withOpacity(0.60),
                              ),
                            ),

                            /// 🔹 CONTENT ABOVE BLUR
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: FigmaSize.w(13),
                                  vertical: FigmaSize.h(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Live Session",
                                      style: TextStyle(
                                        fontSize: FigmaSize.w(17),
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD41000),
                                      ),
                                    ),

                                    Text(
                                      "${data![index].startTime.toString()}",
                                      style: TextStyle(
                                        fontSize: FigmaSize.w(12),
                                        height: 24 / FigmaSize.w(12),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "On ${data![index].liveDate.toString()}",
                                      style: TextStyle(
                                        fontSize: FigmaSize.w(12),
                                        height: 24 / FigmaSize.w(12),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "STATUS : ${data![index].status}",
                                      style: TextStyle(
                                        fontSize: FigmaSize.w(12),
                                        height: 24 / FigmaSize.w(12),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: FigmaSize.h(14)),
                    ],
                  );
                },
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
        margin: EdgeInsets.only(bottom: 10),
        width: double.infinity,
        height: FigmaSize.h(56),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppGradientButton(
              title: "Schedule Event",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Scheduleliveevents()),
                );
              },
              width: FigmaSize.designWidth / 2.6,
            ),
            AppGradientButton(
              title: "Go Live Now",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoLiveScreen()),
                );
              },
              width: FigmaSize.designWidth / 2.6,
            ),
          ],
        ),
      ),
    );
  }
}
