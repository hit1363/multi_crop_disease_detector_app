import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../utils/dashboard_palette.dart';
import 'browse_diseases_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

const double _taskbarBarHeight = 68;
const double _taskbarBottomGap = 10;

/// Root of the signed-in app: four tabs behind a frosted taskbar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _openingGallery = false;

  void _selectTab(int index) {
    if (index == _currentIndex) {
      return;
    }
    setState(() => _currentIndex = index);
  }

  /// Pushes the scan flow as a full-screen route. [openGalleryOnStart] jumps
  /// straight into the system picker, which is what the "Upload from Gallery"
  /// pill does.
  Future<void> _openScanner({bool openGalleryOnStart = false}) async {
    if (_openingGallery) {
      return;
    }
    setState(() => _openingGallery = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CameraScreen(openGalleryOnStart: openGalleryOnStart),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingGallery = false);
      }
    }
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BrowseDiseasesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final screens = <Widget>[
      _DashboardPage(
        onScanWithCamera: _openScanner,
        onUploadFromGallery: () => _openScanner(openGalleryOnStart: true),
        onOpenLibrary: _openLibrary,
      ),
      const HistoryScreen(),
      const StatisticsScreen(),
      SettingsScreen(onOpenLibrary: _openLibrary),
    ];

    return PopScope(
      // Back should walk the user home before it leaves the app; without this
      // Android closes the whole app from any tab.
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _selectTab(0);
        }
      },
      child: Scaffold(
        // Lets the body draw behind the glass taskbar so the blur has
        // something to frost.
        extendBody: true,
        body: screens[_currentIndex],
        bottomNavigationBar: _GlassTaskbar(
          currentIndex: _currentIndex,
          onSelected: _selectTab,
          labels: [
            strings.text('home'),
            strings.text('history'),
            strings.text('stats'),
            strings.text('settings'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.onScanWithCamera,
    required this.onUploadFromGallery,
    required this.onOpenLibrary,
  });

  final VoidCallback onScanWithCamera;
  final VoidCallback onUploadFromGallery;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    final taskbarClearance =
        MediaQuery.paddingOf(context).bottom +
        _taskbarBarHeight +
        _taskbarBottomGap;
    const topPadding = 12.0;
    final bottomPadding = taskbarClearance + 24;

    return ColoredBox(
      // Fallback behind the photo for the brief moment before it decodes.
      color: palette.backdropBottom,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fixed photographic backdrop: never scrolls, swaps with the theme.
          Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/images/bg_dark.png'
                : 'assets/images/bg_light.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minContentHeight =
                    constraints.maxHeight - topPadding - bottomPadding;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    topPadding,
                    20,
                    bottomPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minContentHeight > 0 ? minContentHeight : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _BrandHeader(),
                            const SizedBox(height: 28),
                            _HeroSection(
                              onScanWithCamera: onScanWithCamera,
                              onUploadFromGallery: onUploadFromGallery,
                            ),
                          ],
                        ),
                        _SupportedCropsCard(onOpenLibrary: onOpenLibrary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo, wordmark and tagline, with the theme and language controls.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/icons/app_icon.png',
          width: 54,
          height: 54,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.text('brand_title_line_1'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                strings.text('brand_title_line_2'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const _ThemeButton(),
        const SizedBox(width: 4),
        const _LanguagePill(),
      ],
    );
  }
}

/// Headline block, leaf artwork and the two action pills.
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onScanWithCamera,
    required this.onUploadFromGallery,
  });

  final VoidCallback onScanWithCamera;
  final VoidCallback onUploadFromGallery;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 360;
        final minHeroHeight = width < 300 ? 170.0 : 200.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Headline on the left, leaf artwork to its right.
            // The Column is the Stack's only non-positioned child, so the hero
            // grows with its copy instead of clipping it at large text scales.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeroHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: isRtl ? null : 0,
                    left: isRtl ? 0 : null,
                    top: 0,
                    bottom: 0,
                    width: width * 0.55,
                    child: const _LeafArtwork(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      right: isRtl ? 0 : width * 0.50,
                      left: isRtl ? width * 0.50 : 0,
                      top: 6,
                      bottom: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Detect Plant Diseases" with the accent word inline on
                        // the second line, exactly as the reference mockup does.
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: strings
                                    .text('home_hero_title_lead')
                                    .replaceAll('\n', ' '),
                                style: TextStyle(
                                  fontSize: compact ? 26 : 29,
                                  height: 1.14,
                                  fontWeight: FontWeight.w800,
                                  color: palette.ink,
                                  letterSpacing: -0.9,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' ${strings.text('home_hero_title_accent')}',
                                style: TextStyle(
                                  fontSize: compact ? 26 : 29,
                                  height: 1.14,
                                  fontWeight: FontWeight.w800,
                                  color: palette.primaryLight,
                                  letterSpacing: -0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _PillActionButton(
              label: strings.text('home_scan_with_camera'),
              icon: Icons.photo_camera_rounded,
              primary: true,
              onPressed: onScanWithCamera,
            ),
            const SizedBox(height: 12),
            _PillActionButton(
              label: strings.text('home_upload_from_gallery'),
              icon: Icons.image_outlined,
              primary: false,
              onPressed: onUploadFromGallery,
            ),
          ],
        );
      },
    );
  }
}

/// The photographed leaf with its scan framing. The asset has real
/// transparency, so it dissolves into the page on its own.
class _LeafArtwork extends StatelessWidget {
  const _LeafArtwork();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Leaf_Scan_UI.png',
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      // The asset is decorative; the headline carries the meaning.
      excludeFromSemantics: true,
    );
  }
}

