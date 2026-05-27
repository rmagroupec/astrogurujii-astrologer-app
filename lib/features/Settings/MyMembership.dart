import 'package:flutter/material.dart';

class Mymembership extends StatefulWidget {
  const Mymembership({super.key});

  @override
  State<Mymembership> createState() => _MymembershipState();
}

class _MymembershipState extends State<Mymembership> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Text("My Membership"),
      backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
      foregroundColor: Colors.black,
    ),
    body: Center(
      child: Text("No Data Available"),
    ));
  }
} 