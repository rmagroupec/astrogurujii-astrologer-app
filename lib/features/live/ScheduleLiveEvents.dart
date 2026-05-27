import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';

class Scheduleliveevents extends StatefulWidget {
  const Scheduleliveevents({super.key});

  @override
  State<Scheduleliveevents> createState() => _ScheduleliveeventsState();
}

class _ScheduleliveeventsState extends State<Scheduleliveevents> {
  final TextEditingController _liveEventController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Schedule Events"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: FigmaSize.h(35),
          horizontal: FigmaSize.w(43),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Event Name",
                style: TextStyle(
                  fontSize: FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: FigmaSize.h(10)),
              AppTextFormField(
                verticalPadding: 10,
                controller: _liveEventController,
                hintText: "Live Events",
              ),
              SizedBox(height: FigmaSize.h(18)),
              Text(
                "Start Time",
                style: TextStyle(
                  fontSize: FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: FigmaSize.h(10)),
              AppTextFormField(
                verticalPadding: 10,
                controller: _startTimeController,
                hintText: "Please Select Start time",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(42)),
        margin: EdgeInsets.only(bottom: FigmaSize.h(44)),
        color: Colors.transparent,
        child: AppGradientButton(title: "Schedule Event", onPressed: () {}),
      ),
    );
  }
}
