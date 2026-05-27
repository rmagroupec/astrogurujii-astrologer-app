import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/constants/LoyalUserFeedbackComponent.dart';
import 'package:astrologer_app/core/constants/PaidSessionWithUsers.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/core/widgets/homeIconGrid.dart';
import 'package:astrologer_app/features/Settings/ImmprtantNoticeScreen.dart';
import 'package:astrologer_app/features/Settings/MainSettingScreen.dart';
import 'package:astrologer_app/features/Settings/SupportScreen.dart';
import 'package:astrologer_app/features/Settings/notificationScreen.dart';
import 'package:astrologer_app/features/account/AstrologerSideDrawer.dart';
import 'package:astrologer_app/features/account/SupportChatScreen.dart';
import 'package:astrologer_app/features/modal/LanguageModal.dart';
import 'package:astrologer_app/model/AstrogurujiiConfirmationModal.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Astrologer? astrologerData;
  bool isLoading = true;
  bool chatEnabled = false;
  bool voiceEnabled = false;
  bool videoEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchAstrologerProfile();
  }

  void fetchAstrologerProfile() async {
    try {
      var response = await ApiService().get_astrologer_profile();

      setState(() {
        astrologerData = response.results.isNotEmpty
            ? response.results[0]
            : null;
        chatEnabled = astrologerData?.isChatEnabled ?? false;
        voiceEnabled = astrologerData?.isVoiceCallEnabled ?? false;
        videoEnabled = astrologerData?.isVideoCallEnabled ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Exception: $e");
    }
  }

  bool _isSwitched = false;
  void _showLanguagePopup(BuildContext context) {
    showDialog(context: context, builder: (context) => const LanguagePopup());
  }

  void _confirmToggle({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DivinConfirmDialog(
        title: title,
        message: message,
        onYes: () {
          Navigator.pop(context);
          onConfirm();
        },
        onNo: () {
          Navigator.pop(context);
          onCancel();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return isLoading
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            appBar: AppBar(
              foregroundColor: Colors.black,
              backgroundColor: AppTheme.primaryColor,
              actions: [
                SVGIconHome(
                  "assets/images/walllet.svg",
                  FigmaSize.h(20),
                  FigmaSize.w(20),
                  Colors.black,
                  () {},
                ),
                SizedBox(width: FigmaSize.w(20)),
                SVGIconHome(
                  "assets/images/assistant.svg",
                  FigmaSize.h(35),
                  FigmaSize.w(35),
                  Colors.black,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AstrogurujiiSupportScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(width: FigmaSize.w(20)),
              ],
              automaticallyImplyLeading: false,
              title: Container(
                child: Row(
                  children: [
                    SizedBox(width: FigmaSize.w(20)),
                    SVGIconHome(
                      "assets/images/profile 2.svg",
                      FigmaSize.h(35),
                      FigmaSize.w(35),
                      Colors.black,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AstrologerProfileScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: FigmaSize.w(25)),
                    SVGIconHome(
                      "assets/images/notification 1.svg",
                      FigmaSize.h(25),
                      FigmaSize.w(25),
                      Colors.black,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              elevation: 1,
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(10),
                      vertical: FigmaSize.h(16),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(12),
                      vertical: FigmaSize.h(16),
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(FigmaSize.w(10)),
                      border: Border.all(color: Color(0xFF0000000A), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Chat",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(15),
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: FigmaSize.h(5)),
                                Text(
                                  "Aug, 21 07:30 PM",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(12),
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF343434),
                                  ),
                                ),
                              ],
                            ),
                            CustomToggleSwitch(
                              value: chatEnabled,
                              onChanged: (newValue) {
                                if (newValue) {
                                  _confirmToggle(
                                    title: "Enable Chat",
                                    message:
                                        "Are you sure you want to go online for chat?",
                                    onConfirm: () {
                                      setState(() => chatEnabled = true);
                                      ApiService().updateAvailableStatus(
                                        isChat: true,
                                      );
                                    },
                                    onCancel: () {
                                      setState(() => chatEnabled = false);
                                    },
                                  );
                                } else {
                                  setState(() => chatEnabled = false);
                                  ApiService().updateAvailableStatus(
                                    isChat: false,
                                  );
                                }
                              },
                            ),

                            Text(
                              "₹ ${astrologerData?.perMinChat.toString()} /min",
                              style: TextStyle(
                                fontSize: FigmaSize.w(15),
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: FigmaSize.h(23)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Call",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(15),
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: FigmaSize.h(5)),
                                Text(
                                  "Aug, 21 07:30 PM",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(12),
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF343434),
                                  ),
                                ),
                              ],
                            ),
                            CustomToggleSwitch(
                              value: voiceEnabled,
                              onChanged: (newValue) {
                                if (newValue) {
                                  _confirmToggle(
                                    title: "Enable Call",
                                    message:
                                        "Are you sure you want to go online for calls?",
                                    onConfirm: () {
                                      setState(() => voiceEnabled = true);
                                      ApiService().updateAvailableStatus(
                                        isVoiceCall: true,
                                      );
                                    },
                                    onCancel: () {
                                      setState(() => voiceEnabled = false);
                                    },
                                  );
                                } else {
                                  setState(() => voiceEnabled = false);
                                  ApiService().updateAvailableStatus(
                                    isVoiceCall: false,
                                  );
                                }
                              },
                            ),

                            Text(
                              "₹ ${astrologerData?.perMinVoiceCall.toString()} /min",
                              style: TextStyle(
                                fontSize: FigmaSize.w(15),
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: FigmaSize.h(23)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Video Call",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(15),
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: FigmaSize.h(5)),
                                Text(
                                  "Aug, 21 07:30 PM",
                                  style: TextStyle(
                                    fontSize: FigmaSize.w(12),
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF343434),
                                  ),
                                ),
                              ],
                            ),
                            CustomToggleSwitch(
                              value: videoEnabled,
                              onChanged: (newValue) {
                                if (newValue) {
                                  _confirmToggle(
                                    title: "Enable Video Call",
                                    message:
                                        "Are you sure you want to go online for video calls?",
                                    onConfirm: () {
                                      setState(() => videoEnabled = true);
                                      ApiService().updateAvailableStatus(
                                        isVideoCall: true,
                                      );
                                    },
                                    onCancel: () {
                                      setState(() => videoEnabled = false);
                                    },
                                  );
                                } else {
                                  setState(() => videoEnabled = false);
                                  ApiService().updateAvailableStatus(
                                    isVideoCall: false,
                                  );
                                }
                              },
                            ),

                            Text(
                              "₹ ${astrologerData?.perMinVideoCall.toString()} /min",
                              style: TextStyle(
                                fontSize: FigmaSize.w(15),
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: FigmaSize.h(10),
                      left: FigmaSize.w(23),
                    ),
                    child: Text(
                      "Services",
                      style: TextStyle(
                        fontSize: FigmaSize.w(13),
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD41000),
                      ),
                    ),
                  ),
                  HomeIconGrid(),

                  Paidsessionwithusers(),
                ],
              ),
            ),
          );
  }

  Widget SVGIconHome(
    String iconPath,
    double height,
    double width,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(iconPath),
      ),
    );
  }
}
