import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';

/// Figma-verified material values used by the Companion Home composition.
///
/// The Obsidian values mirror node `2:2` exactly. Pearl continues to consume
/// the shared semantic appearance tokens so this screen does not fork the
/// application's light-theme identity.
@immutable
final class CompanionHomeTokens {
  const CompanionHomeTokens({
    required this.textPrimary,
    required this.textSecondary,
    required this.glass,
    required this.borderSubtle,
    required this.ctaForeground,
    required this.lacquerHighlight,
    required this.lacquerPrimary,
    required this.lacquerMid,
    required this.lacquerDepth,
  });

  factory CompanionHomeTokens.from(ChromeKissColors colors) {
    final isObsidian =
        ThemeData.estimateBrightnessForColor(colors.canvas) == Brightness.dark;
    if (isObsidian) return obsidian;

    return CompanionHomeTokens(
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
      glass: colors.surfaceSecondary,
      borderSubtle: colors.materialChrome.withValues(alpha: 0.24),
      ctaForeground: colors.onAccent,
      lacquerHighlight: const Color(0xFFFF8CD1),
      lacquerPrimary: colors.accentPrimary,
      lacquerMid: const Color(0xFFB80A6E),
      lacquerDepth: const Color(0xFF470533),
    );
  }

  static const obsidian = CompanionHomeTokens(
    textPrimary: Color(0xFFF8F3FF),
    textSecondary: Color(0xFFC7B6D9),
    glass: Color(0xFF171222),
    borderSubtle: Color(0x3DD9D8E2),
    ctaForeground: Color(0xFFF8F3FF),
    lacquerHighlight: Color(0xFFFF8CD1),
    lacquerPrimary: Color(0xFFFF4FB8),
    lacquerMid: Color(0xFFB80A6E),
    lacquerDepth: Color(0xFF470533),
  );

  final Color textPrimary;
  final Color textSecondary;
  final Color glass;
  final Color borderSubtle;
  final Color ctaForeground;
  final Color lacquerHighlight;
  final Color lacquerPrimary;
  final Color lacquerMid;
  final Color lacquerDepth;
}

extension CompanionHomeBuildContext on BuildContext {
  CompanionHomeTokens get companionHome => CompanionHomeTokens.from(chromeKiss);
}
