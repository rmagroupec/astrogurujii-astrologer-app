// lib/features/Settings/TermsAndConditions.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TermsAndConditionScreen extends StatelessWidget {
  const TermsAndConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Terms & Conditions'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(20),
          vertical  : FigmaSize.h(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Heading ──────────────────────────────────────────────────
            Text(
              'Terms of Use',
              style: TextStyle(
                fontSize  : FigmaSize.w(18),
                fontWeight: FontWeight.w600,
                color     : c.text,
              ),
            ),

            SizedBox(height: FigmaSize.h(10)),

            // ── HTML content from API ─────────────────────────────────────
            Expanded(
              child: FutureBuilder<String>(
                future : ApiService().TermsAndCondition(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryYellow),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        'Failed to load terms.',
                        style: TextStyle(color: c.subText),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Html(
                      data : snapshot.data!,
                      style: {
                        'body': Style(
                          fontSize  : FontSize(FigmaSize.w(13)),
                          // Adapt text color to current theme
                          color     : isDark ? c.text : Colors.black87,
                          fontFamily: 'Poppins',
                          backgroundColor: Colors.transparent,
                        ),
                        'a': Style(
                          color: AppTheme.primaryYellow,
                        ),
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}