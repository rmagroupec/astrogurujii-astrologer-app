import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/account/LoginScreen.dart';
import 'package:astrologer_app/service/localStorageService.dart';
import 'package:flutter/material.dart';

import '../../service/notificationService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
   String? _token;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

 Future<void> _loadToken() async {
    setState(() => _isLoading = true);
    final token = NotificationService().fcmToken ?? 
                  await NotificationService().getStoredToken();
    setState(() {
      _token = token;
      print(_token);
      _isLoading = false;
    });
  }

  void _checkLoginStatus() async {
    // Wait for 2 seconds to show the logo (optional)
    await Future.delayed(Duration(seconds: 2));

    bool loggedIn = await LocalStorageService().isLoggedIn();

    if (loggedIn) {
      // User is logged in -> Go to Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else {
      // No token found -> Go to Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: FigmaSize.w(160), // match figma logo width
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
