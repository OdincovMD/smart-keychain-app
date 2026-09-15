import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';

void main() {
  group('appearance resolution', () {
    test('explicit appearances ignore platform brightness', () {
      expect(
        resolveAppAppearance(AppAppearance.obsidian, Brightness.light),
        ResolvedAppAppearance.obsidian,
      );
      expect(
        resolveAppAppearance(AppAppearance.pearl, Brightness.dark),
        ResolvedAppAppearance.pearl,
      );
    });

    test('system maps platform dark to Obsidian and light to Pearl', () {
      expect(
        resolveAppAppearance(AppAppearance.system, Brightness.dark),
        ResolvedAppAppearance.obsidian,
      );
      expect(
        resolveAppAppearance(AppAppearance.system, Brightness.light),
        ResolvedAppAppearance.pearl,
      );
    });
  });

  group('Chrome Kiss semantic colors', () {
    test('Obsidian resolves the current Figma foundation values', () {
      const colors = ChromeKissColors.obsidian;

      expect(colors.canvas, const Color(0xFF09080D));
      expect(colors.lens, const Color(0xFF020205));
      expect(colors.textPrimary, const Color(0xFFF7F3F8));
      expect(colors.textSecondary, const Color(0xFFB9B0BE));
      expect(colors.textAccent, const Color(0xFFFF4FB8));
      expect(colors.accentPrimary, const Color(0xFFFF4FB8));
      expect(colors.accentOptical, const Color(0xFFC9BEFF));
      expect(colors.chromeLight, const Color(0xFFE5E2EA));
      expect(colors.chromeMid, const Color(0xFFAAA4B0));
      expect(colors.chromeDark, const Color(0xFF6A6470));
      expect(colors.materialChrome, const Color(0xFFE5E2EA));
      expect(colors.materialChampagne, const Color(0xFFD9B56D));
      expect(colors.surfaceSecondary, const Color(0xFF171222));
      expect(colors.divider, const Color(0xFF34313A));
      expect(colors.success, const Color(0xFF67DFB2));
      expect(colors.warning, const Color(0xFFF2C66D));
      expect(colors.danger, const Color(0xFFFF647C));
      expect(colors.onAccent, const Color(0xFF09080D));
    });

    test('Pearl resolves the current Figma variables', () {
      const colors = ChromeKissColors.pearl;

      expect(colors.canvas, const Color(0xFFF4F2F6));
      expect(colors.lens, const Color(0xFF020205));
      expect(colors.textPrimary, const Color(0xFF211823));
      expect(colors.textSecondary, const Color(0xFF6F5C72));
      expect(colors.textAccent, const Color(0xFFB70A6D));
      expect(colors.accentPrimary, const Color(0xFFFF4FB8));
      expect(colors.accentOptical, const Color(0xFFC9BEFF));
      expect(colors.chromeLight, const Color(0xFFF8F3FF));
      expect(colors.chromeMid, const Color(0xFFD9D8E2));
      expect(colors.chromeDark, const Color(0xFF8F8893));
      expect(colors.materialChrome, const Color(0xFF8F8893));
      expect(colors.materialChampagne, const Color(0xFF9A6F36));
      expect(colors.surfaceSecondary, const Color(0xFFEEE6EC));
      expect(colors.divider, const Color(0xFFD9D8E2));
      expect(colors.success, const Color(0xFF187A65));
      expect(colors.warning, const Color(0xFF805E00));
      expect(colors.danger, const Color(0xFFC23455));
      expect(colors.onAccent, const Color(0xFF211823));
    });

    test('the glossy companion lens is black in both appearances', () {
      expect(ChromeKissColors.obsidian.lens, const Color(0xFF020205));
      expect(ChromeKissColors.pearl.lens, ChromeKissColors.obsidian.lens);
    });

    test(
      'semantic text and essential Pearl edges meet contrast invariants',
      () {
        const obsidian = ChromeKissColors.obsidian;
        const pearl = ChromeKissColors.pearl;

        expect(
          _contrast(obsidian.textPrimary, obsidian.canvas),
          greaterThan(4.5),
        );
        expect(
          _contrast(obsidian.textSecondary, obsidian.canvas),
          greaterThan(4.5),
        );
        expect(_contrast(pearl.textPrimary, pearl.canvas), greaterThan(4.5));
        expect(_contrast(pearl.textSecondary, pearl.canvas), greaterThan(4.5));
        expect(
          _contrast(pearl.onAccent, pearl.accentPrimary),
          greaterThan(4.5),
        );
        expect(_contrast(pearl.materialChrome, pearl.canvas), greaterThan(3));
        expect(
          _contrast(pearl.accentPrimary, pearl.canvas),
          lessThan(3),
          reason: 'Hot Orchid needs a semantic edge on Pearl.',
        );
      },
    );
  });

  test('fidelity recipes resolve distinct Obsidian and Pearl materials', () {
    const obsidian = ChromeKissFidelityTheme.obsidian;
    const pearl = ChromeKissFidelityTheme.pearl;

    expect(obsidian.canvas, ChromeKissColors.obsidian.canvas);
    expect(pearl.canvas, ChromeKissColors.pearl.canvas);
    expect(obsidian.lens, pearl.lens);
    expect(obsidian.satinGradient, isNot(pearl.satinGradient));
    expect(obsidian.glass, isNot(pearl.glass));
    expect(obsidian.atmosphereOpacity, lessThan(pearl.atmosphereOpacity));
    expect(obsidian.titleStyle.fontFamily, 'CormorantGaramond');
    expect(obsidian.bodyStyle.fontFamily, 'Manrope');
    expect(obsidian.scriptStyle.fontFamily, 'GreatVibes');
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
