// lib/features/Settings/MyMembership.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';

class Mymembership extends StatefulWidget {
  const Mymembership({super.key});

  @override
  State<Mymembership> createState() => _MymembershipState();
}

class _MymembershipState extends State<Mymembership> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('My Membership'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership_outlined,
                size: 56, color: c.subText.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(
              'No Data Available',
              style: TextStyle(color: c.subText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}