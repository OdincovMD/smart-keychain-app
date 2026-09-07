import 'package:flutter/material.dart';

import '../domain/settings/app_appearance.dart';

enum ResolvedAppAppearance { obsidian, pearl }

ResolvedAppAppearance resolveAppAppearance(
  AppAppearance appearance,
  Brightness platformBrightness,
) {
  return switch (appearance) {
    AppAppearance.obsidian => ResolvedAppAppearance.obsidian,
    AppAppearance.pearl => ResolvedAppAppearance.pearl,
    AppAppearance.system =>
      platformBrightness == Brightness.dark
          ? ResolvedAppAppearance.obsidian
          : ResolvedAppAppearance.pearl,
  };
}

ThemeMode themeModeFor(AppAppearance appearance) {
  return switch (appearance) {
    AppAppearance.obsidian => ThemeMode.dark,
    AppAppearance.pearl => ThemeMode.light,
    AppAppearance.system => ThemeMode.system,
  };
}

@immutable
final class ChromeKissColors extends ThemeExtension<ChromeKissColors> {
  const ChromeKissColors({
    required this.canvas,
    required this.lens,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentPrimary,
    required this.accentOptical,
    required this.materialChrome,
    required this.materialChampagne,
    required this.surfaceSecondary,
    required this.divider,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onAccent,
  });

  static const obsidian = ChromeKissColors(
    canvas: Color(0xFF0B0A0F),
    lens: Color(0xFF020205),
    textPrimary: Color(0xFFF8F4FA),
    textSecondary: Color(0xFFAAA5B3),
    accentPrimary: Color(0xFFFF4FB8),
    accentOptical: Color(0xFFC9BEFF),
    materialChrome: Color(0xFFD9D8E2),
    materialChampagne: Color(0xFFE7C98B),
    surfaceSecondary: Color(0xFF17161C),
    divider: Color(0xFF34313A),
    success: Color(0xFF67DFB2),
    warning: Color(0xFFF2C66D),
    danger: Color(0xFFFF647C),
    onAccent: Color(0xFF0B0A0F),
  );

  static const pearl = ChromeKissColors(
    canvas: Color(0xFFF8F2F6),
    lens: Color(0xFF020205),
    textPrimary: Color(0xFF241A22),
    textSecondary: Color(0xFF655A63),
    accentPrimary: Color(0xFFFF4FB8),
    accentOptical: Color(0xFFC9BEFF),
    materialChrome: Color(0xFF8F8893),
    materialChampagne: Color(0xFF9A6F36),
    surfaceSecondary: Color(0xFFEEE6EC),
    divider: Color(0xFFCFC5CD),
    success: Color(0xFF187A65),
    warning: Color(0xFF805E00),
    danger: Color(0xFFC23455),
    onAccent: Color(0xFF241A22),
  );

  static ChromeKissColors forAppearance(ResolvedAppAppearance appearance) {
    return switch (appearance) {
      ResolvedAppAppearance.obsidian => obsidian,
      ResolvedAppAppearance.pearl => pearl,
    };
  }

  final Color canvas;
  final Color lens;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentPrimary;
  final Color accentOptical;
  final Color materialChrome;
  final Color materialChampagne;
  final Color surfaceSecondary;
  final Color divider;
  final Color success;
  final Color warning;
  final Color danger;
  final Color onAccent;

