import 'package:astrologer_app/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appearance"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          _ThemeOptionTile(
            title: "System Default",
            subtitle: "Follow device theme",
            icon: Icons.settings_suggest,
            selected: themeMode == ThemeMode.system,
            onTap: () => themeProvider.setTheme(ThemeMode.system),
          ),

          _ThemeOptionTile(
            title: "Light Mode",
            subtitle: "Always use light theme",
            icon: Icons.light_mode,
            selected: themeMode == ThemeMode.light,
            onTap: () => themeProvider.setTheme(ThemeMode.light),
          ),

          _ThemeOptionTile(
            title: "Dark Mode",
            subtitle: "Always use dark theme",
            icon: Icons.dark_mode,
            selected: themeMode == ThemeMode.dark,
            onTap: () => themeProvider.setTheme(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}
