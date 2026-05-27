import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RoundedIconForHome extends StatelessWidget {
  
  final String iconPath;  
  final String label;
  final VoidCallback onTap;
  const RoundedIconForHome({super.key, required this.iconPath, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Column(
          children: [
            Container(
              width: FigmaSize.w(52),
              height: FigmaSize.h(52),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x33FCD417), // #FCD417 at 20% opacity
                    Color(0x33FED402), // #FED402 at 20% opacity
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  height: FigmaSize.h(30),
                  width: FigmaSize.w(30),
                ),
              ),
            ),
            SizedBox(height: FigmaSize.h(6)),
            Text(
              label ,
              style: TextStyle(
                fontSize: FigmaSize.w(13),
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
