import 'package:flutter/widgets.dart';

class FigmaSize {
  static late double screenWidth;
  static late double screenHeight;

  // Base Figma design size
  static const double designWidth = 412;
  static const double designHeight = 807;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    screenWidth = mq.size.width;
    screenHeight = mq.size.height;
  }

  // Width scaling
  static double w(double width) {
    return (width / designWidth) * screenWidth;
  }

  // Height scaling
  static double h(double height) {
    return (height / designHeight) * screenHeight;
  }

  // Font scaling (balanced)
  static double sp(double fontSize) {
    final scaleWidth = screenWidth / designWidth;
    final scaleHeight = screenHeight / designHeight;
    return fontSize * (scaleWidth + scaleHeight) / 2;
  }
}
