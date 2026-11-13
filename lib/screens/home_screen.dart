import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../utils/dashboard_palette.dart';
import '../widgets/home_ornaments.dart';
import 'browse_diseases_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backdropTop, palette.backdropBottom],
          stops: const [0.0, 0.55],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 22),
              _HeroSection(
                onScanWithCamera: onScanWithCamera,
                onUploadFromGallery: onUploadFromGallery,
              ),
              const SizedBox(height: 22),
              _SupportedCropsCard(onOpenLibrary: onOpenLibrary),
              const SizedBox(height: 18),
              const _FooterSection(),
            ],
          ),
        ),
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
        const LeafBrandMark(size: 48),
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
              const SizedBox(height: 3),
              Text(
                strings.text('home_tagline'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: palette.inkSoft,
                  letterSpacing: 0.1,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Headline on the left, leaf artwork bleeding off the right edge.
            // The Column is the Stack's only non-positioned child, so the hero
            // grows with its copy instead of clipping it at large text scales.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: isRtl ? null : -8,
                  left: isRtl ? -8 : null,
                  top: 0,
                  bottom: 0,
                  width: width * 0.40,
                  child: const _LeafArtwork(),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: isRtl ? 0 : width * 0.40,
                    left: isRtl ? width * 0.40 : 0,
                    top: 6,
                    bottom: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.text('home_hero_title_lead'),
                        style: TextStyle(
                          fontSize: compact ? 26 : 29,
                          height: 1.14,
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                          letterSpacing: -0.9,
                        ),
                      ),
                      // The trailing accent word sits on its own line so the
                      // green reads as a headline flourish.
                      Text(
                        strings.text('home_hero_title_accent'),
                        style: TextStyle(
                          fontSize: compact ? 26 : 29,
                          height: 1.14,
                          fontWeight: FontWeight.w800,
                          color: palette.primaryLight,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Swoosh(
                        width: width * 0.26,
                        color: palette.primaryLight,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.text('home_hero_description'),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: palette.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

/// The photographed leaf with its scan framing.
class _LeafArtwork extends StatelessWidget {
  const _LeafArtwork();

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/images/leaf_scan.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          // The asset is decorative; the headline carries the meaning.
          excludeFromSemantics: true,
        ),
      ),
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
      child: Container(
        // The drop shadow is painted by the enclosing DecoratedBox rather than
        // by the [Ink]: an ink decoration is composited on the Material's
        // canvas, which cuts the blur at the pill edge and leaves a flat pale
        // rectangle behind the button.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: palette.primaryDeep.withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.none,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: primary ? palette.primaryGradient : null,
                color: primary ? null : palette.card,
                border: primary
                    ? null
                    : Border.all(color: palette.outlinePill, width: 1.4),
              ),
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
      ),
    );
  }
}

/// "Supported Crops" card: title, badge, five crop chips and a "More" tile.
class _SupportedCropsCard extends StatelessWidget {
  const _SupportedCropsCard({required this.onOpenLibrary});

  final VoidCallback onOpenLibrary;

  /// Crop keys in display order, with a representative icon and tint. The
  /// circles are placeholders until hand-authored crop photography lands in
  /// `assets/images/crop_name.png`, at which point [_CropCircle] picks it up.
  static const _crops = <({String key, IconData icon, Color tint})>[
    (key: 'home_crop_tomato', icon: Icons.local_florist_rounded, tint: Color(0xFFE4574C)),
    (key: 'home_crop_potato', icon: Icons.grain_rounded, tint: Color(0xFFC79A5B)),
    (key: 'home_crop_corn', icon: Icons.agriculture_rounded, tint: Color(0xFFE8B93C)),
    (key: 'home_crop_apple', icon: Icons.apple_rounded, tint: Color(0xFFD94F4F)),
    (key: 'home_crop_grape', icon: Icons.grass_rounded, tint: Color(0xFF7B5EA7)),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                  strings.text('home_crops_badge', values: {'count': '10'}),
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
                    icon: crop.icon,
                    tint: crop.tint,
                    assetName: crop.key.replaceFirst('home_crop_', ''),
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
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.assetName,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final String assetName;
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
            _CropCircle(
              assetName: assetName,
              icon: icon,
              tint: tint,
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

/// Round crop thumbnail. Falls back to a tinted placeholder until real
/// photography is dropped into `assets/images/crop_name.png`.
class _CropCircle extends StatelessWidget {
  const _CropCircle({
    required this.assetName,
    required this.icon,
    required this.tint,
  });

  final String assetName;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    final assetPath = 'assets/images/crop_$assetName.png';

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.14),
        border: Border.all(
          color: palette.cardBorder,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        // Placeholder while the asset is absent: a tinted disc with the crop's
        // icon. Swapped automatically once the file exists.
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(icon, size: 24, color: tint),
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

/// Illustration plus the handwritten-style sign-off.
class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;
    return SizedBox(
      height: 214,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -20,
            right: -20,
            bottom: 0,
            height: 190,
            child: const LandscapeArt(height: 190),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  strings.text('home_footer_tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 19,
                    height: 1.24,
                    fontWeight: FontWeight.w600,
                    color: palette.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Swoosh(
                  width: 96,
                  height: 12,
                  color: palette.primaryLight,
                  strokeWidth: 2.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Taskbar
// ---------------------------------------------------------------------------

/// Frosted, full-bleed bottom bar with four destinations and an underline on
/// the active one.
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: palette.glass,
            border: Border(top: BorderSide(color: palette.glassBorder)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
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
        color: palette.ink,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: themeService.toggleTheme,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0B2E22)
                  : Colors.white,
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
    // Resolved during build: `itemBuilder` runs when the popup opens, which is
    // outside the build phase, so it must not call `AppLocalizations.of`.
    final strings = AppLocalizations.of(context);
    final palette = context.dashboard;
    final code = languageService.language.code.toUpperCase();

    return PopupMenuButton<AppLanguage>(
      tooltip: strings.text('language'),
      position: PopupMenuPosition.under,
      onSelected: languageService.setLanguage,
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          CheckedPopupMenuItem<AppLanguage>(
            value: language,
            checked: languageService.language == language,
            child: Text(language.label),
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
            Icon(
              Icons.language_rounded,
              size: 17,
              color: palette.inkSoft,
            ),
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

