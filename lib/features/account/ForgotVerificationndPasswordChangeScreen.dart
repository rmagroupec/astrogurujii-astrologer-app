import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/core/widgets/footer_widget_login.dart';

import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isOtpVerified = false;
  bool isLoading = false;

  @override
  void dispose() {
   
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // 🔥 API CALL FOR OTP VERIFICATION
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
      isOtpVerified = true;
    });
  }

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // 🔥 API CALL FOR CHANGE PASSWORD
    await Future.delayed(const Duration(seconds: 2));

    setState(() => isLoading = false);

    // Navigate or show success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Column(
        children: [
          /// LOGO SECTION
          SizedBox(
            height: FigmaSize.h(304),
            child: Center(
              child: Container(
                height: FigmaSize.h(142),
                width: FigmaSize.w(142),
                padding: EdgeInsets.all(FigmaSize.w(12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(FigmaSize.w(20)),
                ),
                child: Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          /// FORM SECTION
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: FigmaSize.h(40),
                horizontal: FigmaSize.w(43),
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// EMAIL
                  

                    SizedBox(height: FigmaSize.h(16)),

                    /// OTP FIELD (ONLY BEFORE VERIFIED)
                    if (!isOtpVerified)
                      AppTextFormField(
                        controller: otpController,
                        hintText: "Enter OTP",
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.length < 4 ? "Invalid OTP" : null,
                      ),

                    /// PASSWORD FIELDS (AFTER OTP VERIFIED)
                    if (isOtpVerified) ...[
                      AppTextFormField(
                        controller: newPasswordController,
                        hintText: "New Password",
                        isPassword: true,
                        validator: (value) =>
                            value!.length < 6 ? "Min 6 characters" : null,
                      ),
                      SizedBox(height: FigmaSize.h(16)),
                      AppTextFormField(
                        controller: confirmPasswordController,
                        hintText: "Confirm Password",
                        isPassword: true,
                        validator: (value) =>
                            value != newPasswordController.text
                                ? "Passwords do not match"
                                : null,
                      ),
                    ],

                    SizedBox(height: FigmaSize.h(24)),

                    /// ACTION BUTTON
                    AppGradientButton(
                      title: isOtpVerified ? "Change Password" : "Verify OTP",
                      isLoading: isLoading,
                      onPressed:
                          isOtpVerified ? _changePassword : _verifyOtp,
                    ),

                    SizedBox(height: FigmaSize.h(32)),

                  ],
                ),
              ),
            ),
          ),

          /// FOOTER STATS
          const DarkStatsHeader(),
        ],
      ),
    );
  }
}
