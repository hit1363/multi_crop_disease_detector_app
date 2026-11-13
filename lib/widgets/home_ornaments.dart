import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/dashboard_palette.dart';

/// The app's brand mark: two leaves fanned out behind a magnifier whose lens
/// holds a third, smaller leaf.
///
/// Drawn rather than shipped as a bitmap so it stays crisp at any size and
/// recolours with the active theme.
class LeafBrandMark extends StatelessWidget {
  const LeafBrandMark({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LeafBrandMarkPainter(
          leafLight: palette.primaryLight,
          leafDark: palette.primary,
          ring: palette.ink,
        ),
      ),
    );
  }
}

class _LeafBrandMarkPainter extends CustomPainter {
  _LeafBrandMarkPainter({
    required this.leafLight,
    required this.leafDark,
    required this.ring,
  });

  final Color leafLight;
  final Color leafDark;
  final Color ring;

  /// A pointed-both-ends leaf from [base] to [tip], bowed by [bulge].
  static Path _leaf(Offset base, Offset tip, double bulge) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) {
      return Path();
    }
    final nx = -dy / length;
    final ny = dx / length;
    final c1 = Offset(
      base.dx + dx * 0.42 + nx * bulge,
      base.dy + dy * 0.42 + ny * bulge,
    );
    final c2 = Offset(
      base.dx + dx * 0.42 - nx * bulge,
      base.dy + dy * 0.42 - ny * bulge,
    );
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final base = p(0.33, 0.68);

    // Two leaves fanning up and out from a common stem.
    canvas.drawPath(
      _leaf(base, p(0.03, 0.17), 0.085 * s),
      Paint()..color = leafDark,
    );
    canvas.drawPath(
      _leaf(base, p(0.45, 0.04), 0.075 * s),
      Paint()..color = leafLight,
    );

    // Magnifier lens.
    final lensCenter = p(0.62, 0.61);
    final lensRadius = 0.255 * s;
    canvas.drawCircle(
      lensCenter,
      lensRadius,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.072 * s,
    );

    // Handle, from the lens rim at 45 degrees outward.
    final dir = 1 / math.sqrt2;
    final handleStart = Offset(
      lensCenter.dx + lensRadius * dir,
      lensCenter.dy + lensRadius * dir,
    );
    final handleEnd = Offset(
      lensCenter.dx + (lensRadius + 0.20 * s) * dir,
      lensCenter.dy + (lensRadius + 0.20 * s) * dir,
    );
    canvas.drawLine(
      handleStart,
      handleEnd,
      Paint()
        ..color = ring
        ..strokeWidth = 0.085 * s
        ..strokeCap = StrokeCap.round,
    );

    // Leaf seen through the lens.
    canvas.drawPath(
      _leaf(p(0.535, 0.695), p(0.715, 0.515), 0.045 * s),
      Paint()..color = leafLight,
    );
  }

  @override
  bool shouldRepaint(_LeafBrandMarkPainter oldDelegate) {
    return oldDelegate.leafLight != leafLight ||
        oldDelegate.leafDark != leafDark ||
        oldDelegate.ring != ring;
  }
}

/// The hand-drawn green underline used beneath the hero heading and the footer
/// tagline.
class Swoosh extends StatelessWidget {
  const Swoosh({
    super.key,
    this.width = 108,
    this.height = 14,
    this.color,
    this.strokeWidth = 2.6,
  });

  final double width;
  final double height;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SwooshPainter(
          color: color ?? context.dashboard.primaryLight,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  _SwooshPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.03, h * 0.80)
      ..cubicTo(w * 0.30, h * 0.22, w * 0.66, h * 0.10, w * 0.97, h * 0.42);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    // A lighter second pass gives the stroke its tapered, drawn-by-hand feel.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.1
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_SwooshPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// The rolling-hills footer artwork: misty sky, layered hills, tree clusters
/// and a small farmhouse.
///
/// Painted rather than sourced as a bitmap because the reference illustration
/// has its tagline burnt into the pixels; drawing it keeps the caption live
/// text (and therefore translatable) and lets the whole scene adapt to dark
/// mode.
class LandscapeArt extends StatelessWidget {
  const LandscapeArt({super.key, this.height = 190});

  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.dashboard;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LandscapePainter(palette: palette, isDark: isDark),
      ),
    );
  }
}

