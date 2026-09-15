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
    required this.textAccent,
    required this.accentPrimary,
    required this.accentOptical,
    required this.chromeLight,
    required this.chromeMid,
    required this.chromeDark,
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
    canvas: Color(0xFF09080D),
    lens: Color(0xFF020205),
    textPrimary: Color(0xFFF7F3F8),
    textSecondary: Color(0xFFB9B0BE),
    textAccent: Color(0xFFFF4FB8),
    accentPrimary: Color(0xFFFF4FB8),
    accentOptical: Color(0xFFC9BEFF),
    chromeLight: Color(0xFFE5E2EA),
    chromeMid: Color(0xFFAAA4B0),
    chromeDark: Color(0xFF6A6470),
    materialChrome: Color(0xFFE5E2EA),
    materialChampagne: Color(0xFFD9B56D),
    surfaceSecondary: Color(0xFF171222),
    divider: Color(0xFF34313A),
    success: Color(0xFF67DFB2),
    warning: Color(0xFFF2C66D),
    danger: Color(0xFFFF647C),
    onAccent: Color(0xFF09080D),
  );

  static const pearl = ChromeKissColors(
    canvas: Color(0xFFF4F2F6),
    lens: Color(0xFF020205),
    textPrimary: Color(0xFF211823),
    textSecondary: Color(0xFF6F5C72),
    textAccent: Color(0xFFB70A6D),
    accentPrimary: Color(0xFFFF4FB8),
    accentOptical: Color(0xFFC9BEFF),
    chromeLight: Color(0xFFF8F3FF),
    chromeMid: Color(0xFFD9D8E2),
    chromeDark: Color(0xFF8F8893),
    materialChrome: Color(0xFF8F8893),
    materialChampagne: Color(0xFF9A6F36),
    surfaceSecondary: Color(0xFFEEE6EC),
    divider: Color(0xFFD9D8E2),
    success: Color(0xFF187A65),
    warning: Color(0xFF805E00),
    danger: Color(0xFFC23455),
    onAccent: Color(0xFF211823),
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
  final Color textAccent;
  final Color accentPrimary;
  final Color accentOptical;
  final Color chromeLight;
  final Color chromeMid;
  final Color chromeDark;
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
    Color? textAccent,
    Color? accentPrimary,
    Color? accentOptical,
    Color? chromeLight,
    Color? chromeMid,
    Color? chromeDark,
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
      textAccent: textAccent ?? this.textAccent,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentOptical: accentOptical ?? this.accentOptical,
      chromeLight: chromeLight ?? this.chromeLight,
      chromeMid: chromeMid ?? this.chromeMid,
      chromeDark: chromeDark ?? this.chromeDark,
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
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentOptical: Color.lerp(accentOptical, other.accentOptical, t)!,
      chromeLight: Color.lerp(chromeLight, other.chromeLight, t)!,
      chromeMid: Color.lerp(chromeMid, other.chromeMid, t)!,
      chromeDark: Color.lerp(chromeDark, other.chromeDark, t)!,
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
        fontFamily: 'CormorantGaramond',
        fontFamilyFallback: const ['Manrope', 'NunitoSans'],
        fontWeight: FontWeight.w500,
        fontSize: 40,
        height: 1.08,
        letterSpacing: -1.05,
        color: colors.textPrimary,
      ),
      title: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontFamilyFallback: const ['Manrope', 'NunitoSans'],
        fontWeight: FontWeight.w500,
        fontSize: 30,
        height: 32 / 30,
        letterSpacing: 0,
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