  @override
  ChromeKissColors copyWith({
    Color? canvas,
    Color? lens,
    Color? textPrimary,
    Color? textSecondary,
    Color? accentPrimary,
    Color? accentOptical,
    Color? materialChrome,
    Color? materialChampagne,
    Color? surfaceSecondary,
    Color? divider,
    Color? success,
    Color? warning,
    Color? danger,
    Color? onAccent,
  }) {
    return ChromeKissColors(
      canvas: canvas ?? this.canvas,
      lens: lens ?? this.lens,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentOptical: accentOptical ?? this.accentOptical,
      materialChrome: materialChrome ?? this.materialChrome,
      materialChampagne: materialChampagne ?? this.materialChampagne,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  ChromeKissColors lerp(ChromeKissColors? other, double t) {
    if (other == null) return this;
    return ChromeKissColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      lens: Color.lerp(lens, other.lens, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentOptical: Color.lerp(accentOptical, other.accentOptical, t)!,
      materialChrome: Color.lerp(materialChrome, other.materialChrome, t)!,
      materialChampagne: Color.lerp(
        materialChampagne,
        other.materialChampagne,
        t,
      )!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

@immutable
final class ChromeKissTypography extends ThemeExtension<ChromeKissTypography> {
  const ChromeKissTypography({
    required this.display,
    required this.title,
    required this.body,
    required this.label,
    required this.status,
  });

  factory ChromeKissTypography.fromColors(ChromeKissColors colors) {
    return ChromeKissTypography(
      display: TextStyle(
        fontFamily: 'Unbounded',
        fontFamilyFallback: const ['Manrope', 'NunitoSans'],
        fontWeight: FontWeight.w600,
        fontSize: 40,
        height: 1.08,
        letterSpacing: -1.05,
        color: colors.textPrimary,
      ),
      title: TextStyle(
        fontFamily: 'Unbounded',
        fontFamilyFallback: const ['Manrope', 'NunitoSans'],
        fontWeight: FontWeight.w600,
        fontSize: 26,
        height: 1.16,
        letterSpacing: -0.45,
        color: colors.textPrimary,
      ),
      body: TextStyle(
        fontFamily: 'Manrope',
        fontFamilyFallback: const ['NunitoSans'],
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.45,
        color: colors.textPrimary,
      ),
      label: TextStyle(
        fontFamily: 'Manrope',
        fontFamilyFallback: const ['NunitoSans'],
        fontWeight: FontWeight.w700,
        fontSize: 15,
        height: 1.2,
        color: colors.textPrimary,
      ),
      status: TextStyle(
        fontFamily: 'Manrope',
        fontFamilyFallback: const ['NunitoSans'],
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        height: 1.25,
        letterSpacing: 0.35,
        color: colors.textSecondary,
      ),
    );
  }

  final TextStyle display;
  final TextStyle title;
  final TextStyle body;
  final TextStyle label;
  final TextStyle status;

  @override
  ChromeKissTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? status,
  }) {
    return ChromeKissTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      status: status ?? this.status,
    );
  }

  @override
  ChromeKissTypography lerp(ChromeKissTypography? other, double t) {
    if (other == null) return this;
    return ChromeKissTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      status: TextStyle.lerp(status, other.status, t)!,
    );
  }
}

@immutable
final class ChromeKissMotionToken {
  const ChromeKissMotionToken({required this.duration, required this.curve});

  final Duration duration;
  final Curve curve;
}

@immutable
final class ChromeKissMotion extends ThemeExtension<ChromeKissMotion> {
  const ChromeKissMotion({
    required this.micro,
    required this.interaction,
    required this.transition,
    required this.delight,
  });

  static const standard = ChromeKissMotion(
    micro: ChromeKissMotionToken(
      duration: Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
    ),
    interaction: ChromeKissMotionToken(
      duration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    ),
    transition: ChromeKissMotionToken(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    ),
    delight: ChromeKissMotionToken(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    ),
  );

  final ChromeKissMotionToken micro;
  final ChromeKissMotionToken interaction;
  final ChromeKissMotionToken transition;
  final ChromeKissMotionToken delight;

  @override
  ChromeKissMotion copyWith({
    ChromeKissMotionToken? micro,
    ChromeKissMotionToken? interaction,
    ChromeKissMotionToken? transition,
    ChromeKissMotionToken? delight,
  }) {
    return ChromeKissMotion(
      micro: micro ?? this.micro,
      interaction: interaction ?? this.interaction,
      transition: transition ?? this.transition,
      delight: delight ?? this.delight,
    );
  }

  @override
  ChromeKissMotion lerp(ChromeKissMotion? other, double t) {
    if (other == null || t < 0.5) return this;
    return other;
  }
}

extension ChromeKissBuildContext on BuildContext {
  ChromeKissColors get chromeKiss {
    return Theme.of(this).extension<ChromeKissColors>() ??
        (throw StateError('ChromeKissColors is missing from ThemeData.'));
  }

  ChromeKissTypography get chromeKissText {
    return Theme.of(this).extension<ChromeKissTypography>() ??
        (throw StateError('ChromeKissTypography is missing from ThemeData.'));
  }

  ChromeKissMotion get chromeKissMotion {
    return Theme.of(this).extension<ChromeKissMotion>() ??
        (throw StateError('ChromeKissMotion is missing from ThemeData.'));
  }
}
