import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.coral,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ).copyWith(
        primary: AppColors.coral,
        secondary: AppColors.mint,
        tertiary: AppColors.amber,
        onPrimary: AppColors.background,
        onSurface: AppColors.cream,
      );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme
        .apply(
          fontFamily: 'NunitoSans',
          bodyColor: AppColors.cream,
          displayColor: AppColors.cream,
        )
        .copyWith(
          displaySmall: const TextStyle(
            fontFamily: 'Fredoka',
            fontFamilyFallback: ['NunitoSans'],
            fontWeight: FontWeight.w600,
            fontSize: 40,
            height: 1.05,
            letterSpacing: -1.2,
            color: AppColors.cream,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Fredoka',
            fontFamilyFallback: ['NunitoSans'],
            fontWeight: FontWeight.w600,
            fontSize: 28,
            height: 1.12,
            color: AppColors.cream,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Fredoka',
            fontFamilyFallback: ['NunitoSans'],
            fontWeight: FontWeight.w600,
            fontSize: 21,
            color: AppColors.cream,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'NunitoSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.45,
            color: AppColors.cream,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'NunitoSans',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.45,
            color: AppColors.muted,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'NunitoSans',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'NunitoSans',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.amber,
      inactiveTrackColor: AppColors.surfaceRaised,
      thumbColor: AppColors.cream,
      overlayColor: AppColors.amber.withValues(alpha: 0.14),
      trackHeight: 8,
    ),
  );
}
