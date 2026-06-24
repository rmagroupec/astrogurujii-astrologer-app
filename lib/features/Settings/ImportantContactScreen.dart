// lib/features/Settings/ImportantContactScreen.dart

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportantNumberPage extends StatelessWidget {
  const ImportantNumberPage({super.key});

  // ── Contact data ────────────────────────────────────────────────────────────
  static const _sections = [
    _ContactSection(
      title  : 'App Call',
      numbers: [
        '7615976021', '7615976022', '7615976023',
        '7615976024', '7615976025', '7615976026',
        '7615976027', '7615976028', '7615976029',
        '7615976030', '7615976031', '7615976032',
        '7615976033', '7615976034', '7615976035',
      ],
    ),
    _ContactSection(
      title  : 'App Chat Alert',
      numbers: [
        '7615976021', '7615976022', '7615976023',
        '7615976024', '7615976025', '7615976026',
        '7615976027', '7615976028', '7615976029',
        '7615976030', '7615976031', '7615976032',
        '7615976033', '7615976034', '7615976035',
      ],
    ),
    _ContactSection(
      title  : 'App Admin Support',
      numbers: [
        '7615976021', '7615976022', '7615976023',
        '7615976024', '7615976025',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title    : const Text('Important Numbers',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Info banner
            Container(
              padding   : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color       : AppTheme.primaryYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border      : Border.all(
                    color: AppTheme.primaryYellow.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will get call and chat alerts from these numbers. '
                      'Save these numbers to avoid any confusion.',
                      style: TextStyle(
                          fontSize: 12, color: c.subText, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ..._sections.map((section) => _SectionWidget(
              section: section,
              c      : c,
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class _ContactSection {
  final String       title;
  final List<String> numbers;
  const _ContactSection({required this.title, required this.numbers});
}

// ─────────────────────────────────────────────────────────────────────────────
// Section widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionWidget extends StatefulWidget {
  final _ContactSection section;
  final AppColors       c;
  const _SectionWidget({required this.section, required this.c});

  @override
  State<_SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<_SectionWidget> {
  bool _saving = false;

  // ── Save all numbers for this section ──────────────────────────────────────
  // Strategy:
  // 1. Try flutter_contacts if available (deep save).
  // 2. Fall back to opening the dialer for the first number (native Add Contact).
  // We use url_launcher (already in pubspec) to open tel: URI which on both
  // Android and iOS routes through the native dialer → "Add to Contacts".
  // For bulk save we open them sequentially with a small delay.
  Future<void> _addAllContacts() async {
    if (_saving) return;
    setState(() => _saving = true);

    int saved = 0;
    int failed = 0;

    for (final number in widget.section.numbers) {
      final uri = Uri(scheme: 'tel', path: '+91$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        saved++;
        // Small pause so native dialer has time to open
        await Future.delayed(const Duration(milliseconds: 400));
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    // Opening all at once via tel: is not ideal for many numbers — 
    // instead show a copy-all option and open the first one.
    // This is the standard approach without flutter_contacts package.
    _showSaveSheet();
  }

  // ── Better UX: show a bottom sheet with copy + open-in-dialer per number ──
  void _showSaveSheet() {
    final c = widget.c;
    showModalBottomSheet(
      context          : context,
      isScrollControlled: true,
      backgroundColor  : Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color       : c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Handle
            const SizedBox(height: 12),
            Container(
              width : 40, height: 4,
              decoration: BoxDecoration(
                  color       : c.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.section.title,
                      style: TextStyle(
                          fontSize  : 16,
                          fontWeight: FontWeight.w700,
                          color     : c.text),
                    ),
                  ),
                  // Copy all
                  TextButton.icon(
                    onPressed: () {
                      final all = widget.section.numbers
                          .map((n) => '+91 $n')
                          .join(', ');
                      Clipboard.setData(ClipboardData(text: all));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content        : const Text('All numbers copied!'),
                          behavior       : SnackBarBehavior.floating,
                          backgroundColor: Colors.green.shade700,
                          shape          : RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon : const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy All'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryYellow),
                  ),
                ],
              ),
            ),

            const Divider(),

            // List of numbers with individual save buttons
            Flexible(
              child: ListView.builder(
                shrinkWrap : true,
                padding    : const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                itemCount  : widget.section.numbers.length,
                itemBuilder: (ctx, i) {
                  final num = widget.section.numbers[i];
                  final display = '+91 $num';
                  return _NumberRow(
                    number  : num,
                    display : display,
                    label   : '${widget.section.title} ${i + 1}',
                    c       : c,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c      = widget.c;
    final isDark = context.isDark;

    // Format numbers as readable text
    final numbersText = widget.section.numbers
        .asMap()
        .entries
        .map((e) => '+91 ${e.value}')
        .join(',  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Section header
        Row(
          children: [
            Container(
              width : 4, height: 18,
              decoration: BoxDecoration(
                color       : AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.section.title,
              style: TextStyle(
                fontSize  : 16,
                fontWeight: FontWeight.w700,
                color     : c.text,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding   : const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color       : AppTheme.primaryYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.section.numbers.length} numbers',
                style: TextStyle(
                    fontSize  : 10,
                    fontWeight: FontWeight.w600,
                    color     : Colors.orange.shade800),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Numbers text
        Container(
          width     : double.infinity,
          padding   : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color       : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border      : Border.all(color: c.border),
          ),
          child: Text(
            numbersText,
            style: TextStyle(
                fontSize: 13, color: c.subText, height: 1.7),
          ),
        ),

        const SizedBox(height: 12),

        // Add Contact button
        SizedBox(
          width : double.infinity,
          height: 44,
          child : ElevatedButton.icon(
            onPressed: _saving ? null : _showSaveSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor        : AppTheme.primaryYellow,
              foregroundColor        : Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation              : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon : _saving
                ? const SizedBox(
                    width : 16, height: 16,
                    child : CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black54))
                : const Icon(Icons.person_add_rounded, size: 18),
            label: Text(
              _saving ? 'Opening...' : 'Add Contacts',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: c.divider),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single number row inside the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _NumberRow extends StatefulWidget {
  final String    number;
  final String    display;
  final String    label;
  final AppColors c;
  const _NumberRow({
    required this.number,
    required this.display,
    required this.label,
    required this.c,
  });

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

class _NumberRowState extends State<_NumberRow> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);

    // Opens native dialer / contacts app with the number pre-filled.
    // On Android: opens dialer where user can tap "Add to contacts"
    // On iOS: tapping the number opens "Add to Contacts" sheet
    final uri = Uri(scheme: 'tel', path: widget.number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: widget.display));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.display} copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: widget.display));
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;

    return Container(
      margin : const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(10),
        border      : Border.all(color: c.border),
      ),
      child: Row(
        children: [

          // Phone icon
          Container(
            width : 36, height: 36,
            decoration: BoxDecoration(
              color       : AppTheme.primaryYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.phone_rounded,
                size: 18, color: Colors.orange.shade700),
          ),
          const SizedBox(width: 10),

          // Number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.display,
                    style: TextStyle(
                        fontSize  : 14,
                        fontWeight: FontWeight.w600,
                        color     : c.text)),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 11, color: c.subText)),
              ],
            ),
          ),

          // Copy button
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.display));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content        : Text('${widget.display} copied!'),
                  behavior       : SnackBarBehavior.floating,
                  duration       : const Duration(seconds: 1),
                  backgroundColor: Colors.green.shade700,
                  shape          : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              padding   : const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color       : c.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.copy_rounded, size: 14, color: c.subText),
            ),
          ),

          const SizedBox(width: 8),

          // Save button
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              padding   : const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: _saving
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFCD417), Color(0xFFFFE569)]),
                color       : _saving ? Colors.grey.shade200 : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _saving
                  ? const SizedBox(
                      width : 14, height: 14,
                      child : CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black54))
                  : const Text('Save',
                      style: TextStyle(
                          fontSize  : 12,
                          fontWeight: FontWeight.w700,
                          color     : Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}