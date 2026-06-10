import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/RoundedIconWidgetForHome.dart';
import 'package:astrologer_app/features/Settings/MyCommunityScreen.dart';
import 'package:astrologer_app/features/Settings/MyReviewScreen.dart';
import 'package:astrologer_app/features/Settings/OfferHistoryScreen.dart';
import 'package:astrologer_app/features/Settings/OfferScreen.dart';
import 'package:astrologer_app/features/Settings/SuggestedPujaScreen.dart';
import 'package:astrologer_app/features/account/AstrologerSideDrawer.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/features/account/WalletScreen.dart';
import 'package:astrologer_app/features/live/LiveEventListScreen.dart';
import 'package:astrologer_app/features/live/WaitlistScreen.dart';
import 'package:astrologer_app/features/reports/MainReportsScreen.dart';
import 'package:astrologer_app/features/service/ChatScreen.dart' show AstrologerChatScreen, ChatScreen;
import 'package:astrologer_app/features/service/IncomingChatScreen.dart';
import 'package:astrologer_app/features/service/IncomingVideoCallScreen.dart';
import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/service/navigationservice.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeIconGrid extends StatelessWidget {
  const HomeIconGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Define your data in a simple list
    final List<Map<String, dynamic>> menuItems = [
      {"icon": "phone.svg", "label": "Call","page": MainReportsScreen(page: "audio",)},
      {"icon": "chat.svg", "label": "Chat","page": MainReportsScreen(page: "chat",)},
      {"icon": "videocall.svg", "label": "Video Call","page": MainReportsScreen(page: "video",)},
      {"icon": "online-shopping.svg", "label": "AstroMall","page":MainReportsScreen(page: "Astromall",)},
      {"icon": "live.svg", "label": "Go Live", "page":LiveEventListScreen()},
      {"icon": "phone.svg", "label": "Waitlist","page": Waitlistscreen()},
      {"icon": "chat_assistant.svg", "label": "Assistant","page": SupportChatScreen()},
      {"icon": "puja.svg", "label": "Pooja", "page":PoojaBookingScreen()},
      {"icon": "offers.svg", "label": "Offers", "page":OffersScreen()},
      {"icon": "review.svg", "label": "Reviews", "page":MyReviewsScreen()},
      {"icon": "wallet2.svg", "label": "Wallet","page": WalletScreen()},
      {"icon": "user (1) 1.svg", "label": "Profile", "page":AstrologerProfileScreen()
    





    },
      {"icon": "diversity1.svg", "label": "Community", "page": MyCommunityFollowers()},
    ];

    return GridView.builder(
      shrinkWrap: true, // Important: allows GridView to be inside a Column/Scrollview
      physics: const NeverScrollableScrollPhysics(), // Let the parent scroll
      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 items per row
        mainAxisSpacing: FigmaSize.h(5), // Vertical spacing
        crossAxisSpacing: FigmaSize.w(10), // Horizontal spacing
        childAspectRatio: 0.62, // Adjust this to fit your label height
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return RoundedIconForHome(
          iconPath: "assets/images/${menuItems[index]['icon']}",
          label: menuItems[index]['label']!,
          onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => menuItems[index]['page']));
          },
        );
      },
    );
  }
  // In your notification handler or wherever you trigger the incoming chat
}