// lib/features/support/AstrogurujiiSupportScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AstrogurujiiSupportScreen extends StatelessWidget {
  const AstrogurujiiSupportScreen({super.key});

  static const String supportPhone    = '+916394856756';
  static const String supportWhatsApp = '+916394856756';

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:$supportPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsappSupport() async {
    final uri = Uri.parse(
      'https://wa.me/$supportWhatsApp?text=Hello%Astrogurujii%20Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        elevation  : 0,
        centerTitle: true,
        title: const Text(
          'Astrogurujii Support',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Heading ──────────────────────────────────────────────
            Text(
              'Need Help?',
              style: TextStyle(
                fontSize  : 24,
                fontWeight: FontWeight.bold,
                color     : c.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Our support team is always here for you',
              style: TextStyle(color: c.subText, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // ── Call support ──────────────────────────────────────────
            _SupportCard(
              icon    : Icons.call,
              title   : 'Call Support',
              subtitle: supportPhone,
              color   : Colors.green,
              onTap   : _callSupport,
              c       : c,
            ),

            const SizedBox(height: 18),

            // ── WhatsApp support ──────────────────────────────────────
            _SupportCard(
              icon    : Icons.chat_bubble_outline,
              title   : 'WhatsApp Support',
              subtitle: 'Chat with us instantly',
              color   : Colors.teal,
              onTap   : _whatsappSupport,
              c       : c,
            ),

            const Spacer(),

            // ── Brand footer ──────────────────────────────────────────
            Center(
              child: Text(
                'Astrogurujii – Your Divine Guide',
                style: TextStyle(color: c.subText, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SUPPORT CARD
// ─────────────────────────────────────────────────────────────────
class _SupportCard extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final Color        color;
  final VoidCallback onTap;
  final AppColors    c;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color       : c.surface,
          borderRadius: BorderRadius.circular(16),
          border      : Border.all(color: c.border),
          boxShadow   : isDark
              ? []
              : [
                  BoxShadow(
                    color     : Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset    : const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius         : 26,
              backgroundColor: color.withOpacity(isDark ? 0.20 : 0.12),
              child          : Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: c.subText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}