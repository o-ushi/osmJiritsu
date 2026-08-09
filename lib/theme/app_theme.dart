import 'dart:math' as math;

import 'package:flutter/material.dart';

/// osmJiritsu's shared color palette and [ThemeData].
///
/// Two kinds of colors live here:
/// - **Identity** ([strength]/[opportunity]/[weakness]/[threat], [amber],
///   [coral], [overdueYellow]): SWOT-quadrant and status colors that must
///   keep a fixed meaning.
/// - **Chrome** ([scene], [mint], [cardFill], …): the app's fixed look.
class AppPalette {
  AppPalette._();

  // ── Identity ────────────────────────────────────────────────────────
  static const strength = Color(0xFF3DDC97);
  static const opportunity = Color(0xFF6FA8F5);
  static const amber = Color(0xFFFFB562);
  static const coral = Color(0xFFFF8C7F);
  static const weakness = amber;
  static const threat = coral;

  /// 案件一覧で期限切れ行を目立たせる真っ黄色。
  static const overdueYellow = Color(0xFFFFEE00);

  /// Settings/help/privacy-style screens ([SubpageScaffold]) stay on this
  /// fixed light background rather than [scene].
  ///
  /// Values below are aligned with osmGradus's shared [AppPalette] so the
  /// osm family reads as one design system.
  static const subpageBackground = Color(0xFFF2F2F7);
  static const subpageText = Color(0xFF1A1A1F);
  static const subpageTextMuted = Color(0xFF61616B);

  // ── Chrome: scene ───────────────────────────────────────────────────
  static const scene = Color(0xFF3D5993);
  static const sceneText = Color(0xFFFFFFFF);
  static const sceneTextMuted = Color(0xB3FFFFFF);

  /// Alias for [scene] — most of the app still calls it `canvas`.
  static Color get canvas => scene;

  // ── Chrome: accents & cards ─────────────────────────────────────────
  static const mint = Color(0xFF007AFF);
  static const mintDark = Color(0xFF007AFF);
  static const softBlue = Color(0xFFFF9933);
  static const softBlueDark = Color(0xFFFF9933);
  static const ink = Color(0xFF1A1A1F);
  static const inkMuted = Color(0xFF61616B);
  static const onAccent = Colors.white;

  static const cardFill = Color(0xFFFFFAF2);
  static const cardBorder = Color(0xFFF5C799);
  static const cardAccent = Color(0xFFFF9933);

  /// Links and TextButtons sitting directly on [scene].
  static const linkOnScene = Color(0xFF007AFF);

  /// Links and TextButtons sitting on [cardFill] (e.g. dialog actions).
  static const linkOnCard = Color(0xFF007AFF);

  // ── Contrast helpers ────────────────────────────────────────────────

  static const _readableDarkText = Color.fromRGBO(26, 26, 31, 1);

  static bool isLightSurface(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.light;

  static double relativeLuminance(Color color) {
    double linearize(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.r);
    final g = linearize(color.g);
    final b = linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color primaryTextOn(Color fill) {
    const light = Colors.white;
    final darkRatio = contrastRatio(fill, _readableDarkText);
    final lightRatio = contrastRatio(fill, light);
    if ((darkRatio - lightRatio).abs() < 0.35) {
      return isLightSurface(fill) ? _readableDarkText : light;
    }
    return darkRatio >= lightRatio ? _readableDarkText : light;
  }

  /// Returns [preferred] when it meets [minContrast] against [background];
  /// otherwise the higher-contrast primary text color for that background.
  static Color ensureReadableOn({
    required Color background,
    required Color preferred,
    double minContrast = 4.5,
  }) {
    if (contrastRatio(background, preferred) >= minContrast) return preferred;
    return primaryTextOn(background);
  }

  /// Scene-specific shortcut of [ensureReadableOn].
  static Color ensureReadableOnScene(
    Color preferred, {
    double minContrast = 4.5,
  }) {
    return ensureReadableOn(
      background: scene,
      preferred: preferred,
      minContrast: minContrast,
    );
  }

  static Color readableAccent(Color accent, Color surface) {
    if (isLightSurface(surface)) return accent;
    return Color.lerp(accent, Colors.white, 0.25) ?? accent;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.mintDark,
      brightness: Brightness.light,
      primary: AppPalette.mintDark,
      secondary: AppPalette.cardAccent,
      surface: AppPalette.cardFill,
    ).copyWith(
      onSurface: AppPalette.ink,
      onSurfaceVariant: AppPalette.inkMuted,
      onPrimary: AppPalette.onAccent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.canvas,
      // Default styles target card-shaped containers ([AppPalette.cardFill]).
      // Text sitting directly on [AppPalette.scene] must set
      // [AppPalette.sceneText]/[sceneTextMuted] explicitly — or inherit from
      // [ColorScheme.onSurface] via Material defaults where applicable.
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppPalette.ink,
          height: 1.3,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.ink),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppPalette.ink,
        ),
        bodyLarge: TextStyle(color: AppPalette.ink, height: 1.5),
        bodyMedium: TextStyle(color: AppPalette.inkMuted, height: 1.4),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppPalette.linkOnScene),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.linkOnScene,
          side: BorderSide(color: AppPalette.linkOnScene.withValues(alpha: 0.65)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.cardFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        // Without this, `prefixIcon` reserves Material's default 48×48
        // tap-target box around the glyph — most of it empty padding — so
        // a small icon like Icons.explore_outlined ends up with a wide gap
        // on both sides before the text even starts. Shrinking the box to
        // the icon's own size keeps `contentPadding` (above) as the only
        // left/right margin, so fields with and without a prefix icon line
        // up the same amount from each edge.
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppPalette.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppPalette.mintDark, width: 2),
        ),
        hintStyle: TextStyle(color: AppPalette.inkMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.mintDark,
          foregroundColor: AppPalette.onAccent,
          disabledBackgroundColor: const Color(0xFFD8E8E2),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      iconTheme: IconThemeData(color: AppPalette.ink),
      // AppBar is transparent, so it's the [scene] background showing
      // through behind it — its foreground needs the scene-contrast color.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPalette.sceneText,
        centerTitle: true,
      ),
      // Pinned to AppPalette.cardFill rather than Material3's own
      // auto-derived tonal surface color, so title/content text and action
      // buttons match what a dialog is actually painted on.
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.cardFill,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppPalette.ink,
        ),
        contentTextStyle: TextStyle(color: AppPalette.inkMuted, height: 1.4),
      ),
    );
  }
}
