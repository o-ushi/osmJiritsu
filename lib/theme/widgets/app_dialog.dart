import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Shows an [AlertDialog] (or any dialog content) with a contrast-safe
/// [TextButtonTheme] for its own actions — use this instead of a bare
/// `showDialog` for every dialog in this app.
///
/// A dialog's surface is pinned to [AppPalette.cardFill] (see
/// [AppTheme.light]'s `dialogTheme`). The app-wide [TextButtonTheme] is
/// tuned against [AppPalette.scene] ([AppPalette.linkOnScene]), so without
/// this override, dialog action buttons would inherit that scene-tuned
/// color. [AppPalette.linkOnCard] is the card-surface counterpart.
Future<T?> showAppAlertDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppPalette.linkOnCard),
        ),
      ),
      child: builder(context),
    ),
  );
}

/// Shows a [showDatePicker] themed against [AppPalette.cardFill], not
/// [AppPalette.scene].
///
/// The app-wide [ColorScheme] pins [ColorScheme.onSurface] to
/// [AppPalette.sceneText] for AppBars / scene-facing labels — but the date
/// picker dialog sits on the card surface, so it needs card ink instead.
/// Same class of bug as [showAppAlertDialog]; use this instead of a bare
/// `showDatePicker` everywhere in this app.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  bool Function(DateTime)? selectableDayPredicate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    selectableDayPredicate: selectableDayPredicate,
    builder: (context, child) {
      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            surface: AppPalette.cardFill,
            onSurface: AppPalette.ink,
            onSurfaceVariant: AppPalette.inkMuted,
            primary: AppPalette.mintDark,
            onPrimary: AppPalette.onAccent,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.linkOnCard,
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppPalette.cardFill,
            headerBackgroundColor: AppPalette.mintDark,
            headerForegroundColor: AppPalette.onAccent,
            dividerColor: AppPalette.cardBorder,
            weekdayStyle: TextStyle(color: AppPalette.inkMuted),
            dayStyle: TextStyle(color: AppPalette.ink),
            yearStyle: TextStyle(color: AppPalette.ink),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppPalette.onAccent;
              }
              if (states.contains(WidgetState.disabled)) {
                return AppPalette.ink.withValues(alpha: 0.38);
              }
              return AppPalette.ink;
            }),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppPalette.onAccent;
              }
              return AppPalette.mintDark;
            }),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppPalette.onAccent;
              }
              if (states.contains(WidgetState.disabled)) {
                return AppPalette.ink.withValues(alpha: 0.38);
              }
              return AppPalette.ink;
            }),
          ),
        ),
        child: child!,
      );
    },
  );
}
