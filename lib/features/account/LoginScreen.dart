import 'dart:convert';

import 'package:astrologer_app/MainNavScreen.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/core/widgets/footer_widget_login.dart';
import 'package:astrologer_app/features/account/ForgotPasswordScreen.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/localStorageService.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ Moved controllers & key into State so they persist across rebuilds
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    // ✅ Properly dispose controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isObscure = true;
  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          await LocalStorageService().saveLoginData(data);

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavScreen()),
            (route) => false,
          );
        } else {
          // ✅ Show server-side error message if available
          final message = data['message'] ?? 'Invalid credentials. Please try again.';
          _showError(message);
        }
      } else if (response.statusCode == 401) {
        _showError('Invalid email or password.');
      } else {
        _showError('Something went wrong (${response.statusCode}). Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      // ✅ Prevents overflow when keyboard opens
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: FigmaSize.screenHeight,
          ),
          child: Column(
            children: [
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

              Container(
                padding: EdgeInsets.symmetric(
                  vertical: FigmaSize.h(50),
                  horizontal: FigmaSize.w(43),
                ),
                width: FigmaSize.screenWidth,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  color: Colors.white,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextFormField(
                        controller: _emailController,
                        hintText: "Email",
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Email is required";
                          }
                          // ✅ Basic email format check
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value.trim())) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: FigmaSize.h(16)),

                      AppTextFormField(
                        controller: _passwordController,
                        hintText: "Password",
                        obscureText: true,
                        isPassword: true,
                        suffixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return "Minimum 6 characters";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: FigmaSize.h(16)),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Forget Password?",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),

                      SizedBox(height: FigmaSize.h(16)),

                      // ✅ Show loader inside button area while logging in
                      _isLoading
                          ? const CircularProgressIndicator()
                          : AppGradientButton(
                              title: "Login",
                              onPressed: _handleLogin,
                            ),

                      SizedBox(height: FigmaSize.h(32)),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: const Color(0xFF6C7278)),
                            children: [
                              const TextSpan(text: "By Login, you agree to the "),
                              TextSpan(
                                text: "Terms of Service",
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: open terms page
                                  },
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Data Processing Agreement",
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: open DPA page
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: FigmaSize.h(23)),
                    ],
                  ),
                ),
              ),

              const DarkStatsHeader(),
            ],
          ),
        ),
      ),
    );
  }
}