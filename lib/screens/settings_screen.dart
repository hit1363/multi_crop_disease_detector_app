import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../utils/dashboard_palette.dart';
import 'about_screen.dart';
import 'browse_diseases_screen.dart';

/// The dashboard's Settings tab.
///
/// Holds the preferences that used to live as header icons (language, theme)
/// plus the secondary destinations that no longer have their own tab
/// (the disease library and About).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onOpenLibrary});

  /// Invoked for the "Disease Library" row. When null the screen pushes
  /// [BrowseDiseasesScreen] itself, so the tab works standalone.
  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;
    final languageService = context.watch<LanguageService>();
    final themeService = context.watch<ThemeService>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backdropTop, palette.backdropBottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              strings.text('settings'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.ink,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: strings.text('settings_language'),
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    // ignore: deprecated_member_use
                    groupValue: languageService.language,
                    // ignore: deprecated_member_use
                    onChanged: (selected) {
                      if (selected != null) {
                        languageService.setLanguage(selected);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      language.label,
                      style: TextStyle(color: palette.ink),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              title: strings.text('settings_appearance'),
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: themeService.isDarkMode,
                  onChanged: (_) => themeService.toggleTheme(),
                  title: Text(
                    strings.text(
                      themeService.isDarkMode ? 'dark_mode' : 'light_mode',
                    ),
                    style: TextStyle(color: palette.ink),
                  ),
                  secondary: Icon(
                    themeService.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              title: strings.text('settings_library'),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.menu_book_rounded,
                    color: palette.primary,
                  ),
                  title: Text(
                    strings.text('settings_library'),
                    style: TextStyle(color: palette.ink),
                  ),
                  subtitle: Text(
                    strings.text('settings_library_hint'),
                    style: TextStyle(color: palette.inkSoft, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    final openLibrary = onOpenLibrary;
                    if (openLibrary != null) {
                      openLibrary();
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BrowseDiseasesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: palette.primary,
                  ),
                  title: Text(
                    strings.text('about'),
                    style: TextStyle(color: palette.ink),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${strings.text('settings_version')} 1.0.0',
                style: TextStyle(color: palette.inkSoft, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    // Material, not a decorated Container: ListTile paints its background and
    // ink splash onto the nearest Material ancestor, so a plain coloured box in
    // between hides them and trips a framework assertion.
    return Material(
      color: palette.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: palette.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}
