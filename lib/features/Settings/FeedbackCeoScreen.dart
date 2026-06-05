// lib/features/Settings/FeedbackCeoScreen.dart

import 'dart:convert';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

class FeedbackCeoScreen extends StatefulWidget {
  const FeedbackCeoScreen({super.key});

  @override
  State<FeedbackCeoScreen> createState() => _FeedbackCeoScreenState();
}

class _FeedbackCeoScreenState extends State<FeedbackCeoScreen> {
  final _msgCtrl  = TextEditingController();
  final _client   = ApiClient();
  bool  _sending  = false;
  bool  _sent     = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content        : Text('Please write your feedback'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _sending = true);
    try {
      final res  = await _client.post(
        'astrologer_api/feedback_ceo',
        {'message': msg},
        isAuthRequired: true,
      );
      final json = jsonDecode(res.body);
      if (!mounted) return;

      if (res.statusCode == 200 && json['result'] == true) {
        setState(() { _sent = true; _sending = false; });
        _msgCtrl.clear();
      } else {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content        : Text(json['message'] ?? 'Submission failed'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content        : Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title          : const Text('Feedback to CEO Office'),
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        elevation      : 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(24),
          vertical  : FigmaSize.h(24),
        ),
        child: _sent ? _successView() : _formView(),
      ),
    );
  }

  // ── Success view ─────────────────────────────────────────────────────────
  Widget _successView() {
    return Column(
      children: [
        SizedBox(height: FigmaSize.h(60)),
        const Icon(Icons.check_circle_outline,
            color: Colors.green, size: 80),
        SizedBox(height: FigmaSize.h(20)),
        Text(
          'Thank you!',
          style: TextStyle(
            fontSize  : FigmaSize.w(22),
            fontWeight: FontWeight.w700,
            color     : Colors.black,
          ),
        ),
        SizedBox(height: FigmaSize.h(10)),
        Text(
          'Your feedback has been submitted to the CEO office.\n'
          'We value your thoughts and will review them carefully.',
          textAlign: TextAlign.center,
          style    : TextStyle(
              fontSize: FigmaSize.w(14), color: Colors.grey.shade600),
        ),
        SizedBox(height: FigmaSize.h(40)),
        SizedBox(
          width : double.infinity,
          height: FigmaSize.h(50),
          child : ElevatedButton(
            onPressed: () => setState(() => _sent = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCD417),
              foregroundColor: Colors.black,
              elevation      : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit Another',
              style: TextStyle(
                  fontSize: FigmaSize.w(15), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form view ─────────────────────────────────────────────────────────────
  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        Container(
          width     : double.infinity,
          padding   : EdgeInsets.all(FigmaSize.w(16)),
          decoration: BoxDecoration(
            color       : const Color(0xFFFFFBE6),
            border      : Border.all(color: const Color(0xFFFCD417)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_center,
                      color: Color(0xFFF5A623), size: 22),
                  SizedBox(width: FigmaSize.w(8)),
                  Text(
                    'Direct to CEO',
                    style: TextStyle(
                      fontSize  : FigmaSize.w(15),
                      fontWeight: FontWeight.w700,
                      color     : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: FigmaSize.h(8)),
              Text(
                'Your feedback goes directly to the CEO office. '
                'Share suggestions, concerns, or ideas openly. '
                'All submissions are confidential.',
                style: TextStyle(
                    fontSize: FigmaSize.w(12),
                    color   : Colors.grey.shade700),
              ),
            ],
          ),
        ),

        SizedBox(height: FigmaSize.h(24)),

        Text(
          'Your Message',
          style: TextStyle(
            fontSize  : FigmaSize.w(13),
            fontWeight: FontWeight.w600,
            color     : Colors.black,
          ),
        ),
        SizedBox(height: FigmaSize.h(8)),

        // Message field
        TextField(
          controller    : _msgCtrl,
          maxLines      : 8,
          maxLength     : 1000,
          textInputAction: TextInputAction.newline,
          decoration    : InputDecoration(
            hintText      : 'Write your feedback, suggestion or concern...',
            hintStyle     : TextStyle(
                color: Colors.grey.shade400, fontSize: FigmaSize.w(13)),
            border        : OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide  : BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder : OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide  : BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder : OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide  : const BorderSide(color: Color(0xFFFCD417), width: 1.5),
            ),
            contentPadding: EdgeInsets.all(FigmaSize.w(14)),
          ),
        ),

        SizedBox(height: FigmaSize.h(8)),
        Text(
          '* Your feedback is anonymous and goes directly to leadership.',
          style: TextStyle(
              fontSize: FigmaSize.w(11), color: Colors.grey.shade500),
        ),

        SizedBox(height: FigmaSize.h(32)),

        // Submit button
        SizedBox(
          width : double.infinity,
          height: FigmaSize.h(52),
          child : ElevatedButton(
            onPressed: _sending ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCD417),
              foregroundColor: Colors.black,
              elevation      : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _sending
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    'Submit Feedback',
                    style: TextStyle(
                      fontSize  : FigmaSize.w(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}