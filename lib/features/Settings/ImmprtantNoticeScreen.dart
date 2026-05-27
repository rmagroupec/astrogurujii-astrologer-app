import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/components/commonWidget.dart';
import 'package:flutter/material.dart';

class ImportantNoticeScreen extends StatefulWidget {
  const ImportantNoticeScreen({super.key});

  @override
  State<ImportantNoticeScreen> createState() => _ImportantNoticeScreenState();
}

class _ImportantNoticeScreenState extends State<ImportantNoticeScreen> {
  int selectedTab = 0; // 0 = All, 1 = Unread

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
       appBar: yellowAppBar("Important Notice"),
      body: Column(
        children: [
          _tabs(),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (_, index) {
                final bool isUnread = index < 2;
                return _noticeTile(
                  title: index == 0
                      ? "Astromall Team"
                      : "Akash Tiwari, HOD",
                  subtitle: "Important Update from head office...",
                  date: index == 0 ? "Oct 15" : "Oct 12",
                  unreadCount: index == 0
                      ? 1
                      : index == 1
                          ? 10
                          : 0,
                  isUnread: isUnread,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Tabs ----------------

  Widget _tabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _tabItem("All", 0),
          _tabItem("Unread", 1),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    final bool selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Column(
          children: [
             SizedBox(height:  FigmaSize.h(12),),
            Text(
              title,
              style: TextStyle(
                fontSize: FigmaSize.w(14),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
             SizedBox(height:  FigmaSize.h(10),),
            Container(
              height:  FigmaSize.h(2),
              width:  FigmaSize.w(110),
              color:
                  selected ? const Color(0xFFFCD417) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Notification Tile ----------------

  Widget _noticeTile({
    required String title,
    required String subtitle,
    required String date,
    required int unreadCount,
    required bool isUnread,
  }) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal:  FigmaSize.w(16), vertical: FigmaSize.h(12),),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            height: FigmaSize.h(42),
            width: FigmaSize.w(42)  ,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFCD417)),
              image: const DecorationImage(
                image: AssetImage("assets/images/profile_placeholder.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

           SizedBox(width: FigmaSize.w(12),),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: FigmaSize.w(14),
                    color: isUnread ? Colors.black : Colors.grey,
                  ),
                ),
                 SizedBox(height: FigmaSize.h(4),),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: FigmaSize.w(12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Right side
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(fontSize: FigmaSize.w(11), color: Colors.black),
              ),
               SizedBox(height: FigmaSize.h(8),),
              if (unreadCount > 0)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: FigmaSize.w(6), vertical: FigmaSize.h(2)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD417),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style:  TextStyle(
                      fontSize: FigmaSize.w(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
