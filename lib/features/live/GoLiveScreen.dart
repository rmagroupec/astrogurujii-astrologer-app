import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF000000).withOpacity(0.36),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: FigmaSize.h(88)),
            Container(
              height: FigmaSize.h(235),
              width: FigmaSize.w(270),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset("assets/images/go_live.svg"),
                  ),
                  Positioned(
                    top: FigmaSize.h(115),
                    left: FigmaSize.w(105),
                    child: Text(
                      "Face Here",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(FigmaSize.w(13)),
              height: FigmaSize.h(58),
              width: FigmaSize.w(58),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: SvgPicture.asset("assets/images/mic.svg"),
            ),
            SizedBox(width: FigmaSize.w(8),),
            Container(
              padding: EdgeInsets.all(FigmaSize.w(13)),
              height: FigmaSize.h(58),
              width: FigmaSize.w(58),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: SvgPicture.asset("assets/images/video-camera.svg"),
            ),
            GradientButton(
              width: FigmaSize.w(191),
              title: "Click to Go Live",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