class _LandscapePainter extends CustomPainter {
  _LandscapePainter({required this.palette, required this.isDark});

  final DashboardPalette palette;
  final bool isDark;

  /// Blends a light-mode scene colour toward the page ink in dark mode, so the
  /// illustration dims with the theme instead of glowing.
  Color _tone(Color light, double strength) {
    if (!isDark) {
      return light;
    }
    return Color.lerp(light, palette.backdropTop, strength)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hillBack = _tone(const Color(0xFFCBE6B4), 0.55);
    final hillMid = _tone(const Color(0xFF9CD177), 0.45);
    final hillFront = _tone(const Color(0xFF63B247), 0.34);
    final hillNear = _tone(const Color(0xFF3E8F32), 0.28);
    final treeDark = _tone(const Color(0xFF2E6B33), 0.30);
    final treeLight = _tone(const Color(0xFF4E9440), 0.30);

    // Distant mountains, very pale, behind everything.
    final mountains = Path()
      ..moveTo(0, h * 0.34)
      ..lineTo(w * 0.10, h * 0.20)
      ..lineTo(w * 0.19, h * 0.31)
      ..lineTo(w * 0.30, h * 0.13)
      ..lineTo(w * 0.42, h * 0.33)
      ..lineTo(w * 0.55, h * 0.18)
      ..lineTo(w * 0.68, h * 0.34)
      ..lineTo(w * 0.80, h * 0.21)
      ..lineTo(w * 0.92, h * 0.33)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      mountains,
      Paint()..color = _tone(const Color(0xFFD9E9CE), 0.60),
    );

