import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Loyaluserfeedbackcomponent extends StatelessWidget {
  const Loyaluserfeedbackcomponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: FigmaSize.h(15),
        horizontal: FigmaSize.w(18),
      ),
      decoration: BoxDecoration(color: Color(0xFFFEF8D9)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FigmaSize.h(8),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FigmaSize.w(10),
                  children: [
                    SvgPicture.asset("assets/images/message.svg"),
                    Text(
                      "Bring your Loyal Users Back",
                      style: TextStyle(
                        fontSize: FigmaSize.w(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  "List of your Loyal User Who haven’t spoken to you in a While",
                  style: TextStyle(
                    fontSize: FigmaSize.w(12),
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF898989),
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset("assets/images/right_arrow.svg"),
        ],
      ),
    );
  }
}
