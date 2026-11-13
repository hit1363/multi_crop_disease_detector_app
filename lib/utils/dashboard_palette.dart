import 'package:flutter/material.dart';

/// Colours for the dashboard's illustration-led surfaces.
///
/// The dashboard departs from the flat Material palette: it sits on a pale
/// sage backdrop, uses a deep forest ink for text, and renders call-to-action
/// pills with a two-stop green gradient. Expressing those as a
/// [ThemeExtension] keeps every colour theme-aware (dark mode included) and
/// means no widget has to hard-code a hex value.
@immutable
class DashboardPalette extends ThemeExtension<DashboardPalette> {
  const DashboardPalette({
    required this.backdropTop,
    required this.backdropBottom,
    required this.ink,
    required this.inkSoft,
    required this.primary,
    required this.primaryDeep,
    required this.primaryLight,
    required this.card,
    required this.cardBorder,
    required this.badge,
    required this.badgeInk,
    required this.glass,
    required this.glassBorder,
    required this.outlinePill,
  });

  /// Vertical page backdrop, top to bottom.
  final Color backdropTop;
  final Color backdropBottom;

  /// Primary and secondary text.
  final Color ink;
  final Color inkSoft;

  /// Green used for accents, the active nav item, and the hero framing.
  final Color primary;
  final Color primaryDeep;
  final Color primaryLight;

  /// Content cards.
  final Color card;
  final Color cardBorder;

  /// Small pill badge ("10+ Crops").
  final Color badge;
  final Color badgeInk;

  /// Frosted bottom bar.
  final Color glass;
  final Color glassBorder;

  /// Border of the secondary (outlined) action pill.
  final Color outlinePill;

  static const DashboardPalette light = DashboardPalette(
    backdropTop: Color(0xFFEDF7E9),
    backdropBottom: Color(0xFFFFFFFF),
    ink: Color(0xFF0B2E22),
    inkSoft: Color(0xFF4A6B5C),
    primary: Color(0xFF1E6B33),
    primaryDeep: Color(0xFF0E5626),
    primaryLight: Color(0xFF2FA64B),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFDCEBD8),
    badge: Color(0xFFD8F0DC),
    badgeInk: Color(0xFF1B5E2A),
    glass: Color(0xF2FFFFFF),
    glassBorder: Color(0xFFE3F0DF),
    outlinePill: Color(0xFFBFDCC2),
  );

  static const DashboardPalette dark = DashboardPalette(
    backdropTop: Color(0xFF0C1F19),
    backdropBottom: Color(0xFF061410),
    ink: Color(0xFFE8F5EC),
    inkSoft: Color(0xFF9DBBAB),
    primary: Color(0xFF4CC46A),
    primaryDeep: Color(0xFF1E8A3C),
    primaryLight: Color(0xFF7BE08F),
    card: Color(0xFF12291F),
    cardBorder: Color(0xFF1F3D2E),
    badge: Color(0xFF1B3A2A),
    badgeInk: Color(0xFFA8E6B6),
    glass: Color(0xF2102318),
    glassBorder: Color(0xFF1F3D2E),
    outlinePill: Color(0xFF35604A),
  );

  /// Gradient stops for the primary action pill.
  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDeep],
  );

  @override
  DashboardPalette copyWith({
    Color? backdropTop,
    Color? backdropBottom,
    Color? ink,
    Color? inkSoft,
    Color? primary,
    Color? primaryDeep,
    Color? primaryLight,
    Color? card,
    Color? cardBorder,
    Color? badge,
    Color? badgeInk,
    Color? glass,
    Color? glassBorder,
    Color? outlinePill,
  }) {
    return DashboardPalette(
      backdropTop: backdropTop ?? this.backdropTop,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primaryLight: primaryLight ?? this.primaryLight,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      badge: badge ?? this.badge,
      badgeInk: badgeInk ?? this.badgeInk,
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      outlinePill: outlinePill ?? this.outlinePill,
    );
  }

  @override
  DashboardPalette lerp(ThemeExtension<DashboardPalette>? other, double t) {
    if (other is! DashboardPalette) {
      return this;
    }
    return DashboardPalette(
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t)!,
      backdropBottom: Color.lerp(backdropBottom, other.backdropBottom, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      badgeInk: Color.lerp(badgeInk, other.badgeInk, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      outlinePill: Color.lerp(outlinePill, other.outlinePill, t)!,
    );
  }
}

/// Convenience accessor so widgets read `context.dashboard` rather than
/// repeating the `Theme.of(context).extension<...>()!` chain.
extension DashboardPaletteX on BuildContext {
  DashboardPalette get dashboard =>
      Theme.of(this).extension<DashboardPalette>() ?? DashboardPalette.light;
}
