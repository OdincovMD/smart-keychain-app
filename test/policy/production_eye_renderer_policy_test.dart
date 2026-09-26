import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production code does not select legacy or reference eye renderers', () {
    const ownerAndDeveloperAllowlist = {
      'lib/features/device_home/widgets/procedural_eyes_view.dart',
      'lib/features/device_home/widgets/character_study_screen.dart',
    };
    final productionFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !ownerAndDeveloperAllowlist.contains(file.path));
    final bannedSelections = [
      RegExp(r'EyeRendererVariant\.legacy\b'),
      RegExp(r'EyeRendererVariant\.kissCutV2\b'),
      RegExp(r'EyeRendererVariant\.figmaJewelry\b'),
    ];

    for (final file in productionFiles) {
      final source = file.readAsStringSync();
      for (final selection in bannedSelections) {
        expect(
          selection.hasMatch(source),
          isFalse,
          reason: '${file.path} selects non-production renderer $selection',
        );
      }
    }
  });

  test(
    'legacy companion identity assets stay off production identity surfaces',
    () {
      // Scene content assets are the real pixels applied to the device and are
      // allowed in production. Companion identity previews are presentation;
      // they must use the shared Kiss Cut V2.1 renderer instead of baked legacy
      // anatomy. This list intentionally does not ban assets/scenes/** or user
      // image paths.
      const legacyCompanionIdentityAssets = {
        'assets/chrome_kiss/home_look_original.png',
        'assets/chrome_kiss/home_look_mint.png',
        'assets/chrome_kiss/home_look_lilac.png',
        'assets/chrome_kiss/wardrobe_current_look.png',
        'assets/chrome_kiss/appearance_preview_obsidian.png',
        'assets/chrome_kiss/appearance_preview_pearl.png',
        'assets/chrome_kiss/appearance_preview_system.png',
        'assets/chrome_kiss/create_preview_original.png',
        'assets/chrome_kiss/create_preview_mint.png',
        'assets/chrome_kiss/create_preview_lilac.png',
        'assets/chrome_kiss/eye_left_figma.png',
        'assets/chrome_kiss/eye_right_figma.png',
      };
      const referenceRendererAllowlist = {
        'lib/features/device_home/widgets/figma_kiss_cut_eyes_view.dart',
      };
      final productionFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in productionFiles) {
        final source = file.readAsStringSync();
        for (final asset in legacyCompanionIdentityAssets) {
          if (!source.contains(asset)) continue;
          expect(
            referenceRendererAllowlist.contains(file.path),
            isTrue,
            reason:
                '${file.path} reuses legacy companion identity asset $asset. '
                'Render identity with Kiss Cut V2.1; keep real scene/user '
                'content assets unchanged.',
          );
        }
      }
    },
  );
}
