import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconForSetting extends StatelessWidget {
  
  final String iconPath;  
  final String label;
  final VoidCallback onTap;
  const IconForSetting({super.key, required this.iconPath, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10), horizontal: FigmaSize.w(10)),
        decoration: BoxDecoration(color: Color(0xFFFCD417).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Container(
              width: FigmaSize.w(52),
              height: FigmaSize.h(52),
              decoration: BoxDecoration(
                color: Colors.white,
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
                fontSize: FigmaSize.w(11),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
