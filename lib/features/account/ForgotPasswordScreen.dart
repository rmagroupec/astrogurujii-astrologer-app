import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/core/widgets/footer_widget_login.dart';
import 'package:astrologer_app/features/account/ForgotVerificationndPasswordChangeScreen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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
              height: FigmaSize.designHeight/1.5,
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

                    
                    SizedBox(height: FigmaSize.h(16)),
                    
                   
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(0)),
                      child: AppGradientButton(
                        title: "Login",

                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen()));
                        },
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(32)),
                    SizedBox(height: FigmaSize.h(23)),
                     DarkStatsHeader(color: Colors.white,),
                  ],
                ),
              ),
            ),

           
          ],
        ),
      ),
    );
  }
}