/// One of the two full-width rounded action bars.
class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final foreground = primary ? Colors.white : palette.ink;
    final chevron = isRtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary
            ? palette.primary.withValues(alpha: 0.85)
            : palette.card.withValues(alpha: 0.85),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: primary
              ? BorderSide.none
              : BorderSide(color: palette.outlinePill, width: 1.4),
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  Icon(chevron, size: 22, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Supported Crops" card: title, badge, five crop chips and a "More" tile.
class _SupportedCropsCard extends StatelessWidget {
  const _SupportedCropsCard({required this.onOpenLibrary});

  final VoidCallback onOpenLibrary;

  /// These compact produce glyphs keep the crop row recognizable at phone
  /// scale while the app's photo library remains focused on disease examples.
  static const _crops = <({String key, String emoji, Color tint})>[
    (key: 'home_crop_tomato', emoji: '🍅', tint: Color(0xFFE4574C)),
    (key: 'home_crop_potato', emoji: '🥔', tint: Color(0xFFC79A5B)),
    (key: 'home_crop_corn', emoji: '🌽', tint: Color(0xFFE8B93C)),
    (key: 'home_crop_apple', emoji: '🍎', tint: Color(0xFFD94F4F)),
    (key: 'home_crop_grape', emoji: '🍇', tint: Color(0xFF7B5EA7)),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: palette.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.cardBorder),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 18,
                    color: palette.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.text('home_supported_crops'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.badge,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      strings.text('home_crops_badge', values: {'count': '16'}),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: palette.badgeInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final crop in _crops)
                    Expanded(
                      child: _CropTile(
                        label: strings.text(crop.key),
                        emoji: crop.emoji,
                        tint: crop.tint,
                        onTap: onOpenLibrary,
                      ),
                    ),
                  Expanded(
                    child: _MoreTile(
                      label: strings.text('home_more'),
                      onTap: onOpenLibrary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({
    required this.label,
    required this.emoji,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CropCircle(emoji: emoji, tint: tint),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: palette.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round produce chip: the crop emoji on a solid tint of the same hue.
class _CropCircle extends StatelessWidget {
  const _CropCircle({required this.emoji, required this.tint});

  final String emoji;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.18),
        border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 27, height: 1),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.card,
                border: Border.all(color: palette.outlinePill, width: 1.4),
              ),
              child: Center(
                child: Text(
                  '•••',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1,
                    color: palette.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: palette.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Taskbar
// ---------------------------------------------------------------------------

/// Tinted-glass floating pill with four destinations and an underline on the
/// active one. Sits over the body (see [Scaffold.extendBody]) so the blur has
/// content to frost.
class _GlassTaskbar extends StatelessWidget {
  const _GlassTaskbar({
    required this.currentIndex,
    required this.onSelected,
    required this.labels,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<String> labels;

  static const _icons = <IconData>[
    Icons.home_rounded,
    Icons.history_rounded,
    Icons.bar_chart_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, _taskbarBottomGap),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: palette.glass,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.glassBorder),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  height: _taskbarBarHeight,
                  child: Row(
                    children: [
                      for (var index = 0; index < labels.length; index++)
                        Expanded(
                          child: _TaskbarItem(
                            icon: _icons[index],
                            label: labels[index],
                            selected: index == currentIndex,
                            onTap: () => onSelected(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskbarItem extends StatelessWidget {
  const _TaskbarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    final color = selected ? palette.primary : palette.inkSoft;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            // Active underline. Kept as a fixed-size box (transparent when
            // inactive) so selecting a tab never shifts the row's layout.
            Container(
              height: 2.5,
              width: 20,
              decoration: BoxDecoration(
                color: selected ? palette.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header controls
// ---------------------------------------------------------------------------

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final palette = context.dashboard;
    final isDarkMode = themeService.isDarkMode;
    return Semantics(
      button: true,
      label: AppLocalizations.of(
        context,
      ).text(isDarkMode ? 'light_mode' : 'dark_mode'),
      child: Material(
        color: palette.ink.withValues(alpha: 0.55),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: themeService.toggleTheme,
          child: SizedBox(
            width: 62,
            height: 40,
            child: Center(
              child: Icon(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                // Inverted against the solid ink disc behind it.
                color: isDarkMode ? palette.backdropBottom : palette.card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The language selector: a white pill showing the active language code, with
/// the menu opened from a [PopupMenuButton].
class _LanguagePill extends StatelessWidget {
  const _LanguagePill();

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;
    final currentLanguage = languageService.language;
    final code = currentLanguage.code.toUpperCase();
    const accentColor = Color(0xFF1B7A3D);

    return PopupMenuButton<AppLanguage>(
      tooltip: strings.text('language'),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: palette.card,
      surfaceTintColor: Colors.transparent,
      // Crucial: Clips the items so they never overflow the rounded card borders
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.cardBorder),
      ),
      padding: EdgeInsets.zero,
      // Clean, uniform inner padding for the entire menu list
      menuPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      onSelected: languageService.setLanguage,
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          PopupMenuItem<AppLanguage>(
            value: language,
            height: 42, // Clean, compact fixed height
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: currentLanguage == language
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: currentLanguage == language
                        ? accentColor
                        : palette.ink,
                  ),
                ),
                if (currentLanguage == language)
                  const Icon(Icons.check_rounded, size: 16, color: accentColor),
              ],
            ),
          ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 17, color: palette.inkSoft),
            const SizedBox(width: 5),
            Text(
              code,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: palette.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}
