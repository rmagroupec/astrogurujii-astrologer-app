import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class Referastrologer extends StatefulWidget {
  const Referastrologer({super.key});

  @override
  State<Referastrologer> createState() => _ReferastrologerState();
}

class _ReferastrologerState extends State<Referastrologer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        title: Text("Refer Astrologer"),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(44),
              vertical: FigmaSize.h(16),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(44),
              vertical: FigmaSize.h(20),
            ),
            decoration: BoxDecoration(
              color: Color(0xFFFCD417).withOpacity(0.05),
              border: Border.all(color: Color(0xFFFCD417)),
              borderRadius: BorderRadius.circular(1),
            ),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  "Your Referral Code",
                  style: TextStyle(
                    fontSize: FigmaSize.w(13),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: FigmaSize.h(12)),
                DottedBorder(
                  options: RectDottedBorderOptions(
                    // rounded corners
                    color: const Color(0xFFD41000),
                    strokeWidth: 1,
                    dashPattern: const [6, 4],
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: FigmaSize.h(16),
                      horizontal: FigmaSize.w(44),
                    ),
                    color: Colors.white,
                    child: Text(
                      "MTKy0Dg=",
                      style: TextStyle(
                        fontSize: FigmaSize.w(15),
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD41000),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: FigmaSize.h(9)),
                Text(
                  "Tap to copy",
                  style: TextStyle(
                    fontSize: FigmaSize.w(13),
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD41000),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: FigmaSize.w(132)),
            child: Center(child: Text("No Data Available")),
          ),
        ],
      ),
      bottomNavigationBar: GradientButton(
        title: "+ Refer an Astrologer",
        onTap: () {
          // your action here
        },
      ),
    );
  }
}
