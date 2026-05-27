import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/core/widgets/footer_widget_login.dart';
import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/Settings/MainSettingScreen.dart';
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
  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        height: FigmaSize.screenHeight,
        width: FigmaSize.screenWidth,
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
              decoration: BoxDecoration(
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
                      controller: emailController,
                      hintText: "Email",
                      keyboardType: TextInputType.emailAddress,
                      // prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is required";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: FigmaSize.h(16)),

                    AppTextFormField(
                      controller: passwordController,
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
                          selectionColor: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(16)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(0)),
                      child: AppGradientButton(
                        title: "Login",

                        onPressed: () async {
                          try {
                            if (_formKey.currentState!.validate() == false) {
                              return;
                            }
                            var response = await ApiService().login(
                              emailController.text,
                              passwordController.text,
                            );
                              print
                              ("Response Status: ${response.body}");
                            if (response.statusCode == 200) {
                              // Correctly decode the body now that the type isn't void
                              var data = jsonDecode(response.body);
                              if (data['status'] == true) {
                                // ✅ Store data locally
                                await LocalStorageService().saveLoginData(data);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            } else {
                              print(
                                "Login failed with status: ${response.statusCode}",
                              );
                            }
                          } catch (e) {
                            // Handle network or parsing exceptions
                            print("An error occurred: $e");
                          }
                          // if (success) {
                          //   Navigator.pushReplacement(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => HomeScreen(),
                          //     ),
                          //   );
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     SnackBar(content: Text("Login failed")),
                          //   );
                          // }
                        },
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(32)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(10),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6C7278)),
                          children: [
                            const TextSpan(text: "By Login, you agree to the "),
                            TextSpan(
                              text: "Terms of Service",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // open terms page
                                },
                            ),
                            const TextSpan(text: " and "),
                            TextSpan(
                              text: "Data Processing Agreement",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // open DPA page
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

            DarkStatsHeader(),
          ],
        ),
      ),
    );
  }
}
