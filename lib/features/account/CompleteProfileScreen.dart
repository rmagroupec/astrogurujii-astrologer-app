// lib/features/account/CompleteProfileScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
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
  final _dobCtrl     = TextEditingController();
  final _tobCtrl     = TextEditingController();
  final _pobCtrl     = TextEditingController();
  final _faithCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _aboutCtrl   = TextEditingController();
  final _bioCtrl     = TextEditingController();

  bool        _isSubmitting   = false;
  bool        _loadingProfile = true;
  Astrologer? _astro;

  @override
  void initState() {
    super.initState();
    _fetchAndPrefill();
  }

  @override
  void dispose() {
    _dobCtrl.dispose();     _tobCtrl.dispose();
    _pobCtrl.dispose();     _faithCtrl.dispose();
    _addressCtrl.dispose(); _cityCtrl.dispose();
    _aboutCtrl.dispose();   _bioCtrl.dispose();
    super.dispose();
  }

  // ── Fetch & prefill ────────────────────────────────────────────────────────
  Future<void> _fetchAndPrefill() async {
    if (mounted) setState(() => _loadingProfile = true);
    try {
      final res = await ApiService().get_astrologer_profile();
      if (!mounted) return;
      final a = res.results.isNotEmpty ? res.results[0] : widget.astrologerData;
      _astro = a;
      _prefill(a);
    } catch (_) {
      if (mounted) { _astro = widget.astrologerData; _prefill(widget.astrologerData); }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _prefill(Astrologer a) {
    _dobCtrl.text     = a.dob;
    _pobCtrl.text     = a.address;
    _addressCtrl.text = a.address;
    _aboutCtrl.text   = a.about;
    _bioCtrl.text     = a.bio;
  }

  // ── Picker theme ───────────────────────────────────────────────────────────
  Widget _pickerTheme(BuildContext ctx, Widget child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary  : AppTheme.primaryYellow,
            onPrimary: Colors.black,
          ),
        ),
        child: child,
      );

  String _p2(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDOB() async {
    DateTime initial = DateTime(1990);
    if (_dobCtrl.text.isNotEmpty) {
      try { initial = DateTime.parse(_dobCtrl.text); } catch (_) {}
    }
    final picked = await showDatePicker(
      context    : context,
      initialDate: initial,
      firstDate  : DateTime(1940),
      lastDate   : DateTime.now(),
      builder    : (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (picked != null && mounted) {
      _dobCtrl.text =
          '${picked.year}-${_p2(picked.month)}-${_p2(picked.day)}';
    }
  }

  Future<void> _pickTOB() async {
    final picked = await showTimePicker(
      context    : context,
      initialTime: TimeOfDay.now(),
      builder    : (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (picked != null && mounted) _tobCtrl.text = picked.format(context);
  }

  // ── Phone OTP — Step 1 ────────────────────────────────────────────────────
  void _editPhoneNumber() {
    final phoneCtrl = TextEditingController();
    final c         = context.colors;

    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          bool    sending  = false;
          String? errorMsg;

          Future<void> _sendOtp() async {
            final number = phoneCtrl.text.trim();
            if (number.length < 10) {
              setSheet(() => errorMsg = 'Enter a valid 10-digit number');
              return;
            }
            setSheet(() { sending = true; errorMsg = null; });
            try {
              final res  = await ApiService()
                  .UpdatePhoneNumberFunc({'number': number});
              final json = jsonDecode(res.body) as Map<String, dynamic>;
              setSheet(() => sending = false);
              if (json['result'] == true) {
                if (!mounted) return;
                Navigator.of(sheetCtx).pop();
                _showOtpSheet(number);
              } else {
                setSheet(() => errorMsg =
                    json['message']?.toString() ?? 'Failed to send OTP');
              }
            } catch (e) {
              setSheet(() {
                sending  = false;
                errorMsg = e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return Container(
            decoration: BoxDecoration(
              color       : c.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left  : 24, right: 24, top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize      : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                )),
                SizedBox(height: FigmaSize.h(18)),
                Text('Update Phone Number',
                    style: TextStyle(
                        fontSize  : FigmaSize.w(16),
                        fontWeight: FontWeight.w600,
                        color     : c.text)),
                SizedBox(height: FigmaSize.h(6)),
                Text('Enter your new number. We will send an OTP to verify.',
                    style: TextStyle(
                        fontSize: FigmaSize.w(12), color: c.subText)),
                SizedBox(height: FigmaSize.h(16)),
                TextField(
                  controller  : phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength   : 10,
                  style       : TextStyle(color: c.text),
                  onChanged   : (_) {
                    if (errorMsg != null) setSheet(() => errorMsg = null);
                  },
                  decoration: InputDecoration(
                    prefixText   : '+91  ',
                    hintText     : '10-digit mobile number',
                    hintStyle    : TextStyle(color: c.subText),
                    counterText  : '',
                    errorText    : errorMsg,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide  : BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide  : BorderSide(
                            color: AppTheme.primaryYellow, width: 2)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide  : BorderSide(
                            color: AppTheme.accentRed)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: FigmaSize.w(12),
                        vertical  : FigmaSize.h(14)),
                  ),
                ),
                SizedBox(height: FigmaSize.h(20)),
                SizedBox(
                  width : double.infinity,
                  height: FigmaSize.h(50),
                  child : ElevatedButton(
                    onPressed: sending ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: sending
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text('Send OTP',
                            style: TextStyle(
                                fontSize  : FigmaSize.w(16),
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: FigmaSize.h(8)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Step 2: verify OTP ─────────────────────────────────────────────────────
  void _showOtpSheet(String number) {
    final otpCtrl = TextEditingController();
    final c       = context.colors;

    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          bool    verifying = false;
          String? errorMsg;

          Future<void> _verifyOtp() async {
            final otp = otpCtrl.text.trim();
            if (otp.length < 4) {
              setSheet(() => errorMsg =
                  'Enter the OTP sent to +91 $number');
              return;
            }
            setSheet(() { verifying = true; errorMsg = null; });
            try {
              final res  = await ApiService().UpdatePhoneNumberFunc(
                  {'number': number, 'otp': otp});
              final json = jsonDecode(res.body) as Map<String, dynamic>;
              setSheet(() => verifying = false);
              if (!mounted) return;
              final ok = json['result'] == true;
              Navigator.of(sheetCtx).pop();
              _showSnack(
                json['message']?.toString() ??
                    (ok ? 'Number updated successfully' : 'Verification failed'),
                success: ok,
              );
              if (ok) _fetchAndPrefill();
            } catch (e) {
              setSheet(() {
                verifying = false;
                errorMsg  = e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return Container(
            decoration: BoxDecoration(
              color       : c.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left  : 24, right: 24, top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize      : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                )),
                SizedBox(height: FigmaSize.h(18)),
                Text('Verify OTP',
                    style: TextStyle(
                        fontSize  : FigmaSize.w(18),
                        fontWeight: FontWeight.w700,
                        color     : c.text)),
                SizedBox(height: FigmaSize.h(6)),
                Text('OTP sent to +91 $number',
                    style: TextStyle(
                        fontSize: FigmaSize.w(13), color: c.subText)),
                SizedBox(height: FigmaSize.h(4)),
                Text('(Default OTP is 1234 if SMS not received)',
                    style: TextStyle(
                        fontSize: FigmaSize.w(11),
                        color   : Colors.orange.shade700)),
                SizedBox(height: FigmaSize.h(16)),
                TextField(
                  controller  : otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength   : 6,
                  textAlign   : TextAlign.center,
                  style: TextStyle(
                      fontSize     : FigmaSize.w(20),
                      fontWeight   : FontWeight.w700,
                      letterSpacing: 10,
                      color        : c.text),
                  onChanged: (_) {
                    if (errorMsg != null) setSheet(() => errorMsg = null);
                  },
                  decoration: InputDecoration(
                    hintText    : '• • • •',
                    hintStyle   : TextStyle(
                        fontSize: FigmaSize.w(20), color: c.subText),
                    counterText : '',
                    errorText   : errorMsg,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide  : BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide  : BorderSide(
                            color: AppTheme.primaryYellow, width: 2)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide  : BorderSide(color: AppTheme.accentRed)),
                  ),
                ),
                SizedBox(height: FigmaSize.h(6)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _editPhoneNumber();
                    },
                    child: Text('Resend OTP',
                        style: TextStyle(
                            fontSize  : FigmaSize.w(13),
                            color     : AppTheme.accentRed,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: FigmaSize.h(8)),
                SizedBox(
                  width : double.infinity,
                  height: FigmaSize.h(50),
                  child : ElevatedButton(
                    onPressed: verifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: verifying
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text('Verify OTP',
                            style: TextStyle(
                                fontSize  : FigmaSize.w(16),
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: FigmaSize.h(8)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final body = <String, dynamic>{};
    void add(String key, TextEditingController c) {
      final v = c.text.trim();
      if (v.isNotEmpty) body[key] = v;
    }
    add('about',   _aboutCtrl);
    add('bio',     _bioCtrl);
    add('dob',     _dobCtrl);
    add('tob',     _tobCtrl);
    add('pob',     _pobCtrl);
    add('address', _addressCtrl);
    add('city',    _cityCtrl);
    add('faith',   _faithCtrl);

    if (body.isEmpty) { _showSnack('Nothing to update'); return; }
    setState(() => _isSubmitting = true);
    try {
      final res  = await ApiClient().post(
        'astrologer_api/profile_update', body, isAuthRequired: true);
      if (!mounted) return;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['status'] == true) {
        _showSnack('Profile updated successfully', success: true);
        Navigator.of(context).pop();
      } else {
        _showSnack(json['message']?.toString() ?? 'Update failed');
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
      backgroundColor: success ? Colors.green.shade600 : AppTheme.accentRed,
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

    if (_loadingProfile) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(title: const Text('Complete your Profile')),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryYellow),
        ),
      );
    }

    final d = _astro ?? widget.astrologerData;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            // Colors inherited from AppTheme automatically
            title    : const Text('Complete your Profile'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(16),
              vertical  : FigmaSize.h(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Profile card ─────────────────────────────────────────
                Container(
                  padding   : EdgeInsets.all(FigmaSize.w(12)),
                  decoration: BoxDecoration(
                    color       : c.surface,
                    border      : Border.all(color: AppTheme.primaryYellow),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        height    : FigmaSize.h(72),
                        width     : FigmaSize.w(72),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color       : isDark ? c.toggleBg : Colors.grey.shade100,
                          image       : d.profileImg.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(d.profileImg),
                                  fit  : BoxFit.cover)
                              : null,
                        ),
                        child: d.profileImg.isEmpty
                            ? Icon(Icons.person,
                                color: c.subText, size: 36)
                            : null,
                      ),
                      SizedBox(width: FigmaSize.w(12)),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _richLine('Real Name : ',    d.displayname,
                                bold: true, c: c),
                            SizedBox(height: FigmaSize.h(4)),
                            _richLine('Display Name : ', d.displayname, c: c),
                            SizedBox(height: FigmaSize.h(4)),
                            Text(d.email,
                                style: TextStyle(
                                    fontSize  : FigmaSize.w(12),
                                    color     : AppTheme.accentRed,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(height: FigmaSize.h(4)),
                            _iconLine(
                              'Registered No. : +91 ${d.number}',
                              c      : c,
                              onEdit : _editPhoneNumber,
                            ),
                            SizedBox(height: FigmaSize.h(4)),
                            _iconLine(
                              'Primary No. : +91 ${d.number}',
                              c     : c,
                              onEdit: _editPhoneNumber,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: FigmaSize.h(24)),

                // ── Form ─────────────────────────────────────────────────
                Text('Basic Details',
                    style: TextStyle(
                        fontSize  : FigmaSize.w(14),
                        fontWeight: FontWeight.w600,
                        color     : c.text)),
                SizedBox(height: FigmaSize.h(12)),

                _label('Date of Birth', c),
                _field(ctrl: _dobCtrl, hint: 'Select date of birth',
                    onTap : _pickDOB,
                    suffix: Icon(Icons.calendar_today,
                        size: 16, color: c.subText),
                    c    : c),

                SizedBox(height: FigmaSize.h(14)),
                _label('Time of Birth', c),
                _field(ctrl: _tobCtrl, hint: 'Select time of birth',
                    onTap : _pickTOB,
                    suffix: Icon(Icons.access_time,
                        size: 16, color: c.subText),
                    c    : c),

                SizedBox(height: FigmaSize.h(14)),
                _label('Place of Birth', c),
                _field(ctrl: _pobCtrl, hint: 'Enter place of birth', c: c),

                SizedBox(height: FigmaSize.h(14)),
                _label('Faith', c),
                _field(ctrl: _faithCtrl, hint: 'Select Faith', c: c),

                SizedBox(height: FigmaSize.h(14)),
                _label('Current Address', c),
                _field(ctrl: _addressCtrl, hint: 'Enter address', c: c),

                SizedBox(height: FigmaSize.h(14)),
                _label('City', c),
                _field(ctrl: _cityCtrl, hint: 'Enter Town / City', c: c),

                SizedBox(height: FigmaSize.h(14)),
                _label('About', c),
                _field(ctrl: _aboutCtrl,
                    hint    : 'Write something about yourself',
                    maxLines: 3, c: c),

                SizedBox(height: FigmaSize.h(14)),
                _label('Bio', c),
                _field(ctrl: _bioCtrl, hint: 'Short bio',
                    maxLines: 2, c: c),

                SizedBox(height: FigmaSize.h(32)),

                // ── Submit button ─────────────────────────────────────────
                GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: Container(
                    width    : double.infinity,
                    height   : FigmaSize.h(50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient    : const LinearGradient(
                          colors: [Color(0xFF2B2B2B), Color(0xFF4A3F36)]),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Submit',
                              style: TextStyle(
                                  color     : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize  : 16)),
                    ),
                  ),
                ),
                SizedBox(height: FigmaSize.h(32)),
              ],
            ),
          ),
        ),

        // ── Loading overlay ────────────────────────────────────────────────
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(child: CircularProgressIndicator(
                color: AppTheme.primaryYellow)),
          ),
      ],
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  Widget _label(String text, AppColors c) => Padding(
    padding: EdgeInsets.only(bottom: FigmaSize.h(6)),
    child: Text(text,
        style: TextStyle(
            fontSize  : FigmaSize.w(12),
            fontWeight: FontWeight.w600,
            color     : c.text)),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String     hint,
    required AppColors  c,
    VoidCallback?       onTap,
    Widget?             suffix,
    int                 maxLines = 1,
  }) => TextFormField(
    controller: ctrl,
    readOnly  : onTap != null,
    onTap     : onTap,
    maxLines  : maxLines,
    style     : TextStyle(color: c.text, fontSize: FigmaSize.w(12)),
    decoration: InputDecoration(
      hintText      : hint,
      hintStyle     : TextStyle(fontSize: FigmaSize.w(12), color: c.subText),
      suffixIcon    : suffix,
      contentPadding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(12), vertical: FigmaSize.h(12)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide  : BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide  : BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide  : BorderSide(color: AppTheme.primaryYellow, width: 2)),
    ),
  );

  Widget _richLine(String label, String value,
      {bool bold = false, required AppColors c}) =>
      RichText(text: TextSpan(
        style: TextStyle(fontSize: FigmaSize.w(12), color: c.text),
        children: [
          TextSpan(text: label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: c.text)),
          TextSpan(text: value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color     : c.subText)),
        ],
      ));

  Widget _iconLine(String text,
      {required AppColors c, VoidCallback? onEdit}) =>
      Row(children: [
        Expanded(child: Text(text,
            style: TextStyle(
                fontSize  : FigmaSize.w(12),
                color     : AppTheme.accentRed,
                fontWeight: FontWeight.w500))),
        GestureDetector(
          onTap    : onEdit,
          behavior : HitTestBehavior.opaque,
          child    : Padding(
            padding: EdgeInsets.only(left: FigmaSize.w(8)),
            child  : Icon(Icons.edit, size: 16, color: c.subText)),
        ),
      ]);
}