import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/language_service.dart';
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
  int _currentIndex = 0;

  void _selectTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final screens = <Widget>[
      DashboardPage(
        onStartScan: () => _selectTab(1),
        onOpenHistory: () => _selectTab(2),
        onOpenStatistics: () => _selectTab(3),
        onOpenDiseases: () => _selectTab(4),
      ),
      const CameraScreen(),
      const HistoryScreen(),
      const StatisticsScreen(),
      const BrowseDiseasesScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: _FloatingTaskbar(
          currentIndex: _currentIndex,
          onSelected: _selectTab,
          labels: [
            strings.text('home'),
            strings.text('scan'),
            strings.text('history'),
            strings.text('statistics'),
            strings.text('diseases'),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onStartScan,
    required this.onOpenHistory,
    required this.onOpenStatistics,
    required this.onOpenDiseases,
  });

  final VoidCallback onStartScan;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenDiseases;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? colorScheme.surface : const Color(0xFFF9FCF8),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: SizedBox(
              width: constraints.maxWidth - 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DashboardHeader(),
                  const SizedBox(height: 18),
                  _HeroDetectionCard(onStartScan: onStartScan),
                  const SizedBox(height: 20),
                  _QuickActions(
                    onStartScan: onStartScan,
                    onOpenHistory: onOpenHistory,
                    onOpenStatistics: onOpenStatistics,
                    onOpenDiseases: onOpenDiseases,
                  ),
                  const SizedBox(height: 28),
                  _SupportedCrops(onViewAll: onOpenDiseases),
                  const SizedBox(height: 26),
                  const _HelpfulTip(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showAboutOverflow = constraints.maxWidth >= 400;
        return Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.energy_savings_leaf_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.text('app_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.06,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.text('home_tagline'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const _ThemeButton(),
            _LanguageMenu(includeAbout: !showAboutOverflow),
            if (showAboutOverflow) const _HeaderOverflowMenu(),
          ],
        );
      },
    );
  }
}

class _HeroDetectionCard extends StatelessWidget {
  const _HeroDetectionCard({required this.onStartScan});

  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? colorScheme.onSurface : const Color(0xFF062D27);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final artworkSize = compact ? 210.0 : 250.0;
        final titleRight = compact ? 96.0 : 126.0;
        final descriptionRight = compact ? 132.0 : 150.0;

