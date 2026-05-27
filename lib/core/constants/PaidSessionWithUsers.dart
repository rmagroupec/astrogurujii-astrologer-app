import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Paidsessionwithusers extends StatefulWidget {
  const Paidsessionwithusers({super.key});

  @override
  State<Paidsessionwithusers> createState() => _PaidsessionwithusersState();
}

class _PaidsessionwithusersState extends State<Paidsessionwithusers> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: FigmaSize.h(15),
        horizontal: FigmaSize.w(22),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Start Paid Session with Users",
                style: TextStyle(
                  fontSize: FigmaSize.w(15),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                "View All",
                style: TextStyle(
                  fontSize: FigmaSize.w(15),
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFD41000),
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(21)),
          SizedBox(
            width: double.infinity,
            height: FigmaSize.h(124),
            child: ListView.builder(
              itemCount: 7,
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: FigmaSize.w(10)),
                  padding: EdgeInsets.symmetric(
                    vertical: FigmaSize.h(12),
                    horizontal: FigmaSize.w(12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 1, color: Color(0x17000000)),
                    borderRadius: BorderRadius.circular(FigmaSize.w(10)),
                  ),
                  child: Column(
                    spacing: FigmaSize.h(16),
                    children: [
                      Row(
                        spacing: FigmaSize.w(18),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: FigmaSize.w(11),
                            children: [
                              Container(
                                width: FigmaSize.w(47),
                                height: FigmaSize.h(47),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 1,
                                    color: Color(0xFF34A853),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      "https://www.creativehatti.com/wp-content/uploads/edd/2021/08/Indian-pandit-illustration-with-greet-hands-4-large.jpg",
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bhumika",
                                    style: TextStyle(
                                      fontSize: FigmaSize.w(12),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Spend ₹500+",
                                    style: TextStyle(
                                      fontSize: FigmaSize.w(9),
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF898989),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: FigmaSize.h(2),
                              horizontal: FigmaSize.w(8),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFCD417).withOpacity(0.15),
                              border: Border.all(
                                width: 1,
                                color: Color(0xFFFCD417).withOpacity(0.26),
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              spacing: FigmaSize.w(3),
                              children: [
                                Icon(
                                  Icons.watch_later_outlined,
                                  color: Colors.black,
                                  size: FigmaSize.w(15),
                                ),
                                Text(
                                  "4 min",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(12),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Row(
                        spacing: FigmaSize.w(32),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CallChatActionButton(
                            'Call',
                            "assets/images/call_icon.svg",
                            () {},
                          ),
                          CallChatActionButton(
                            'Chat',
                            "assets/images/bubble-chat.svg",
                            () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget CallChatActionButton(String name, String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(22),
          vertical: FigmaSize.h(5),
        ),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Color(0xFF34A853)),
          color: Color(0xFFF1FAF8),
          borderRadius: BorderRadius.circular(FigmaSize.w(4)),
        ),
        child: Row(
          spacing: FigmaSize.w(5),
          children: [
            SvgPicture.asset(icon),
            Text(
              name,
              style: TextStyle(
                fontSize: FigmaSize.w(12),
                fontWeight: FontWeight.w600,
                color: Color(0xFF34A853),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
