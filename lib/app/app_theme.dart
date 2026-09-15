import 'package:flutter/material.dart';

import 'chrome_kiss_theme.dart';

ThemeData buildAppTheme([
  ResolvedAppAppearance appearance = ResolvedAppAppearance.obsidian,
]) {
  final colors = ChromeKissColors.forAppearance(appearance);
  final brightness = switch (appearance) {
    ResolvedAppAppearance.obsidian => Brightness.dark,
    ResolvedAppAppearance.pearl => Brightness.light,
  };
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final typography = ChromeKissTypography.fromColors(colors);
  final fidelity = ChromeKissFidelityTheme.forAppearance(appearance);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: colors.accentPrimary,
        brightness: brightness,
        surface: colors.surfaceSecondary,
      ).copyWith(
        primary: colors.accentPrimary,
        onPrimary: colors.onAccent,
        secondary: colors.accentOptical,
        onSecondary: colors.lens,
        tertiary: colors.materialChampagne,
        surface: colors.surfaceSecondary,
        onSurface: colors.textPrimary,
        error: colors.danger,
        onError: colors.canvas,
        outline: colors.materialChrome,
        outlineVariant: colors.divider,
      );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.canvas,
    extensions: <ThemeExtension<dynamic>>[
      colors,
      typography,
      fidelity,
      ChromeKissMotion.standard,
    ],
    textTheme: base.textTheme
        .apply(
          fontFamily: 'Manrope',
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
        )
        .copyWith(
          displaySmall: typography.display,
          headlineMedium: typography.title,
          titleLarge: typography.body.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: typography.body,
          bodyMedium: typography.body.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: colors.textSecondary,
          ),
          labelLarge: typography.label,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.canvas,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceSecondary,
      modalBackgroundColor: colors.surfaceSecondary,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceSecondary,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: colors.divider),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.accentPrimary,
        foregroundColor: colors.onAccent,
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: typography.label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.materialChrome),
        textStyle: typography.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.textPrimary,
        textStyle: typography.label,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.textPrimary,
        minimumSize: const Size(48, 48),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.materialChrome,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: colors.materialChampagne,
      inactiveTrackColor: colors.divider,
      thumbColor: colors.materialChrome,
      overlayColor: colors.materialChampagne.withValues(alpha: 0.14),
      trackHeight: 8,
    ),
  );
}
