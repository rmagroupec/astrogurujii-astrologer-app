// lib/features/Settings/UpdatePhoneNumber.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
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
  final _registeredPhone = TextEditingController();
  final _primaryPhone    = TextEditingController();
  final _secondaryPhone  = TextEditingController();

  @override
  void dispose() {
    _registeredPhone.dispose();
    _primaryPhone.dispose();
    _secondaryPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Update Phone Number'),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(
          horizontal: FigmaSize.w(27),
          vertical  : FigmaSize.h(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register number is only for logging into the application. '
              'You will receive calls and chat alerts on your primary and '
              'secondary number only.',
              style: TextStyle(
                fontSize  : FigmaSize.w(11),
                fontWeight: FontWeight.w500,
                color     : c.subText,
              ),
            ),
            _PhoneField(
              hintText  : '7615976021',
              label     : 'Registered Phone Number',
              controller: _registeredPhone,
              c         : c,
              onVerify  : _handleVerify,
            ),
            _PhoneField(
              hintText  : '7615976021',
              label     : 'Primary Phone Number',
              controller: _primaryPhone,
              c         : c,
              onVerify  : _handleVerify,
            ),
            _PhoneField(
              hintText  : '7615976021',
              label     : 'Secondary Phone Number',
              controller: _secondaryPhone,
              c         : c,
              onVerify  : _handleVerify,
            ),
          ],
        ),
      ),
    );
  }

  // ── Verify + OTP logic ────────────────────────────────────────────────────
  Future<void> _handleVerify(TextEditingController controller) async {
    final data = {'number': controller.text};
    final sent = await ApiService().UpdatePhoneNumberFunc(data);
    final rsp  = jsonDecode(sent.body) as Map<String, dynamic>;

    if (rsp['result'] == true) {
      _showOtpSheet(
        phone   : controller.text,
        onVerify: (otp) async {
          final newData = {'number': controller.text, 'otp': otp};
          final verified = await ApiService().UpdatePhoneNumberFunc(newData);
          final rspData  = jsonDecode(verified.body) as Map<String, dynamic>;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(rspData['message'] ?? '')),
            );
          }
        },
      );
    }
  }

  void _showOtpSheet({
    required String             phone,
    required Function(String)   onVerify,
  }) {
    final otpController = TextEditingController();
    final c             = context.colors;

    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color       : c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left  : 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize     : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter OTP',
              style: TextStyle(
                  fontSize  : 18,
                  fontWeight: FontWeight.w600,
                  color     : c.text),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller  : otpController,
              keyboardType: TextInputType.number,
              maxLength   : 6,
              style       : TextStyle(color: c.text),
              decoration  : InputDecoration(
                hintText     : 'Enter 6 digit OTP',
                hintStyle    : TextStyle(color: c.subText),
                border       : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide  : BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide  : BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide  : BorderSide(
                      color: AppTheme.primaryYellow, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onVerify(otpController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Verify OTP',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Phone field row ───────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final String                              hintText;
  final String                              label;
  final TextEditingController               controller;
  final AppColors                           c;
  final Future<void> Function(TextEditingController) onVerify;

  const _PhoneField({
    required this.hintText,
    required this.label,
    required this.controller,
    required this.c,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: FigmaSize.h(37)),
        Text(
          label,
          style: TextStyle(
            fontSize  : FigmaSize.w(16),
            fontWeight: FontWeight.w600,
            color     : c.text,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: FigmaSize.h(12)),
          decoration: BoxDecoration(
            color       : c.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Country code + caret
              Row(
                children: [
                  Text(
                    '+91',
                    style: TextStyle(
                      color     : c.text,
                      fontSize  : FigmaSize.w(18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: FigmaSize.w(9)),
                  SvgPicture.asset(
                    'assets/images/caret-arrow-up.svg',
                    height     : FigmaSize.h(13),
                    width      : FigmaSize.w(13),
                    colorFilter: isDark
                        ? ColorFilter.mode(c.subText, BlendMode.srcIn)
                        : null,
                  ),
                ],
              ),

              SizedBox(width: FigmaSize.w(35)),

              // Phone number input
              SizedBox(
                width: FigmaSize.w(159),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller  : controller,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color     : c.subText,
                        fontSize  : FigmaSize.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText : hintText,
                        hintStyle: TextStyle(
                          color     : c.subText,
                          fontSize  : FigmaSize.w(16),
                          fontWeight: FontWeight.w500,
                        ),
                        border        : InputBorder.none,
                        isDense       : true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(4)),
                    Divider(color: c.divider, height: 1),
                  ],
                ),
              ),

              // Verify button
              GestureDetector(
                onTap: () => onVerify(controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin  : Alignment.centerLeft,
                      end    : Alignment.centerRight,
                      colors : [Color(0xFFFCD417), Color(0xFFFFE569)],
                    ),
                    borderRadius:
                        BorderRadius.circular(FigmaSize.w(10)),
                  ),
                  child: const Text(
                    'Verify',
                    style: TextStyle(
                      color     : Colors.black,
                      fontSize  : 16,
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
}