/// Theme-resolved material recipes for the Figma-fidelity product surfaces.
///
/// Geometry remains in `ChromeKissFidelityTokens`; this extension owns every
/// appearance-dependent color, gradient, shadow, and text color used by the
/// Wardrobe and Create Look compositions.
@immutable
final class ChromeKissFidelityTheme
    extends ThemeExtension<ChromeKissFidelityTheme> {
  const ChromeKissFidelityTheme({
    required this.outside,
    required this.canvas,
    required this.ink,
    required this.mutedInk,
    required this.accentInk,
    required this.lacquer,
    required this.lacquerDeep,
    required this.lens,
    required this.chromeLine,
    required this.specular,
    required this.glass,
    required this.controlSurface,
    required this.lensBorder,
    required this.shadow,
    required this.atmosphereOpacity,
    required this.satinGradient,
    required this.lacquerGradient,
    required this.lensGradient,
    required this.uploadTargetGradient,
    required this.disabledActionGradient,
  });

  static const obsidian = ChromeKissFidelityTheme(
    outside: Color(0xFF09080D),
    canvas: Color(0xFF09080D),
    ink: Color(0xFFF7F3F8),
    mutedInk: Color(0xFFB9B0BE),
    accentInk: Color(0xFFFF4FB8),
    lacquer: Color(0xFFFF4FB8),
    lacquerDeep: Color(0xFF470533),
    lens: Color(0xFF020205),
    chromeLine: Color(0x3DE5E2EA),
    specular: Color(0xFFF7F3F8),
    glass: Color(0xFF171222),
    controlSurface: Color(0xFF171222),
    lensBorder: Color(0xFF302A3C),
    shadow: Color(0xB3020205),
    atmosphereOpacity: 0.34,
    satinGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF211A2A),
        Color(0xFF16111F),
        Color(0xFF100D17),
        Color(0xFF1D1725),
        Color(0xFF14101C),
      ],
      stops: [0, 0.28, 0.52, 0.76, 1],
    ),
    lacquerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF8CD1),
        Color(0xFFFF4FB8),
        Color(0xFFB80A6E),
        Color(0xFF470533),
      ],
      stops: [0, 0.34, 0.7, 1],
    ),
    lensGradient: LinearGradient(
      begin: Alignment(-0.7, -1),
      end: Alignment(0.8, 1),
      colors: [
        Color(0xFF291F3D),
        Color(0xFF030308),
        Color(0xFF0D081A),
        Color(0xFF381433),
      ],
      stops: [0.146, 0.344, 0.656, 0.854],
    ),
    uploadTargetGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF171122), Color(0xFF020205)],
    ),
    disabledActionGradient: LinearGradient(
      colors: [Color(0xFF4B3B4A), Color(0xFF241C27)],
    ),
  );

  static const pearl = ChromeKissFidelityTheme(
    outside: Color(0xFFE5E5E5),
    canvas: Color(0xFFF4F2F6),
    ink: Color(0xFF211823),
    mutedInk: Color(0xFF6F5C72),
    accentInk: Color(0xFFB70A6D),
    lacquer: Color(0xFFFF4FB8),
    lacquerDeep: Color(0xFF470533),
    lens: Color(0xFF020205),
    chromeLine: Color(0xFFD9D8E2),
    specular: Color(0xFFF8F3FF),
    glass: Color(0xD1FFFFFF),
    controlSurface: Color(0xCCFFFFFF),
    lensBorder: Color(0xFF302A3C),
    shadow: Color(0x33211823),
    atmosphereOpacity: 1,
    satinGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFBF8F7),
        Color(0xFFF2EFF5),
        Color(0xFFE7E3ED),
        Color(0xFFFAF7F4),
        Color(0xFFEDE5ED),
      ],
      stops: [0, 0.28, 0.52, 0.76, 1],
    ),
    lacquerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF8CD1),
        Color(0xFFFF4FB8),
        Color(0xFFB80A6E),
        Color(0xFF470533),
      ],
      stops: [0, 0.34, 0.7, 1],
    ),
    lensGradient: LinearGradient(
      begin: Alignment(-0.7, -1),
      end: Alignment(0.8, 1),
      colors: [
        Color(0xFF291F3D),
        Color(0xFF030308),
        Color(0xFF0D081A),
        Color(0xFF381433),
      ],
      stops: [0.146, 0.344, 0.656, 0.854],
    ),
    uploadTargetGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF1EDF4)],
    ),
    disabledActionGradient: LinearGradient(
      colors: [Color(0xFFCB9AB8), Color(0xFF84536F)],
    ),
  );

  static ChromeKissFidelityTheme forAppearance(
    ResolvedAppAppearance appearance,
  ) {
    return switch (appearance) {
      ResolvedAppAppearance.obsidian => obsidian,
      ResolvedAppAppearance.pearl => pearl,
    };
  }

  final Color outside;
  final Color canvas;
  final Color ink;
  final Color mutedInk;
  final Color accentInk;
  final Color lacquer;
  final Color lacquerDeep;
  final Color lens;
  final Color chromeLine;
  final Color specular;
  final Color glass;
  final Color controlSurface;
  final Color lensBorder;
  final Color shadow;
  final double atmosphereOpacity;
  final LinearGradient satinGradient;
  final LinearGradient lacquerGradient;
  final LinearGradient lensGradient;
  final LinearGradient uploadTargetGradient;
  final LinearGradient disabledActionGradient;

  TextStyle get titleStyle => TextStyle(
    color: ink,
    fontFamily: 'CormorantGaramond',
    fontSize: 30,
    height: 32 / 30,
    fontWeight: FontWeight.w500,
  );

  TextStyle get scriptStyle => TextStyle(
    color: accentInk,
    fontFamily: 'GreatVibes',
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
  );

  TextStyle get bodyStyle => TextStyle(
    color: ink,
    fontFamily: 'Manrope',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  List<BoxShadow> get primaryActionShadows => [
    BoxShadow(
      color: chromeLine.withValues(alpha: 0.22),
      offset: const Offset(0, 14),
      blurRadius: 36,
    ),
    BoxShadow(color: lacquer.withValues(alpha: 0.34), blurRadius: 24),
  ];

  @override
  ChromeKissFidelityTheme copyWith({
    Color? outside,
    Color? canvas,
    Color? ink,
    Color? mutedInk,
    Color? accentInk,
    Color? lacquer,
    Color? lacquerDeep,
    Color? lens,
    Color? chromeLine,
    Color? specular,
    Color? glass,
    Color? controlSurface,
    Color? lensBorder,
    Color? shadow,
    double? atmosphereOpacity,
    LinearGradient? satinGradient,
    LinearGradient? lacquerGradient,
    LinearGradient? lensGradient,
    LinearGradient? uploadTargetGradient,
    LinearGradient? disabledActionGradient,
  }) {
    return ChromeKissFidelityTheme(
      outside: outside ?? this.outside,
      canvas: canvas ?? this.canvas,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      accentInk: accentInk ?? this.accentInk,
      lacquer: lacquer ?? this.lacquer,
      lacquerDeep: lacquerDeep ?? this.lacquerDeep,
      lens: lens ?? this.lens,
      chromeLine: chromeLine ?? this.chromeLine,
      specular: specular ?? this.specular,
      glass: glass ?? this.glass,
      controlSurface: controlSurface ?? this.controlSurface,
      lensBorder: lensBorder ?? this.lensBorder,
      shadow: shadow ?? this.shadow,
      atmosphereOpacity: atmosphereOpacity ?? this.atmosphereOpacity,
      satinGradient: satinGradient ?? this.satinGradient,
      lacquerGradient: lacquerGradient ?? this.lacquerGradient,
      lensGradient: lensGradient ?? this.lensGradient,
      uploadTargetGradient: uploadTargetGradient ?? this.uploadTargetGradient,
      disabledActionGradient:
          disabledActionGradient ?? this.disabledActionGradient,
    );
  }

  @override
  ChromeKissFidelityTheme lerp(ChromeKissFidelityTheme? other, double t) {
    if (other == null) return this;
    return ChromeKissFidelityTheme(
      outside: Color.lerp(outside, other.outside, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      lacquer: Color.lerp(lacquer, other.lacquer, t)!,
      lacquerDeep: Color.lerp(lacquerDeep, other.lacquerDeep, t)!,
      lens: Color.lerp(lens, other.lens, t)!,
      chromeLine: Color.lerp(chromeLine, other.chromeLine, t)!,
      specular: Color.lerp(specular, other.specular, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      controlSurface: Color.lerp(controlSurface, other.controlSurface, t)!,
      lensBorder: Color.lerp(lensBorder, other.lensBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      atmosphereOpacity:
          atmosphereOpacity + (other.atmosphereOpacity - atmosphereOpacity) * t,
      satinGradient:
          Gradient.lerp(satinGradient, other.satinGradient, t)!
              as LinearGradient,
      lacquerGradient:
          Gradient.lerp(lacquerGradient, other.lacquerGradient, t)!
              as LinearGradient,
      lensGradient:
          Gradient.lerp(lensGradient, other.lensGradient, t)! as LinearGradient,
      uploadTargetGradient:
          Gradient.lerp(uploadTargetGradient, other.uploadTargetGradient, t)!
              as LinearGradient,
      disabledActionGradient:
          Gradient.lerp(
                disabledActionGradient,
                other.disabledActionGradient,
                t,
              )!
              as LinearGradient,
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

  ChromeKissFidelityTheme get chromeKissFidelity {
    return Theme.of(this).extension<ChromeKissFidelityTheme>() ??
        (throw StateError(
          'ChromeKissFidelityTheme is missing from ThemeData.',
        ));
  }
}
