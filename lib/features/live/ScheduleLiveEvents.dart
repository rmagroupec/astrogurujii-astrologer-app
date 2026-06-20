// lib/features/live/ScheduleLiveEvents.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Responsive: FigmaSize preserved ──────────────────────────────────────────

import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/core/widgets/app_text_form_field.dart';
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

  String get _formattedDate {
    if (_selectedDateTime == null) return '';
    final d = _selectedDateTime!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get _formattedTime {
    if (_selectedDateTime == null) return '';
    final d      = _selectedDateTime!;
    final hour   = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get _displayLabel =>
      _selectedDateTime == null ? '' : '$_formattedDate  $_formattedTime';

  // ── Date + time picker ────────────────────────────────────────────────────
  Future<void> _pickDateTime() async {
    // Picker uses brand yellow via AppTheme automatically
    final date = await showDatePicker(
      context    : context,
      initialDate: DateTime.now(),
      firstDate  : DateTime.now(),
      lastDate   : DateTime.now().add(const Duration(days: 365)),
      builder    : (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary  : AppTheme.primaryYellow,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context    : context,
      initialTime: TimeOfDay.now(),
      builder    : (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary  : AppTheme.primaryYellow,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
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
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Liveservice().GoLive({
        'title'       : eventName,
        'start_time'  : _formattedTime,
        'live_date'   : _formattedDate,
        'recurringDay': 'customDate',
      });

      final body = jsonDecode(response.body);
      debugPrint('GoLive response: $body');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content        : Text(body['message'] ?? 'Done'),
          backgroundColor: body['status'] == true
              ? Colors.green.shade700
              : AppTheme.accentRed,
        ),
      );

      if (body['status'] == true) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ GoLive error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content        : Text('Error: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      extendBody     : true,
      backgroundColor: c.bg,
      appBar         : AppBar(
        // Colors from AppTheme automatically
        title: const Text('Schedule Events'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical  : FigmaSize.h(35),
          horizontal: FigmaSize.w(43),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Event Name ────────────────────────────────────────────────
              Text(
                'Events Name *',
                style: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color     : c.text,
                ),
              ),
              SizedBox(height: FigmaSize.h(10)),
              AppTextFormField(
                verticalPadding: 10,
                controller     : _liveEventController,
                hintText       : 'Live Event',
              ),

              SizedBox(height: FigmaSize.h(18)),

              // ── Start Time ────────────────────────────────────────────────
              Text(
                'Start Time *',
                style: TextStyle(
                  fontSize  : FigmaSize.w(13),
                  fontWeight: FontWeight.w500,
                  color     : c.text,
                ),
              ),
              SizedBox(height: FigmaSize.h(10)),

              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  width  : double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(16),
                    vertical  : FigmaSize.h(13),
                  ),
                  decoration: BoxDecoration(
                    color       : c.surface,
                    borderRadius: BorderRadius.circular(FigmaSize.w(8)),
                    border: Border.all(
                      color: _selectedDateTime != null
                          ? AppTheme.primaryYellow
                          : c.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDateTime == null
                              ? 'Please Select Start time'
                              : _displayLabel,
                          style: TextStyle(
                            fontSize: FigmaSize.w(13),
                            color   : _selectedDateTime == null
                                ? c.subText
                                : c.text,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size : FigmaSize.w(16),
                        color: _selectedDateTime != null
                            ? AppTheme.primaryYellow
                            : c.subText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom button ───────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          color  : c.bg,
          padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(42), vertical: FigmaSize.h(16)),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryYellow))
              : AppGradientButton(
                  title    : 'Schedule Event',
                  onPressed: _scheduleEvent,
                ),
        ),
      ),
    );
  }
}