import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class LanguagePopup extends StatefulWidget {
  const LanguagePopup({super.key});

  @override
  State<LanguagePopup> createState() => _LanguagePopupState();
}

class _LanguagePopupState extends State<LanguagePopup> {
  String selectedLanguage = 'English';

  final List<Map<String, String>> languages = [
    {'name': 'English', 'native': 'Eng'},
    {'name': 'Hindi', 'native': 'हिन्दी'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'name': 'Tamil', 'native': 'தமிழ்'},
    {'name': 'Telugu', 'native': 'తెలుగు'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Set the background to pure white
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20), // Margin from screen edges
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Constrains the popup height to its content
          children: [
            // Header with Close Button
            Stack(
              alignment: Alignment.center,
              children: [
                 Text(
                  'Choose Language',
                  style: TextStyle(fontSize: FigmaSize.w(18), fontWeight: FontWeight.w600, color: Colors.black),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: FigmaSize.w(24)),
                  ),
                ),
              ],
            ),
             SizedBox(height: FigmaSize.h(24),),

            // Language Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguage == lang['name'];
                
                return GestureDetector(
                  onTap: () => setState(() => selectedLanguage = lang['name']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCD417).withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Color(0xFFFFD700) : Colors.amber.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang['native']!,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: FigmaSize.w(16), color: Colors.black),
                        ),
                        Text(lang['name']!, style: TextStyle(fontSize: FigmaSize.w(16), fontWeight: FontWeight.w600, color: Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: FigmaSize.h(24)),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: FigmaSize.h(60),
              child: ElevatedButton(
                onPressed: () {
                  print("Selected: $selectedLanguage");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child:  Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}