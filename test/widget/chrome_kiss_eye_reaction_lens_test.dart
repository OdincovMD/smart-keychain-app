import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_eye_reaction_lens.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';

void main() {
  for (final appearance in ResolvedAppAppearance.values) {
    for (final lensSize in ChromeKissEyeReactionLensSize.values) {
      testWidgets(
        '${lensSize.name} reaction lens clips V2.1 eyes in ${appearance.name}',
        (tester) async {
          const reactionKey = Key('reaction_eyes');
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(appearance),
              home: Scaffold(
                body: Center(
                  child: ChromeKissEyeReactionLens(
                    key: const Key('reaction_lens'),
                    reactionKey: reactionKey,
                    size: lensSize,
                    mood: KissCutVisualMood.neutral,
                    animate: false,
                    useProductionMotion: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(
            tester.getSize(find.byKey(const Key('reaction_lens'))),
            lensSize.outerSize,
          );
          expect(
            find.byKey(Key('chrome_kiss_reaction_lens_clip_${lensSize.name}')),
            findsOneWidget,
          );
          final eyes = tester.widget<ChromeKissProductionEyes>(
            find.byKey(reactionKey),
          );
          expect(eyes.scale, lensSize.eyeScale);
          expect(eyes.mood, KissCutVisualMood.neutral);
          expect(eyes.animate, isFalse);
          expect(eyes.background, ChromeKissEyeBackground.transparent);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
