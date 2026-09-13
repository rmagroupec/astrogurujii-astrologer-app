import 'dart:convert';
import 'dart:io';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ChangeBankDetailsScreen extends StatefulWidget {
  const ChangeBankDetailsScreen({super.key});

  @override
  State<ChangeBankDetailsScreen> createState() =>
      _ChangeBankDetailsScreenState();
}

class _ChangeBankDetailsScreenState extends State<ChangeBankDetailsScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _accountNoCtrl       = TextEditingController();
  final _reAccountNoCtrl     = TextEditingController();
  final _bankNameCtrl        = TextEditingController();
  final _accountHolderCtrl   = TextEditingController();
  final _ifscCtrl            = TextEditingController();

  File? _proofFile;
  bool  _isLoading = false;

  final _storage = const FlutterSecureStorage();
  final _picker  = ImagePicker();

  static const String _baseUrl = 'https://admin.vaidikguru.com/';

  @override
  void dispose() {
    _accountNoCtrl.dispose();
    _reAccountNoCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  // ── Image picker bottom sheet ──────────────────────────────────────────────
  Future<void> _pickFile() async {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: c.text),
              title: Text('Take Photo', style: TextStyle(color: c.text)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null) setState(() => _proofFile = File(picked.path));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: c.text),
              title: Text('Choose from Gallery', style: TextStyle(color: c.text)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (picked != null) setState(() => _proofFile = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit via multipart ───────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_accountNoCtrl.text.trim().isEmpty) {
      _showSnack('Please enter account number'); return;
    }
    if (_accountNoCtrl.text.trim() != _reAccountNoCtrl.text.trim()) {
      _showSnack('Account numbers do not match'); return;
    }
    if (_bankNameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter bank name'); return;
    }
    if (_accountHolderCtrl.text.trim().isEmpty) {
      _showSnack('Please enter account holder name'); return;
    }
    if (_ifscCtrl.text.trim().isEmpty) {
      _showSnack('Please enter IFSC code'); return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'auth_token');

      final uri     = Uri.parse('${_baseUrl}astrologer_api/bank_acc_request');
      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['account_type']        = 'Savings';
      request.fields['account_holder_name'] = _accountHolderCtrl.text.trim();
      request.fields['account_no']          = _accountNoCtrl.text.trim();
      request.fields['bank']                = _bankNameCtrl.text.trim();
      request.fields['ifsc']                = _ifscCtrl.text.trim().toUpperCase();

      if (_proofFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'proof_image',
          _proofFile!.path,
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final json     = jsonDecode(response.body);

      if (response.statusCode == 200 && json['result'] == true) {
        _showSnack('Request submitted successfully', success: true);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(json['message'] ?? 'Submission failed');
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
        backgroundColor: success ? Colors.green : AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
        title: const Text("Enter Bank Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textField("Enter Account Number *",
                controller: _accountNoCtrl,
                c: c,
                keyboardType: TextInputType.number),
            _textField("Re-enter Account Number *",
                controller: _reAccountNoCtrl,
                c: c,
                keyboardType: TextInputType.number),
            _textField("Enter Bank Name *",
                controller: _bankNameCtrl,
                c: c),
            _textField("Account Holder Name *",
                controller: _accountHolderCtrl,
                c: c),
            _textField("Enter IFSC Code *",
                controller: _ifscCtrl,
                c: c,
                textCapitalization: TextCapitalization.characters),

            const SizedBox(height: 24),

            Text(
              "Bank Account proof (Cancel Cheque / Pass Book) *",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.text),
            ),

            const SizedBox(height: 12),

            // ── Proof image picker box ──────────────────────────────────────
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _proofFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(_proofFile!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _proofFile = null),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRed,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: OutlinedButton(
                          onPressed: _pickFile,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.accentRed),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: Text(
                            "Choose File",
                            style: TextStyle(color: AppTheme.accentRed),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String hint, {
    required AppColors c,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: TextStyle(color: c.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.subText),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: c.text),
          ),
        ),
      ),
    );
  }
}