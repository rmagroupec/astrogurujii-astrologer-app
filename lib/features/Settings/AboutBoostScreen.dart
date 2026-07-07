// lib/features/Settings/AboutBoostScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens ──────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class AboutBoostScreen extends StatelessWidget {
  const AboutBoostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('About Boost'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(FigmaSize.w(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _para(
              'Boosting your profile through the Boost feature helps you to attract new users. '
              'It is suggested to boost your profile at regular intervals to build new customer base.',
              c,
            ),

            SizedBox(height: FigmaSize.h(20)),
            _heading('How does the boost work?', c),
            SizedBox(height: FigmaSize.h(10)),

            _para(
              'Once you enable the autoboost on your profile, the system will boost your profile '
              'at regular intervals throughout the day as per the availability of the slots for boost. '
              'Each boost slot lasts for 30 minutes and is only provided to you if you meet the following conditions-',
              c,
            ),

            SizedBox(height: FigmaSize.h(14)),
            _bullet('You are available/online for the service.', c),
            SizedBox(height: FigmaSize.h(10)),
            _bullet(
                'There are no customers waiting to connect with you in your waitlist.', c),

            SizedBox(height: FigmaSize.h(20)),
            _heading('Points to Note -', c),
            SizedBox(height: FigmaSize.h(10)),

            _bullet(
              'Your earnings through all the users joining the waitlist during the boost slot shall be '
              '30% of your customer price instead of 50%. Once the user has had connected with you for '
              '30 minutes in total before initiating a new session, your earnings through this user shall '
              'increase to 50% of your customer price.',
              c,
            ),
            SizedBox(height: FigmaSize.h(14)),
            _bullet(
              'Boost charges are not applicable on customers who have connected with you in past 7 days '
              'but join your waitlist during the boost slot.',
              c,
            ),

            SizedBox(height: FigmaSize.h(20)),
            _heading('Eligibility Criteria', c),
            SizedBox(height: FigmaSize.h(10)),

            _bullet(
              'Only exclusive astrologers (astrologers with green tick) are eligible for boost',
              c,
            ),

            SizedBox(height: FigmaSize.h(40)),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text, AppColors c) => Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize  : FigmaSize.w(15),
          fontWeight: FontWeight.w700,
          color     : c.text,
          height    : 1.5,
        ),
      );

  Widget _para(String text, AppColors c) => Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize  : FigmaSize.w(14),
          fontWeight: FontWeight.w400,
          color     : c.text,
          height    : 1.65,
        ),
      );

  Widget _bullet(String text, AppColors c) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: FigmaSize.h(3)),
            child: Text(
              '- ',
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w600,
                color     : c.text,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize  : FigmaSize.w(14),
                fontWeight: FontWeight.w400,
                color     : c.text,
                height    : 1.65,
              ),
            ),
          ),
        ],
      );
}