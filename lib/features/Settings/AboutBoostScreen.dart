// lib/features/Settings/AboutBoostScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens ──────────────────────────────────
// ── Full content: English + Hindi translation ─────────────────────────────────

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

            // ═══════════════════════════════════════════════════════════════
            // ENGLISH
            // ═══════════════════════════════════════════════════════════════

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
            SizedBox(height: FigmaSize.h(14)),
            _bullet(
              'Astrologer with excellent quality of work and performance are eligible for boost.',
              c,
            ),

            SizedBox(height: FigmaSize.h(16)),
            _para(
              '(Quality of your work is not just limited to customer ratings but various other '
              'factors are also taken into considerations which are confidential. In case you are '
              'ineligible for boost, we suggest you to work on your profile quality, primarily on '
              'your customer satisfaction.)',
              c,
            ),

            SizedBox(height: FigmaSize.h(40)),
            Divider(color: c.divider),
            SizedBox(height: FigmaSize.h(24)),

            // ═══════════════════════════════════════════════════════════════
            // हिंदी (HINDI TRANSLATION)
            // ═══════════════════════════════════════════════════════════════

            _para(
              'बूस्ट सुविधा के जरिए अपनी प्रोफाइल को बूस्ट करके आप नए ग्राहकों को आकर्षित करते है। '
              'आपको सलाह दी जाती है की एक निश्चित अंतराल पर बूस्ट का इस्तेमाल करके अपने साथ नये '
              'ग्राहक जोड़ते रहे।',
              c,
            ),

            SizedBox(height: FigmaSize.h(20)),
            _heading('बूस्ट कैसे काम करता है?', c),
            SizedBox(height: FigmaSize.h(10)),

            _para(
              'एक बार जब आप ऑटो बूस्ट अपने प्रोफाइल पर सक्रिय कर लेते है तो सिस्टम आपकी प्रोफाइल को '
              'एक निश्चित अंतराल पर पूरे दिन में, स्लॉट उपलब्धता के आधार पे लगाता रहता है। प्रत्येक '
              'बूस्ट स्लॉट 30 मिनट तक रहता है और यह आपको तभी मिलता है, जब आप निम्नलिखित मानदंडों को '
              'पूरा करते हैं-',
              c,
            ),

            SizedBox(height: FigmaSize.h(14)),
            _bullet('आप सेवा के लिए उपलब्ध/ऑनलाइन हैं।', c),
            SizedBox(height: FigmaSize.h(10)),
            _bullet(
                'आपकी वेटलिस्ट में आपसे जुड़ने के लिए इंतजार कर रहे कोई ग्राहक नहीं हैं।', c),

            SizedBox(height: FigmaSize.h(20)),
            _heading('ध्यान देने योग्य बातें -', c),
            SizedBox(height: FigmaSize.h(10)),

            _bullet(
              'बूस्ट स्लॉट के दौरान वेटलिस्ट में शामिल होने वाले सभी उपयोगकर्ताओं के माध्यम से आपकी '
              'कमाई आपकी ग्राहक कीमत का 50% के बजाय 30% होगी। एक बार जब उपयोगकर्ता नया सत्र शुरू करने '
              'से पहले आपके साथ कुल 30 मिनट तक जुड़ चुका हो, तो इस उपयोगकर्ता के माध्यम से आपकी कमाई '
              'बढ़कर आपकी ग्राहक कीमत का 50% हो जाएगी।',
              c,
            ),
            SizedBox(height: FigmaSize.h(14)),
            _bullet(
              'उन ग्राहकों पर बूस्ट शुल्क लागू नहीं होता जो पिछले 7 दिनों में आपसे जुड़ चुके हैं लेकिन '
              'बूस्ट स्लॉट के दौरान आपकी वेटलिस्ट में शामिल होते हैं।',
              c,
            ),

            SizedBox(height: FigmaSize.h(20)),
            _heading('पात्रता मानदंड', c),
            SizedBox(height: FigmaSize.h(10)),

            _bullet(
              'केवल विशिष्ट ज्योतिषी (हरे टिक वाले ज्योतिषी) ही बूस्ट के लिए पात्र हैं।',
              c,
            ),
            SizedBox(height: FigmaSize.h(14)),
            _bullet(
              'उत्कृष्ट गुणवत्ता और प्रदर्शन वाले ज्योतिषी बूस्ट के लिए पात्र हैं।',
              c,
            ),

            SizedBox(height: FigmaSize.h(16)),
            _para(
              '(आपके काम की गुणवत्ता केवल ग्राहक रेटिंग तक सीमित नहीं है बल्कि विभिन्न अन्य कारकों को '
              'भी ध्यान में रखा जाता है जो गोपनीय हैं। यदि आप बूस्ट के लिए अपात्र हैं, तो हम सुझाव देते '
              'हैं कि आप अपनी प्रोफाइल की गुणवत्ता पर, मुख्य रूप से अपनी ग्राहक संतुष्टि पर काम करें।)',
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