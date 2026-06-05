import 'dart:io';
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
  // ── State ──────────────────────────────────────────────────────────────────
  DateTime? _startMonth;
  DateTime? _endMonth;
  bool _isLoading = false;

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
    final now = DateTime.now();
    final initial = isStart
        ? (_startMonth ?? DateTime(now.year, now.month))
        : (_endMonth   ?? DateTime(now.year, now.month));

    // Show a year-month picker using showDatePicker but day-locked to 1
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2022, 1),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: isStart ? 'Select Start Month' : 'Select End Month',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFCD417),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    // Snap to first day of picked month
    final snapped = DateTime(picked.year, picked.month);

    setState(() {
      if (isStart) {
        _startMonth = snapped;
        // Reset end if it's before start
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
      // Download PDF for the start month (single-month slip)
      // If you want multi-month, call the API in a loop
      final response = await _client.post(
        'astrologer_api/salary_slip_download',
        {
          'month': _startMonth!.month,
          'year':  _startMonth!.year,
        },
        isAuthRequired: true,
      );

      if (response.statusCode == 200 &&
          (response.headers['content-type'] ?? '').contains('pdf')) {
        // Save PDF to device
        final dir  = await getApplicationDocumentsDirectory();
        final name = 'SalarySlip_${_formatMonth(_startMonth)}.pdf'
            .replaceAll(' ', '_');
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(response.bodyBytes);

        // Open PDF
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Pay Slip"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(
          horizontal: FigmaSize.w(27),
          vertical: FigmaSize.h(11),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: FigmaSize.designWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    readOnly: true,
                    onTap: () => _pickMonth(isStart: true),
                    keyboardType: TextInputType.phone,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: const Color(0xFF838383),
                      fontSize: FigmaSize.w(16),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: _startMonth != null
                          ? _formatMonth(_startMonth)
                          : "Select Start Month",
                      hintStyle: TextStyle(
                        color: _startMonth != null
                            ? Colors.black87
                            : const Color(0xFF838383),
                        fontSize: FigmaSize.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: SizedBox(
                        width: FigmaSize.w(20),
                        height: FigmaSize.h(20),
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/images/calendar.svg",
                            width: FigmaSize.w(20),
                            height: FigmaSize.h(20),
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(4)),
                  Divider(
                    color: const Color(0xFF000000).withOpacity(0.06),
                    height: 1,
                  ),
                ],
              ),
            ),
            SizedBox(height: FigmaSize.h(20)),
            SizedBox(
              width: FigmaSize.designWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    readOnly: true,
                    onTap: () => _pickMonth(isStart: false),
                    keyboardType: TextInputType.phone,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: const Color(0xFF838383),
                      fontSize: FigmaSize.w(16),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: _endMonth != null
                          ? _formatMonth(_endMonth)
                          : "Select end Month",
                      hintStyle: TextStyle(
                        color: _endMonth != null
                            ? Colors.black87
                            : const Color(0xFF838383),
                        fontSize: FigmaSize.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: SizedBox(
                        width: FigmaSize.w(20),
                        height: FigmaSize.h(20),
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/images/calendar.svg",
                            width: FigmaSize.w(20),
                            height: FigmaSize.h(20),
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(4)),
                  Divider(
                    color: const Color(0xFF000000).withOpacity(0.06),
                    height: 1,
                  ),
                ],
              ),
            ),
            SizedBox(height: FigmaSize.h(60)),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFCD417),
                    ),
                  )
                : GradientButton(title: "Send on Email", onTap: _onSendEmail),
          ],
        ),
      ),
    );
  }
}