// lib/features/reports/AddNoteSheet.dart
// ── Bottom sheet to add / edit a private astrologer note on a consultation ────

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

class AddNoteSheet extends StatefulWidget {
  final String channelId;
  final String existingNote; // pass "" if no note yet

  const AddNoteSheet({
    super.key,
    required this.channelId,
    required this.existingNote,
  });

  /// Opens the sheet and returns the saved note (or null if dismissed).
  static Future<String?> show(
    BuildContext context, {
    required String channelId,
    required String existingNote,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(
        channelId: channelId,
        existingNote: existingNote,
      ),
    );
  }

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existingNote);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _ctrl.text.trim();
    setState(() => _saving = true);
    try {
      final res  = await ApiClient().post(
        'astrologer_api/save_consultation_note',
        {'channel_id': widget.channelId, 'note': note},
        isAuthRequired: true,
      );
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (body['result'] == true || body['status'] == true) {
        Navigator.pop(context, note);           // return saved note to caller
      } else {
        _showSnack(body['message'] ?? 'Failed to save note');
        setState(() => _saving = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error saving note');
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c      = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottom),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0277BD).withOpacity(isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.note_alt_rounded, color: Color(0xFF0277BD), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Note',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
                    Text('Only you can see this note',
                        style: TextStyle(fontSize: 11, color: c.subText)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: c.subText, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Text field ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 6,
              minLines: 4,
              style: TextStyle(fontSize: 14, color: c.text),
              decoration: InputDecoration(
                hintText: 'e.g. User came for marriage problem. Suggested wearing yellow sapphire...',
                hintStyle: TextStyle(fontSize: 13, color: c.subText.withOpacity(0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Character count ───────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder(
              valueListenable: _ctrl,
              builder: (_, __, ___) => Text(
                '${_ctrl.text.length} chars',
                style: TextStyle(fontSize: 11, color: c.subText),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Save button ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0277BD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Note', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}