import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Payslipscreen extends StatefulWidget {
  const Payslipscreen({super.key});

  @override
  State<Payslipscreen> createState() => _PayslipscreenState();
}

class _PayslipscreenState extends State<Payslipscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Pay Slip"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(
          horizontal: FigmaSize.w(27),
          vertical: FigmaSize.h(11),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: FigmaSize.designWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: const Color(0xFF838383),
                      fontSize: FigmaSize.w(16),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Select Start Month" ?? "Enter Phone Number",
                      hintStyle: TextStyle(
                        color: const Color(0xFF838383),
                        fontSize: FigmaSize.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: SizedBox(
                        width: FigmaSize.w(20),
                        height: FigmaSize.h(20),
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/images/calendar.svg",
                            width: FigmaSize.w(20),
                            height: FigmaSize.h(20),
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(4)),
                  Divider(
                    color: const Color(0xFF000000).withOpacity(0.06),
                    height: 1,
                  ),
                ],
              ),
            ),
            SizedBox(height: FigmaSize.h(20)),
            SizedBox(
              width: FigmaSize.designWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: const Color(0xFF838383),
                      fontSize: FigmaSize.w(16),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Select end Month" ?? "Enter Phone Number",
                      hintStyle: TextStyle(
                        color: const Color(0xFF838383),
                        fontSize: FigmaSize.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: SizedBox(
                        width: FigmaSize.w(20),
                        height: FigmaSize.h(20),
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/images/calendar.svg",
                            width: FigmaSize.w(20),
                            height: FigmaSize.h(20),
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(4)),
                  Divider(
                    color: const Color(0xFF000000).withOpacity(0.06),
                    height: 1,
                  ),
                ],
              ),
            ),
            SizedBox(height: FigmaSize.h(60)),
            GradientButton(title: "Send on Email", onTap: () {}),
          ],
        ),
      ),
    );
  }
}