    // Mist band softening the horizon.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.26, w, h * 0.22),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _tone(const Color(0xFFF7FBF4), 0.72).withValues(alpha: 0.0),
            _tone(const Color(0xFFF7FBF4), 0.72).withValues(alpha: 0.55),
            _tone(const Color(0xFFF7FBF4), 0.72).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.26, w, h * 0.22)),
    );

    // Hill bands, back to front.
    _hill(canvas, size, startY: 0.42, amplitude: 0.05, phase: 0.4, color: hillBack);
    _hill(canvas, size, startY: 0.56, amplitude: 0.06, phase: 2.1, color: hillMid);
    _hill(canvas, size, startY: 0.70, amplitude: 0.07, phase: 4.3, color: hillFront);
    _hill(canvas, size, startY: 0.84, amplitude: 0.05, phase: 1.2, color: hillNear);

    // Tree clusters sitting on the middle hill.
    _treeCluster(canvas, size, x: 0.03, y: 0.50, scale: 1.0,
        dark: treeDark, light: treeLight);
    _treeCluster(canvas, size, x: 0.13, y: 0.545, scale: 0.72,
        dark: treeDark, light: treeLight);
    _treeCluster(canvas, size, x: 0.235, y: 0.52, scale: 0.55,
        dark: treeDark, light: treeLight);
    _treeCluster(canvas, size, x: 0.62, y: 0.60, scale: 0.5,
        dark: treeDark, light: treeLight, flip: true);

    // Farmhouse on the right, with a smaller outbuilding beside it.
    _farmhouse(canvas, size, x: 0.735, y: 0.615, scale: 1.0);
    _farmhouse(canvas, size, x: 0.855, y: 0.655, scale: 0.62);

    // Subtle pasture lines on the nearest hill for texture.
    final line = Paint()
      ..color = _tone(const Color(0xFF2F7A26), 0.25).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      final y = h * (0.90 + i * 0.023);
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(w * 0.5, y - h * 0.035, w, y + h * 0.01);
      canvas.drawPath(path, line);
    }
  }

  void _hill(
    Canvas canvas,
    Size size, {
    required double startY,
    required double amplitude,
    required double phase,
    required Color color,
  }) {
    final w = size.width;
    final h = size.height;
    final y0 = h * startY;

    final path = Path()..moveTo(0, y0);
    const steps = 48;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final x = t * w;
      final wave =
          math.sin(t * math.pi * 1.7 + phase) * h * amplitude +
          math.sin(t * math.pi * 3.4 + phase * 1.7) * h * amplitude * 0.36;
      path.lineTo(x, y0 + wave);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _treeCluster(
    Canvas canvas,
    Size size, {
    required double x,
    required double y,
    required double scale,
    required Color dark,
    required Color light,
    bool flip = false,
  }) {
    final w = size.width;
    final h = size.height;
    final cx = w * x;
    final baseY = h * y;
    final unit = w * 0.012 * scale;

    final trunk = Paint()
      ..color = _tone(const Color(0xFF6B5B3E), 0.3)
      ..strokeWidth = unit * 0.55
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, baseY + unit * 2.6),
      Offset(cx, baseY + unit * 0.4),
      trunk,
    );

    final canopy = Paint()..color = dark;
    final highlight = Paint()..color = light;
    final offsets = flip
        ? const [Offset(-0.9, 0.2), Offset(0.95, 0.1), Offset(0.0, -0.7)]
        : const [Offset(-1.0, 0.1), Offset(0.9, 0.25), Offset(-0.1, -0.75)];

    for (final o in offsets) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + o.dx * unit * 1.7, baseY + o.dy * unit * 1.7),
          width: unit * 3.1,
          height: unit * 2.7,
        ),
        canopy,
      );
    }
    canvas.drawCircle(
      Offset(cx + unit * 0.5, baseY - unit * 1.1),
      unit * 1.05,
      highlight,
    );
  }

  void _farmhouse(
    Canvas canvas,
    Size size, {
    required double x,
    required double y,
    required double scale,
  }) {
    final w = size.width;
    final h = size.height;
    final bodyW = w * 0.075 * scale;
    final bodyH = h * 0.115 * scale;
    final left = w * x;
    final top = h * y;

    final wall = _tone(const Color(0xFFF6EFDC), 0.26);
    final roof = _tone(const Color(0xFFBE5B45), 0.30);
    final shadow = _tone(const Color(0xFFD8CCB0), 0.28);

    // Body.
    canvas.drawRect(Rect.fromLTWH(left, top, bodyW, bodyH), Paint()..color = wall);

    // Side wall for a hint of depth.
    canvas.drawRect(
      Rect.fromLTWH(left + bodyW, top + bodyH * 0.10, bodyW * 0.30, bodyH * 0.90),
      Paint()..color = shadow,
    );

    // Gabled roof.
    final roofPath = Path()
      ..moveTo(left - bodyW * 0.10, top)
      ..lineTo(left + bodyW * 0.5, top - bodyH * 0.46)
      ..lineTo(left + bodyW * 1.10, top)
      ..lineTo(left + bodyW * 1.30, top)
      ..lineTo(left + bodyW * 0.5, top - bodyH * 0.62)
      ..lineTo(left - bodyW * 0.30, top)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = roof);

    // Door and windows.
    final opening = Paint()..color = _tone(const Color(0xFF7C6A4E), 0.28);
    canvas.drawRect(
      Rect.fromLTWH(
        left + bodyW * 0.18,
        top + bodyH * 0.52,
        bodyW * 0.24,
        bodyH * 0.48,
      ),
      opening,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        left + bodyW * 0.60,
        top + bodyH * 0.22,
        bodyW * 0.22,
        bodyH * 0.24,
      ),
      Paint()..color = _tone(const Color(0xFFDCEBF2), 0.25),
    );
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.isDark != isDark;
  }
}
