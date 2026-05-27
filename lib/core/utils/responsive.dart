import 'package:flutter/widgets.dart';

class Responsive {
  static late double width;
  static late double height;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    width = mq.size.width;
    height = mq.size.height;
  }

  static bool get isMobile => width < 600;
  static bool get isTablet => width >= 600 && width < 1024;
  static bool get isDesktop => width >= 1024;
}
