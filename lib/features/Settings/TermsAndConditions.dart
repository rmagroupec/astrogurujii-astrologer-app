import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/service/apiService.dart';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TermsAndConditionScreen extends StatelessWidget {
  const TermsAndConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// AppBar
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),

      /// Body
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(20),
          vertical: FigmaSize.h(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Heading
            Text(
              "Terms of Use",
              style: TextStyle(
                fontSize: FigmaSize.w(18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            SizedBox(height: FigmaSize.h(10)),

            /// HTML from API
            Expanded(
              child: FutureBuilder<String>(
                future: ApiService().TermsAndCondition(context),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    child: Html(
                      data: snapshot.data!,
                      style: {
                        "body": Style(
                          fontSize: FontSize(FigmaSize.w(13)),
                          color: Colors.black87,
                          fontFamily: 'Poppins',
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
