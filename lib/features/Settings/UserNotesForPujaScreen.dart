import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class Usernotesforpujascreen extends StatefulWidget {
  const Usernotesforpujascreen({super.key});

  @override
  State<Usernotesforpujascreen> createState() => _UsernotesforpujascreenState();
}

class _UsernotesforpujascreenState extends State<Usernotesforpujascreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("User Notes"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: FigmaSize.h(15),
          horizontal: FigmaSize.w(20),
        ),
      ),
    );
  }
}