        // A fixed height is required here: a Stack containing only Positioned
        // children cannot determine its height inside a vertical scroll view.
        return SizedBox(
          height: compact ? 276 : 266,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF103C35), const Color(0xFF0A2722)]
                    : [const Color(0xFFE7F7E8), const Color(0xFFF8FDF7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  Positioned(
                    top: compact ? -18 : -30,
                    right: compact ? -38 : -30,
                    child: _LeafArtwork(size: artworkSize),
                  ),
                  Positioned(
                    left: 24,
                    right: titleRight,
                    top: 26,
                    child: Text(
                      strings.text('home_hero_title'),
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                            letterSpacing: -1.1,
                          ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: descriptionRight,
                    top: compact ? 132 : 116,
                    child: Text(
                      strings.text('home_hero_description'),
                      maxLines: compact ? 3 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground.withValues(alpha: 0.72),
                        height: 1.34,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 22,
                    child: SizedBox(
                      width: compact ? 196 : 224,
                      child: FilledButton.icon(
                        onPressed: onStartScan,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          backgroundColor: const Color(0xFF087A4A),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          strings.text('home_start_detection'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeafArtwork extends StatelessWidget {
  const _LeafArtwork({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFB6E185), Color(0xFF4E982B), Color(0xFF165322)],
          stops: [0, .62, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.45,
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFFEAF9C7),
              size: 154,
            ),
          ),
          const Icon(Icons.crop_free_rounded, size: 168, color: Colors.white),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onStartScan,
    required this.onOpenHistory,
    required this.onOpenStatistics,
    required this.onOpenDiseases,
  });

  final VoidCallback onStartScan;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenDiseases;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        final compact = constraints.maxWidth < 390;
        final actions = [
          _ActionCard(
            compact: compact,
            title: strings.text('home_scan_leaf'),
            subtitle: strings.text('home_scan_leaf_hint'),
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFF138651),
            surface: const Color(0xFFE8F8EF),
            onTap: onStartScan,
          ),
          _ActionCard(
            compact: compact,
            title: strings.text('home_scan_history'),
            subtitle: strings.text('home_scan_history_hint'),
            icon: Icons.history_rounded,
            color: const Color(0xFF128AC0),
            surface: const Color(0xFFE8F6FF),
            onTap: onOpenHistory,
          ),
          _ActionCard(
            compact: compact,
            title: strings.text('home_disease_information'),
            subtitle: strings.text('home_disease_information_hint'),
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF7250C8),
            surface: const Color(0xFFF1EDFF),
            onTap: onOpenDiseases,
          ),
          _ActionCard(
            compact: compact,
            title: strings.text('statistics'),
            subtitle: strings.text('home_statistics_hint'),
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFFE77D2E),
            surface: const Color(0xFFFFF1E6),
            onTap: onOpenStatistics,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: cardWidth,
                height: compact ? 148 : 140,
                child: action,
              ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? color.withValues(alpha: .20) : surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: compact ? 44 : 54,
                height: compact ? 44 : 54,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: compact ? 23 : 28),
              ),
              SizedBox(width: compact ? 8 : 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleSmall
                                  : Theme.of(context).textTheme.titleMedium)
                              ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Icon(Icons.chevron_right_rounded, color: color, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportedCrops extends StatelessWidget {
  const _SupportedCrops({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    const crops = [
      ('home_crop_tomato', Icons.local_florist_rounded, Color(0xFFE74B3B)),
      ('home_crop_potato', Icons.agriculture_rounded, Color(0xFFC88A45)),
      ('home_crop_corn', Icons.grass_rounded, Color(0xFFF2B819)),
      ('home_crop_apple', Icons.apple_rounded, Color(0xFFE23C42)),
      ('home_crop_grape', Icons.blur_circular_rounded, Color(0xFF7851A9)),
      ('home_crop_rice', Icons.grain_rounded, Color(0xFF65A844)),
      ('home_crop_wheat', Icons.grass_rounded, Color(0xFFD5A837)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.text('home_supported_crops'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(strings.text('home_view_all')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: crops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              final crop = crops[index];
              return SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: crop.$3.withValues(alpha: .14),
                      ),
                      child: Icon(crop.$2, color: crop.$3, size: 34),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.text(crop.$1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HelpfulTip extends StatelessWidget {
  const _HelpfulTip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: .56),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            Icons.energy_savings_leaf_rounded,
            color: colorScheme.primary,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.text('home_tip_title'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.text('home_tip_description'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTaskbar extends StatelessWidget {
  const _FloatingTaskbar({
    required this.currentIndex,
    required this.onSelected,
    required this.labels,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<String> labels;

  static const _icons = [
    Icons.home_rounded,
    Icons.camera_alt_rounded,
    Icons.history_rounded,
    Icons.bar_chart_rounded,
    Icons.menu_book_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: .16),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: colorScheme.primaryContainer,
          selectedIndex: currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: onSelected,
          destinations: List.generate(
            labels.length,
            (index) => NavigationDestination(
              icon: Icon(_icons[index]),
              selectedIcon: Icon(_icons[index], color: colorScheme.primary),
              label: labels[index],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.includeAbout});

  final bool includeAbout;

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    return PopupMenuButton<Object>(
      tooltip: AppLocalizations.of(context).text('language'),
      icon: const Icon(Icons.language_rounded),
      onSelected: (selection) {
        if (selection is AppLanguage) {
          languageService.setLanguage(selection);
        } else if (selection == _HeaderAction.about) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
        }
      },
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          CheckedPopupMenuItem<Object>(
            value: language,
            checked: languageService.language == language,
            child: Text(language.label),
          ),
        if (includeAbout) const PopupMenuDivider(),
        if (includeAbout)
          PopupMenuItem<Object>(
            value: _HeaderAction.about,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context).text('about')),
              ],
            ),
          ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDarkMode = themeService.isDarkMode;
    return IconButton(
      tooltip: AppLocalizations.of(
        context,
      ).text(isDarkMode ? 'light_mode' : 'dark_mode'),
      onPressed: themeService.toggleTheme,
      icon: Icon(
        isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
    );
  }
}

enum _HeaderAction { about }

class _HeaderOverflowMenu extends StatelessWidget {
  const _HeaderOverflowMenu();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopupMenuButton<_HeaderAction>(
      tooltip: strings.text('about'),
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        if (action == _HeaderAction.about) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _HeaderAction.about,
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded),
              const SizedBox(width: 12),
              Text(strings.text('about')),
            ],
          ),
        ),
      ],
    );
  }
}
