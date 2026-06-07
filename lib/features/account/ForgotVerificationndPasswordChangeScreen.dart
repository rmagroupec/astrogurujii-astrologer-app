import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/core/widgets/footer_widget_login.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  /// Email and OTP are passed in from ForgotPasswordScreen
  final String email;
  final String otp;

  const ChangePasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOtpVerified = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Step 1: Verify OTP locally ────────────────────────────────────────────
  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;

    final enteredOtp = _otpController.text.trim();

    if (enteredOtp != widget.otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect OTP. Please check and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isOtpVerified = true);
  }

  // ── Step 2: Change password via API ──────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().post(
        'astrologer_api/verify_otp_change_password',
        {
          'email': widget.email,
          'otp': widget.otp,
          'new_password': _newPasswordController.text.trim(),
        },
        isAuthRequired: false,
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['result'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back to login (remove all routes above it)
        Navigator.of(context).popUntil((route) => route.isFirst);
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
      body: Column(
        children: [
          // ── Logo ────────────────────────────────────────────────────────
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

          // ── Form ────────────────────────────────────────────────────────
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title changes based on step
                    Text(
                      _isOtpVerified ? 'Set New Password' : 'Verify OTP',
                      style: TextStyle(
                        fontSize: FigmaSize.w(22),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(8)),
                    Text(
                      _isOtpVerified
                          ? 'Enter a strong new password for your account.'
                          : 'Enter the OTP sent to ${widget.email}',
                      style: TextStyle(
                        fontSize: FigmaSize.w(13),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(28)),

                    // ── Step 1: OTP input ──────────────────────────────────
                    if (!_isOtpVerified)
                      AppTextFormField(
                        controller: _otpController,
                        hintText: 'Enter OTP',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'OTP is required';
                          }
                          if (value.trim().length < 4) {
                            return 'Enter a valid 4-digit OTP';
                          }
                          return null;
                        },
                      ),

                    // ── Step 2: New password inputs ────────────────────────
                    if (_isOtpVerified) ...[
                      AppTextFormField(
                        controller: _newPasswordController,
                        hintText: 'New Password',
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (value.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: FigmaSize.h(16)),
                      AppTextFormField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value.trim() != _newPasswordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],

                    SizedBox(height: FigmaSize.h(28)),

                    AppGradientButton(
                      title: _isOtpVerified ? 'Change Password' : 'Verify OTP',
                      isLoading: _isLoading,
                      onPressed: _isOtpVerified ? _changePassword : _verifyOtp,
                    ),

                    SizedBox(height: FigmaSize.h(16)),

                    // Go back option
                    if (!_isOtpVerified)
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Wrong email? Go back',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: FigmaSize.w(13),
                            ),
                          ),
                        ),
                      ),

                    const Spacer(),
                    const DarkStatsHeader(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}