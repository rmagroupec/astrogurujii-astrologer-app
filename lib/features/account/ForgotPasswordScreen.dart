import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/core/widgets/footer_widget_login.dart';
import 'package:astrologer_app/features/account/ForgotVerificationndPasswordChangeScreen.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().post(
        'astrologer_api/forgot_password_otp',
        {'email': _emailController.text.trim()},
        isAuthRequired: false,
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['result'] == true) {
        print(data);
        final String otp = data['otp'].toString();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
              email: _emailController.text.trim(),
              otp: otp,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Something went wrong'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SizedBox(
        height: FigmaSize.screenHeight,
        width: FigmaSize.screenWidth,
        child: Column(
          children: [
            // ── Logo ──────────────────────────────────────────────────────
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
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ── Form ──────────────────────────────────────────────────────
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: FigmaSize.h(50),
                  horizontal: FigmaSize.w(43),
                ),
                width: FigmaSize.screenWidth,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: FigmaSize.w(22),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: FigmaSize.h(8)),
                      Text(
                        'Enter your registered email. We\'ll send you an OTP to reset your password.',
                        style: TextStyle(
                          fontSize: FigmaSize.w(13),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: FigmaSize.h(28)),

                      // Email field
                      AppTextFormField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: FigmaSize.h(28)),

                      AppGradientButton(
                        title: 'Send OTP',
                        isLoading: _isLoading,
                        onPressed: _sendOtp,
                      ),

                      SizedBox(height: FigmaSize.h(20)),

                      // Back to login
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Remember your password? ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: FigmaSize.w(13),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: FigmaSize.w(13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      DarkStatsHeader(color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}