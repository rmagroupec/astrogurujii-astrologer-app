import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/WaitingListResponseModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class Waitlistscreen extends StatefulWidget {
  const Waitlistscreen({super.key});

  @override
  State<Waitlistscreen> createState() => _WaitlistscreenState();
}

class _WaitlistscreenState extends State<Waitlistscreen> {
  bool isLoading = true;
  List<UserChatData>? data;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().WaitingUserList(); // your API
      setState(() {
        data = response.data2;
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
        title: Text("Waitlist"),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      itemCount: 7,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: FigmaSize.h(16)),
                          padding: EdgeInsets.symmetric(
                            vertical: FigmaSize.h(16),
                            horizontal: FigmaSize.w(16),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Color(0xFFE7E7E7),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(
                              FigmaSize.w(10),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: FigmaSize.w(11),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: "Repeat (Indian) | ",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: "Waiting",
                                          style: TextStyle(
                                            color: Color(0xFF1877F2),
                                          ),
                                        ),
                                        TextSpan(
                                          text: " | ",
                                          style: TextStyle(
                                            color: Color(0xFFD41000),
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Loyal",
                                          style: TextStyle(
                                            color: Color(0xFFD41000),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: FigmaSize.h(8)),
                              Divider(),
                              SizedBox(height: FigmaSize.h(9)),
                              Row(
                                spacing: FigmaSize.w(12),
                                children: [
                                  Container(
                                    height: FigmaSize.h(26),
                                    width: FigmaSize.w(26),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 1,
                                        color: Color(0xFFFCD417),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          data![index].image.toString(),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${data![index].name.toString()}",
                                    style: TextStyle(
                                      fontSize: FigmaSize.w(14),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "(#${data![index].id.toString()})",
                                    style: TextStyle(
                                      fontSize: FigmaSize.w(14),
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: FigmaSize.h(10)),
                              Text(
                                "${data![index].createdAt.toString()}",
                                style: TextStyle(
                                  fontSize: FigmaSize.w(12),
                                  fontWeight: FontWeight.w600,

                                  color: Color(0xFFD41000),
                                ),
                              ),
                              SizedBox(height: FigmaSize.h(8)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow(
                                    "Name",
                                    "${data![index].name.toString()}",
                                  ),

                                  _infoRow(
                                    "Type",
                                    "${data![index].type.toString() != "" ? data![index].type.toString() : "Chat"}",
                                  ),

                                  _infoRow("Token", "1"),

                                  _infoRow("Duration", "8 Mins"),
                                ],
                              ),
                              SizedBox(height: FigmaSize.h(8)),
                              Container(
                                width: FigmaSize.w(137),
                                padding: EdgeInsets.symmetric(
                                  vertical: FigmaSize.h(4),
                                  horizontal: FigmaSize.w(23),
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    "Start Offline Session",
                                    style: TextStyle(
                                      fontSize: FigmaSize.w(9),
                                      fontWeight: FontWeight.bold, // 🔑 bld
                                      color: Colors.black,
                                      height: 24 / FigmaSize.w(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(String keyText, String valueText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: FigmaSize.w(70), // 👈 SAME WIDTH FOR ALL KEYS
          child: Text(
            "$keyText",
            style: TextStyle(
              fontSize: FigmaSize.w(12),
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 16 / FigmaSize.w(12),
            ),
          ),
        ),
        Text(
          ":  ",
          style: TextStyle(
            fontSize: FigmaSize.w(12),
            fontWeight: FontWeight.w500,

            height: 16 / FigmaSize.w(12),
          ),
        ),
        Expanded(
          child: Text(
            valueText,
            style: TextStyle(
              fontSize: FigmaSize.w(12),
              fontWeight: FontWeight.bold, // 🔑 bld
              color: Colors.black,
              height: 16 / FigmaSize.w(12),
            ),
          ),
        ),
      ],
    );
  }
}
