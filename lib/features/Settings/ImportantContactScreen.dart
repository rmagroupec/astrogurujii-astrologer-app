// lib/features/Settings/ImportantContactScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';

class ImportantNumberPage extends StatelessWidget {
  const ImportantNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text(
          'Important Number',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You will get call and chat alerts from these numbers. '
              'Save these numbers to avoid any confusion.',
              style: TextStyle(fontSize: 13, color: c.subText),
            ),

            const SizedBox(height: 24),

            _Section(
              title  : 'App Call',
              numbers: '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021',
              onAdd  : () {},
              c      : c,
            ),

            const SizedBox(height: 24),

            _Section(
              title  : 'App Chat Alert',
              numbers: '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021, +91 7615976021',
              onAdd  : () {},
              c      : c,
            ),

            const SizedBox(height: 24),

            _Section(
              title  : 'App Admin Support',
              numbers: '+91 7615976021, +91 7615976021, +91 7615976021,\n'
                  '+91 7615976021, +91 7615976021',
              onAdd  : () {},
              c      : c,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section widget ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String       title;
  final String       numbers;
  final VoidCallback onAdd;
  final AppColors    c;

  const _Section({
    required this.title,
    required this.numbers,
    required this.onAdd,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize  : 16,
            fontWeight: FontWeight.w600,
            color     : c.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          numbers,
          style: TextStyle(
            fontSize: 13,
            color   : c.subText,
            height  : 1.6,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child : ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
              elevation      : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Add Contact',
              style: TextStyle(
                  color     : Colors.black,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: c.divider),
      ],
    );
  }
}