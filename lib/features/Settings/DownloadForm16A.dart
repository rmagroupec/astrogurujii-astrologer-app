import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Downloadform16a extends StatefulWidget {
  const Downloadform16a({super.key});

  @override
  State<Downloadform16a> createState() => _Downloadform16aState();
}

class _Downloadform16aState extends State<Downloadform16a> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Download Form 16A"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),

      body: Container(
        padding: EdgeInsets.symmetric(
          vertical: FigmaSize.h(18),
          horizontal: FigmaSize.w(20),
        ),
        child: ListView.builder(
          itemCount: 6,
          shrinkWrap: true,
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: FigmaSize.h(2),
                horizontal: FigmaSize.w(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "GSFPP1020J_2025-26",
                        style: TextStyle(
                          fontSize: FigmaSize.w(14),
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF838383),
                        ),
                      ),
                      SvgPicture.asset("assets/images/download.svg"),
                    ],
                  ),
                  SizedBox(height: FigmaSize.h(14)),
                  Divider(color: Color(0xFF000000).withOpacity(0.06)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
