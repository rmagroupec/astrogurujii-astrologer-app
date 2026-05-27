import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/components/SettingsGridComponent.dart';
import 'package:flutter/material.dart';

class Mainsettingscreen extends StatelessWidget {
  const Mainsettingscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Settings"),backgroundColor: Color(0xFFFCD417).withOpacity(0.25),),

      body: Container(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(18), horizontal: FigmaSize.w(20)),
        child: SettingsIconGrid(),

      ),
    );
  }
}