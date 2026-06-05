import 'dart:convert';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:flutter/material.dart';

class Scheduleliveevents extends StatefulWidget {
  const Scheduleliveevents({super.key});

  @override
  State<Scheduleliveevents> createState() => _ScheduleliveeventsState();
}

class _ScheduleliveeventsState extends State<Scheduleliveevents> {
  final TextEditingController _liveEventController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _liveEventController.dispose();
    super.dispose();
  }

  // ── Date formatted as YYYY-MM-DD (backend uses .split('T')[0]) ──
  String get _formattedDate {
    if (_selectedDateTime == null) return '';
    final d = _selectedDateTime!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ── Time formatted as HH:MM AM/PM ──
  String get _formattedTime {
    if (_selectedDateTime == null) return '';
    final d = _selectedDateTime!;
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ── Display label shown in the tappable field ──
  String get _displayLabel {
    if (_selectedDateTime == null) return '';
    return '$_formattedDate  $_formattedTime';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _scheduleEvent() async {
    final eventName = _liveEventController.text.trim();

    if (eventName.isEmpty || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Liveservice().GoLive({
        "title": eventName,           // ✅ field name the backend Live model stores
        "start_time": _formattedTime, // ✅ "start_time" used by live_list filter
        "live_date": _formattedDate,  // ✅ "live_date" used by live_list filter
        "recurringDay": "customDate", // ✅ required so live_list picks it up
      });

      final body = jsonDecode(response.body);
      print("GoLive response: $body");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['message'] ?? "Done")),
      );

      if (body['status'] == true) Navigator.pop(context);
    } catch (e) {
      print("❌ GoLive error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Schedule Events"),
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
              // ── Event Name ──────────────────────────────
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

              // ── Start Time ──────────────────────────────
              Text(
                "Start Time",
                style: TextStyle(
                  fontSize: FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: FigmaSize.h(10)),

              // Tappable field — same visual as AppTextFormField
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(24),
                    vertical: FigmaSize.h(10),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FigmaSize.w(5)),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDateTime == null
                              ? "Please Select Start time"
                              : _displayLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _selectedDateTime == null
                                ? Colors.grey.shade500
                                : Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: FigmaSize.w(16),
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(42)),
        margin: EdgeInsets.only(bottom: FigmaSize.h(44)),
        color: Colors.transparent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AppGradientButton(
                title: "Schedule Event",
                onPressed: _scheduleEvent,
              ),
      ),
    );
  }
}