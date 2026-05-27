import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/HomeScreen.dart';
import 'package:astrologer_app/features/account/SplashScreen.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/features/service/service/navigationservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/theme_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/responsive.dart';

import 'l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
       navigatorKey: NavigationManager().navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Professional App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            Responsive.init(context);
            FigmaSize.init(context);
            return child!;
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
