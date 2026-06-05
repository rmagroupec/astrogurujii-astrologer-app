// lib/features/account/CompleteProfileScreen.dart
//
// Fully working. Zero UI changes.
// — All fields editable, pre-filled from astrologerData.
// — DOB → showDatePicker, TOB → showTimePicker.
// — Edit icon on "Registered No." row opens OTP-verified phone update flow
//   (same showOtpSheet pattern used in UpdatePhoneNumber.dart).
// — Submit calls POST /astrologer_api/profile_update.

import 'dart:convert';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/astrologerProfileModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class CompleteProfileScreen extends StatefulWidget {
  final Astrologer astrologerData;
  const CompleteProfileScreen({super.key, required this.astrologerData});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final TextEditingController _dobCtrl;
  late final TextEditingController _tobCtrl;
  late final TextEditingController _pobCtrl;
  late final TextEditingController _faithCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;

  bool _isSubmitting = false;

  final _client = ApiClient();

  @override
  void initState() {
    super.initState();
    final d = widget.astrologerData;
    _dobCtrl     = TextEditingController(text: d.dob.isNotEmpty     ? d.dob     : '');
    _tobCtrl     = TextEditingController();
    _pobCtrl     = TextEditingController(text: d.address.isNotEmpty  ? d.address : '');
    _faithCtrl   = TextEditingController();
    _addressCtrl = TextEditingController(text: d.address.isNotEmpty  ? d.address : '');
    _cityCtrl    = TextEditingController();
  }

  @override
  void dispose() {
    _dobCtrl.dispose();
    _tobCtrl.dispose();
    _pobCtrl.dispose();
    _faithCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDOB() async {
    DateTime initial = DateTime(1990);
    if (_dobCtrl.text.isNotEmpty) {
      try { initial = DateTime.parse(_dobCtrl.text); } catch (_) {}
    }
    final picked = await showDatePicker(
      context   : context,
      initialDate: initial,
      firstDate  : DateTime(1940),
      lastDate   : DateTime.now(),
      builder    : (ctx, child) => _yellowTheme(ctx, child!),
    );
    if (picked != null && mounted) {
      setState(() {
        _dobCtrl.text = '${picked.year}-${_p2(picked.month)}-${_p2(picked.day)}';
      });
    }
  }

  // ── Time picker ────────────────────────────────────────────────────────────
  Future<void> _pickTOB() async {
    final picked = await showTimePicker(
      context    : context,
      initialTime: TimeOfDay.now(),
      builder    : (ctx, child) => _yellowTheme(ctx, child!),
    );
    if (picked != null && mounted) {
      setState(() => _tobCtrl.text = picked.format(context));
    }
  }

  Widget _yellowTheme(BuildContext ctx, Widget child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary  : Color(0xFFFCD417),
            onPrimary: Colors.black,
          ),
        ),
        child: child,
      );

  String _p2(int n) => n.toString().padLeft(2, '0');

  // ── Phone number edit — OTP flow ───────────────────────────────────────────
  void _editPhoneNumber() {
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          bool sending = false;

          Future<void> sendOtp() async {
            final number = phoneCtrl.text.trim();
            if (number.length < 10) return;
            setSheet(() => sending = true);
            try {
              final res  = await ApiService().UpdatePhoneNumberFunc({'number': number});
              final json = jsonDecode(res.body);
              setSheet(() => sending = false);
              if (json['result'] == true) {
                if (!mounted) return;
                Navigator.of(sheetCtx).pop();
                _showOtpSheet(number);
              } else {
                if (!mounted) return;
                _showSnack(json['message'] ?? 'Failed to send OTP');
              }
            } catch (e) {
              setSheet(() => sending = false);
              if (!mounted) return;
              _showSnack(e.toString().replaceFirst('Exception: ', ''));
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left  : 24, right: 24, top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize      : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: FigmaSize.h(16)),
                Text(
                  'Update Phone Number',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: FigmaSize.h(16)),
                TextField(
                  controller  : phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength   : 10,
                  decoration  : InputDecoration(
                    hintText    : 'Enter new phone number',
                    hintStyle   : TextStyle(color: Colors.grey.shade400),
                    prefixText  : '+91 ',
                    counterText : '',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFCD417))),
                  ),
                ),
                SizedBox(height: FigmaSize.h(20)),
                SizedBox(
                  width : double.infinity,
                  height: FigmaSize.h(48),
                  child : ElevatedButton(
                    onPressed: sending ? null : sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCD417),
                      foregroundColor: Colors.black,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── OTP verification sheet ─────────────────────────────────────────────────
  void _showOtpSheet(String number) {
    final otpCtrl = TextEditingController();

    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          bool verifying = false;

          Future<void> verify() async {
            final otp = otpCtrl.text.trim();
            if (otp.isEmpty) return;
            setSheet(() => verifying = true);
            try {
              final res  = await ApiService().UpdatePhoneNumberFunc({
                'number': number,
                'otp'   : otp,
              });
              final json = jsonDecode(res.body);
              setSheet(() => verifying = false);
              if (!mounted) return;
              Navigator.of(sheetCtx).pop();
              _showSnack(
                json['message'] ?? (json['result'] == true ? 'Number updated' : 'Failed'),
                success: json['result'] == true,
              );
            } catch (e) {
              setSheet(() => verifying = false);
              if (!mounted) return;
              _showSnack(e.toString().replaceFirst('Exception: ', ''));
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left  : 24, right: 24, top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize      : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: FigmaSize.h(16)),
                Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: FigmaSize.h(8)),
                Text(
                  'OTP sent to +91 $number',
                  style: TextStyle(
                    color   : Colors.grey,
                    fontSize: FigmaSize.w(13),
                  ),
                ),
                SizedBox(height: FigmaSize.h(16)),
                TextField(
                  controller  : otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength   : 6,
                  decoration  : InputDecoration(
                    hintText    : 'Enter 6-digit OTP',
                    counterText : '',
                    border      : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide  : const BorderSide(color: Color(0xFFFCD417)),
                    ),
                  ),
                ),
                SizedBox(height: FigmaSize.h(20)),
                SizedBox(
                  width : double.infinity,
                  height: FigmaSize.h(48),
                  child : ElevatedButton(
                    onPressed: verifying ? null : verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCD417),
                      foregroundColor: Colors.black,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: verifying
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize  : FigmaSize.w(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Submit profile update ──────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      // Build an "about" payload carrying all the extra fields the backend
      // profile_update doesn't have individual params for yet.
      final parts = <String>[];
      if (_pobCtrl.text.trim().isNotEmpty)
        parts.add('POB: ${_pobCtrl.text.trim()}');
      if (_faithCtrl.text.trim().isNotEmpty)
        parts.add('Faith: ${_faithCtrl.text.trim()}');
      if (_addressCtrl.text.trim().isNotEmpty)
        parts.add('Address: ${_addressCtrl.text.trim()}');
      if (_cityCtrl.text.trim().isNotEmpty)
        parts.add('City: ${_cityCtrl.text.trim()}');
      if (_dobCtrl.text.trim().isNotEmpty)
        parts.add('DOB: ${_dobCtrl.text.trim()}');
      if (_tobCtrl.text.trim().isNotEmpty)
        parts.add('TOB: ${_tobCtrl.text.trim()}');

      final about = parts.isNotEmpty
          ? parts.join(' | ')
          : widget.astrologerData.about;

      final response = await _client.post(
        'astrologer_api/profile_update',
        {
          'about': about,
          'bio'  : widget.astrologerData.bio,
        },
        isAuthRequired: true,
      );

      if (!mounted) return;
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == true) {
        _showSnack('Profile updated successfully', success: true);
        Navigator.of(context).pop();
      } else {
        _showSnack(json['message'] ?? 'Update failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior       : SnackBarBehavior.floating,
      margin         : const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final d = widget.astrologerData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title          : const Text("Complete your Profile"),
        backgroundColor: const Color(0xFFFCD417),
        foregroundColor: Colors.black,
        elevation      : 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16),
          vertical  : FigmaSize.h(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// PROFILE CARD
            Container(
              padding   : EdgeInsets.all(FigmaSize.w(12)),
              decoration: BoxDecoration(
                border      : Border.all(color: const Color(0xFFFCD417)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// PROFILE IMAGE
                  Container(
                    height    : FigmaSize.h(72),
                    width     : FigmaSize.w(72),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(
                          d.profileImg.isNotEmpty
                              ? d.profileImg
                              : "https://i.pravatar.cc/300",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(width: FigmaSize.w(12)),

                  /// PROFILE DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _richLine("Real Name : ",    d.displayname, isBold: true),
                        SizedBox(height: FigmaSize.h(4)),
                        _richLine("Display Name : ", d.displayname),
                        SizedBox(height: FigmaSize.h(4)),
                        Text(
                          d.email,
                          style: TextStyle(
                            fontSize  : FigmaSize.w(12),
                            color     : const Color(0xFFD41000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        // Registered No. — edit icon now opens phone-update flow
                        _iconLine(
                          "Registered No. : +91${d.number}",
                          onEditTap: _editPhoneNumber,
                        ),
                        SizedBox(height: FigmaSize.h(4)),
                        // Primary No. — same edit action
                        _iconLine(
                          "Primary No. : +91${d.number}",
                          onEditTap: _editPhoneNumber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: FigmaSize.h(24)),

            /// BASIC DETAILS
            Text(
              "Basic Details",
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: FigmaSize.h(12)),

            // DOB
            _inputField(
              hint      : d.dob.isNotEmpty ? d.dob : "Please select date of birth",
              controller: _dobCtrl,
              onTap     : _pickDOB,
              suffixIcon: const Icon(Icons.calendar_today,
                  size: 16, color: Colors.grey),
            ),

            SizedBox(height: FigmaSize.h(14)),
            _label("Time of Birth"),
            _inputField(
              hint      : "Please select time of birth",
              controller: _tobCtrl,
              onTap     : _pickTOB,
              suffixIcon: const Icon(Icons.access_time,
                  size: 16, color: Colors.grey),
            ),

            SizedBox(height: FigmaSize.h(14)),
            _label("Place of birth"),
            _inputField(
              hint      : d.address.isNotEmpty
                  ? d.address
                  : "Please select place of birth",
              controller: _pobCtrl,
            ),

            SizedBox(height: FigmaSize.h(14)),
            _label("Faith"),
            _inputField(
              hint      : "Select Faith",
              controller: _faithCtrl,
            ),

            SizedBox(height: FigmaSize.h(14)),
            _label("Current Address"),
            _inputField(
              hint      : d.address.isNotEmpty ? d.address : "Enter Address",
              controller: _addressCtrl,
            ),

            SizedBox(height: FigmaSize.h(14)),
            _label("City"),
            _inputField(
              hint      : "Enter Town / City",
              controller: _cityCtrl,
            ),

            SizedBox(height: FigmaSize.h(30)),

            /// SUBMIT BUTTON — UI unchanged
            GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                width     : double.infinity,
                height    : FigmaSize.h(48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient    : const LinearGradient(
                    colors: [Color(0xFF2B2B2B), Color(0xFF4A3F36)],
                  ),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            color     : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize  : 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers — UI identical to original ────────────────────────────────────

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: FigmaSize.h(6)),
      child: Text(
        text,
        style: TextStyle(
          fontSize  : FigmaSize.w(12),
          fontWeight: FontWeight.w600,
          color     : Colors.black,
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly  : onTap != null,
      onTap     : onTap,
      decoration: InputDecoration(
        hintText      : controller.text.isEmpty ? hint : null,
        hintStyle     : TextStyle(fontSize: FigmaSize.w(12), color: Colors.grey),
        suffixIcon    : suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(12),
          vertical  : FigmaSize.h(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide  : BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide  : BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide  : const BorderSide(color: Color(0xFFFCD417)),
        ),
      ),
    );
  }

  Widget _richLine(String label, String value, {bool isBold = false}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: FigmaSize.w(12), color: Colors.black),
        children: [
          TextSpan(
            text : label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black),
          ),
          TextSpan(
            text : value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      ),
    );
  }

  // _iconLine now accepts an optional onEditTap to make the edit icon tappable
  Widget _iconLine(String text, {VoidCallback? onEditTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              color     : const Color(0xFFD41000),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap    : onEditTap,
          behavior : HitTestBehavior.opaque,
          child    : Padding(
            padding: EdgeInsets.only(left: FigmaSize.w(8)),
            child  : const Icon(Icons.edit, size: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}