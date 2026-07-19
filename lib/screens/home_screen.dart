import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/language_service.dart';
import '../services/app_localizations.dart';
import '../services/theme_service.dart';
import 'about_screen.dart';
import 'browse_diseases_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  void _selectTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final screens = [
      DashboardPage(onStartScan: () => _selectTab(1)),
      const CameraScreen(),
      const HistoryScreen(),
      const StatisticsScreen(),
      const BrowseDiseasesScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: strings.text('home'),
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: strings.text('scan'),
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: strings.text('history'),
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: strings.text('statistics'),
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: strings.text('diseases'),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onStartScan});

  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('app_title')),
        centerTitle: true,
        actions: const [_ThemeButton(), _LanguageMenu(), _AboutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.eco, size: 64, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    strings.text('ai_detection'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.text('ai_description')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.text('start_scan')),
              subtitle: Text(strings.text('gallery_hint')),
              trailing: const Icon(Icons.chevron_right),
              onTap: onStartScan,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(strings.text('browse_diseases')),
              subtitle: Text(strings.text('browse_hint')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BrowseDiseasesScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const _DisclaimerCard(),
        ],
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu();

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();

    return PopupMenuButton<AppLanguage>(
      tooltip: AppLocalizations.of(context).text('language'),
      icon: const Icon(Icons.language),
      initialValue: languageService.language,
      onSelected: languageService.setLanguage,
      itemBuilder: (context) {
        return [
          for (final language in AppLanguage.values)
            PopupMenuItem(value: language, child: Text(language.label)),
        ];
      },
    );
  }
}

class _AboutButton extends StatelessWidget {
  const _AboutButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).text('about'),
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
      },
      icon: const Icon(Icons.info_outline),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final strings = AppLocalizations.of(context);
    final isDarkMode = themeService.isDarkMode;

    return IconButton(
      tooltip: strings.text(isDarkMode ? 'light_mode' : 'dark_mode'),
      onPressed: themeService.toggleTheme,
      icon: Icon(
        isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AppLocalizations.of(context).text('disclaimer')),
            ),
          ],
        ),
      ),
    );
  }
}
