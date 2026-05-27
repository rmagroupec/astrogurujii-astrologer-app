import 'dart:convert';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Updatephonenumber extends StatefulWidget {
  const Updatephonenumber({super.key});

  @override
  State<Updatephonenumber> createState() => _UpdatephonenumberState();
}

class _UpdatephonenumberState extends State<Updatephonenumber> {
  TextEditingController _registeredPhone = new TextEditingController();
  TextEditingController _primaryPhone = new TextEditingController();
  TextEditingController _secondaryPhone = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Update Phone Number"),
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
            Padding(
              padding: EdgeInsets.all(FigmaSize.w(0)),
              child: Text(
                '''Register number is only for logging into the application. you will receive  calls and chat alert on your primary and secondary number only.''',
                style: TextStyle(
                  fontSize: FigmaSize.w(11),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            buildTextContentWithField(
              "7615976021",
              "Registered Phone Number",
              _registeredPhone,
            ),

            buildTextContentWithField(
              "7615976021",
              "Primary Phone Number",
              _primaryPhone,
            ),

            buildTextContentWithField(
              "7615976021",
              "Secondary   Phone Number",
              _secondaryPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextContentWithField(
    String? hintText,
    String? text,
    TextEditingController _controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: FigmaSize.h(37)),
        Text(
          text ?? "Registered Phone Number",
          style: TextStyle(
            fontSize: FigmaSize.w(16),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "+91",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: FigmaSize.w(18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: FigmaSize.w(9)),
                  SvgPicture.asset(
                    "assets/images/caret-arrow-up.svg",
                    height: FigmaSize.h(13),
                    width: FigmaSize.w(13),
                  ),
                ],
              ),
              SizedBox(width: FigmaSize.w(35)),
              // Phone number
              SizedBox(
                width: FigmaSize.w(159),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: const Color(0xFF838383),
                        fontSize: FigmaSize.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText ?? "Enter Phone Number",
                        hintStyle: TextStyle(
                          color: const Color(0xFF838383),
                          fontSize: FigmaSize.w(16),
                          fontWeight: FontWeight.w500,
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

              // Verify Button
              GestureDetector(
                onTap: () async {
                  dynamic data = {"number": _controller.text};

                  var sent = await ApiService().UpdatePhoneNumberFunc(data);
                  Map<String, dynamic> rsp = jsonDecode(sent.body);
                  if (rsp["result"]) {
                    showOtpSheet(
                      context: context,
                      phone: _controller.text,
                      onVerify: (otp) async {
                     dynamic newdata = {
                          "number": _controller.text,
                          "otp": otp,
                        };
                        final verified = await ApiService()
                            .UpdatePhoneNumberFunc(newdata);
                        Map<String, dynamic> rsp_data = jsonDecode(
                          verified.body,
                        );
                        if (rsp_data["result"]) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(rsp_data["message"])),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(rsp_data["message"])),
                          );
                        }
                      },
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFFCD417), Color(0xFFFFE569)],
                    ),
                    borderRadius: BorderRadius.circular(FigmaSize.w(10)),
                  ),
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showOtpSheet({
    required BuildContext context,
    required String phone,
    required Function(String otp) onVerify,
  }) {
    final otpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter OTP",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: "Enter 6 digit OTP",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onVerify(otpController.text.trim());
                  },
                  child: Text("Verify OTP"),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
