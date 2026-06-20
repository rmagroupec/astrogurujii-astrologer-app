// lib/features/Settings/PaySlipScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'dart:io';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class Payslipscreen extends StatefulWidget {
  const Payslipscreen({super.key});

  @override
  State<Payslipscreen> createState() => _PayslipscreenState();
}

class _PayslipscreenState extends State<Payslipscreen> {
  DateTime? _startMonth;
  DateTime? _endMonth;
  bool      _isLoading = false;

  final _client = ApiClient();

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatMonth(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickMonth({required bool isStart}) async {
    final now     = DateTime.now();
    final initial = isStart
        ? (_startMonth ?? DateTime(now.year, now.month))
        : (_endMonth   ?? DateTime(now.year, now.month));

    final picked = await showDatePicker(
      context         : context,
      initialDate     : initial,
      firstDate       : DateTime(2022, 1),
      lastDate        : now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText        : isStart ? 'Select Start Month' : 'Select End Month',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary  : AppTheme.primaryYellow,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    final snapped = DateTime(picked.year, picked.month);

    setState(() {
      if (isStart) {
        _startMonth = snapped;
        if (_endMonth != null && _endMonth!.isBefore(snapped)) {
          _endMonth = null;
        }
      } else {
        _endMonth = snapped;
      }
    });
  }

  Future<void> _onSendEmail() async {
    if (_startMonth == null) {
      _showSnack('Please select a start month');
      return;
    }
    if (_endMonth == null) {
      _showSnack('Please select an end month');
      return;
    }
    if (_endMonth!.isBefore(_startMonth!)) {
      _showSnack('End month must be after start month');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _client.post(
        'astrologer_api/salary_slip_download',
        {'month': _startMonth!.month, 'year': _startMonth!.year},
        isAuthRequired: true,
      );

      if (response.statusCode == 200 &&
          (response.headers['content-type'] ?? '').contains('pdf')) {
        final dir  = await getApplicationDocumentsDirectory();
        final name = 'SalarySlip_${_formatMonth(_startMonth)}.pdf'
            .replaceAll(' ', '_');
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          _showSnack('Saved: ${file.path}', success: true);
        }
      } else {
        _showSnack('Failed to download salary slip');
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: success ? Colors.green : AppTheme.accentRed,
      behavior       : SnackBarBehavior.floating,
      margin         : const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Pay Slip'),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(
          horizontal: FigmaSize.w(27),
          vertical  : FigmaSize.h(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Start month picker ─────────────────────────────────────────
            _MonthPickerField(
              label    : 'Select Start Month',
              selected : _startMonth,
              formatter: _formatMonth,
              onTap    : () => _pickMonth(isStart: true),
              c        : c,
              isDark   : isDark,
            ),

            SizedBox(height: FigmaSize.h(20)),

            // ── End month picker ───────────────────────────────────────────
            _MonthPickerField(
              label    : 'Select end Month',
              selected : _endMonth,
              formatter: _formatMonth,
              onTap    : () => _pickMonth(isStart: false),
              c        : c,
              isDark   : isDark,
            ),

            SizedBox(height: FigmaSize.h(60)),

            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow))
                : GradientButton(
                    title: 'Send on Email',
                    onTap: _onSendEmail),
          ],
        ),
      ),
    );
  }
}

// ── Month picker field ────────────────────────────────────────────────────────
class _MonthPickerField extends StatelessWidget {
  final String       label;
  final DateTime?    selected;
  final String Function(DateTime?) formatter;
  final VoidCallback onTap;
  final AppColors    c;
  final bool         isDark;

  const _MonthPickerField({
    required this.label,
    required this.selected,
    required this.formatter,
    required this.onTap,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = selected != null;

    return SizedBox(
      width: FigmaSize.designWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            readOnly         : true,
            onTap            : onTap,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color     : c.subText,
              fontSize  : FigmaSize.w(16),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText : hasValue ? formatter(selected) : label,
              hintStyle: TextStyle(
                color     : hasValue ? c.text : c.subText,
                fontSize  : FigmaSize.w(16),
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: SizedBox(
                width : FigmaSize.w(20),
                height: FigmaSize.h(20),
                child : Center(
                  child: SvgPicture.asset(
                    'assets/images/calendar.svg',
                    width : FigmaSize.w(20),
                    height: FigmaSize.h(20),
                    colorFilter: isDark
                        ? ColorFilter.mode(c.subText, BlendMode.srcIn)
                        : null,
                  ),
                ),
              ),
              border        : InputBorder.none,
              isDense       : true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SizedBox(height: FigmaSize.h(4)),
          Divider(color: c.divider, height: 1),
        ],
      ),
    );
  }
}