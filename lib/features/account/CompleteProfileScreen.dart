import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:flutter/material.dart';
import 'package:astrologer_app/core/utils/size_config.dart';

class CompleteProfileScreen extends StatelessWidget {
  final Astrologer astrologerData;
  const CompleteProfileScreen({super.key, required this.astrologerData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Complete your Profile"),
        backgroundColor: const Color(0xFFFCD417),
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16),
          vertical: FigmaSize.h(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [

            /// PROFILE CARD
            Container(
              padding: EdgeInsets.all(FigmaSize.w(12)),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFCD417)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// PROFILE IMAGE
                  Container(
                    height: FigmaSize.h(72),
                    width: FigmaSize.w(72),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(
                          astrologerData.profileImg.isNotEmpty
                              ? astrologerData.profileImg
                              : "https://i.pravatar.cc/300",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(width: FigmaSize.w(12)),

                  /// PROFILE DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _richLine(
                          "Real Name : ",
                          astrologerData.displayname,
                          isBold: true,
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        _richLine(
                          "Display Name : ",
                          astrologerData.displayname,
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        Text(
                          astrologerData.email,
                          style: TextStyle(
                            fontSize: FigmaSize.w(12),
                            color: const Color(0xFFD41000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        _iconLine(
                          "Registered No. : +91${astrologerData.number}",
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        _iconLine(
                          "Primary No. : +91${astrologerData.number}",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: FigmaSize.h(24)),

            /// BASIC DETAILS
            Text(
              "Basic Details",
              style: TextStyle(
                fontSize: FigmaSize.w(14),
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: FigmaSize.h(12)),

            _inputField(astrologerData.dob.isNotEmpty
                ? astrologerData.dob
                : "Please select date of birth"),

            SizedBox(height: FigmaSize.h(14)),

            _label("Time of Birth"),
            _inputField("Please select time of birth"),

            SizedBox(height: FigmaSize.h(14)),

            _label("Place of birth"),
            _inputField(astrologerData.address.isNotEmpty
                ? astrologerData.address
                : "Please select place of birth"),

            SizedBox(height: FigmaSize.h(14)),

            _label("Faith"),
            _inputField("Select Faith"),

            SizedBox(height: FigmaSize.h(14)),

            _label("Current Address"),
            _inputField(astrologerData.address.isNotEmpty
                ? astrologerData.address
                : "Enter Address"),

            SizedBox(height: FigmaSize.h(14)),

            _label("City"),
            _inputField("Enter Town / City"),

            SizedBox(height: FigmaSize.h(30)),

            /// SUBMIT BUTTON (UI unchanged)
            Container(
              width: double.infinity,
              height: FigmaSize.h(48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2B2B2B),
                    Color(0xFF4A3F36),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- HELPERS (UNCHANGED UI) ----------

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: FigmaSize.h(6)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: FigmaSize.w(12),
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _inputField(String hint) {
    return TextFormField(
      initialValue: hint,
      readOnly: true, // keeps same UI behavior
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: FigmaSize.w(12),
          color: Colors.grey,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(12),
          vertical: FigmaSize.h(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _richLine(String label, String value, {bool isBold = false}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: FigmaSize.w(12),
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconLine(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: FigmaSize.w(12),
              color: const Color(0xFFD41000),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(Icons.edit, size: 16, color: Colors.grey),
      ],
    );
  }
}
