import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Fixed light-theme overrides for surfaces that always sit on
/// [AppPalette.subpageBackground] — settings/help screens
/// ([SubpageScaffold]) and modal bottom sheets ([showReadableBottomSheet]).
abstract final class SubpageTheme {
  static ThemeData data(ThemeData base) {
    final linkColor = AppPalette.ensureReadableOn(
      background: AppPalette.subpageBackground,
      preferred: AppPalette.mintDark,
      minContrast: 3.0,
    );
    final subpageScheme = base.colorScheme.copyWith(
      brightness: Brightness.light,
      surface: AppPalette.subpageBackground,
      onSurface: AppPalette.subpageText,
      onSurfaceVariant: AppPalette.subpageTextMuted,
      primary: AppPalette.mintDark,
      onPrimary: AppPalette.onAccent,
    );

    return base.copyWith(
      colorScheme: subpageScheme,
      scaffoldBackgroundColor: AppPalette.subpageBackground,
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: AppPalette.subpageText,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: AppPalette.subpageText,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: AppPalette.subpageText,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: AppPalette.subpageText,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: AppPalette.subpageTextMuted,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: AppPalette.subpageTextMuted,
        ),
      ),
      iconTheme: base.iconTheme.copyWith(color: AppPalette.subpageText),
      listTileTheme: ListTileThemeData(
        iconColor: AppPalette.subpageText,
        textColor: AppPalette.subpageText,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          color: AppPalette.subpageText,
        ),
        subtitleTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: AppPalette.subpageTextMuted,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: linkColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: linkColor,
          side: BorderSide(color: linkColor.withValues(alpha: 0.65)),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: AppPalette.subpageText,
        backgroundColor: AppPalette.subpageBackground,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static Widget wrap({required BuildContext context, required Widget child}) {
    return Theme(
      data: data(Theme.of(context)),
      child: child,
    );
  }
}

/// Modal bottom sheet with readable dark-on-light text.
Future<T?> showReadableBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showDragHandle = false,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppPalette.subpageBackground,
    builder: (context) => SubpageTheme.wrap(
      context: context,
      child: builder(context),
    ),
  );
}
