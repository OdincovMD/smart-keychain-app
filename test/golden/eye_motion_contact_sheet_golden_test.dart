@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);
  for (final size in [240.0, 64.0]) {
    testWidgets('authored motion contact sheet at ${size.toInt()} px', (
      tester,
    ) async {
      final frames = _frames();
      final width = size * frames.length + 16 * (frames.length + 1);
      tester.view
        ..physicalSize = Size(width, size + 56)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(
            key: const Key('eye_motion_contact_sheet'),
            color: const Color(0xFF08070D),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final frame in frames)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: size,
                        child: KissCutEyesView(
                          state: frame.state,
                          style: KissCutRendererStyle.v21OpticalGlint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        frame.label,
                        style: TextStyle(
                          color: const Color(0xFFF7EAF3),
                          fontFamily: 'NunitoSans',
                          fontSize: size == 64 ? 8 : 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(const Key('eye_motion_contact_sheet')),
        matchesGoldenFile(
          'baselines/eye_motion_contact_sheet_${size.toInt()}.png',
        ),
      );
    });
  }
}

List<({String label, EyeRuntimeState state})> _frames() {
  final base = EyeRuntimeState.resting(EyeEmotion.neutral);
  EyeRuntimeState sample(String clip, int milliseconds) =>
      EyeMotionClipSampler.sample(
        definition: chromeKissEyeMotionDefinition,
        clip: chromeKissEyeMotionDefinition.clips[clip]!,
        elapsed: Duration(milliseconds: milliseconds),
        base: base,
        initial: base,
      ).state;
  return [
    (label: 'REST', state: base),
    (label: 'BREATHE', state: sample(ChromeKissEyeClips.neutralIdle, 1900)),
    (label: 'CURIOUS A', state: sample(ChromeKissEyeClips.curiousFollow, 85)),
    (label: 'CURIOUS B', state: sample(ChromeKissEyeClips.curiousFollow, 390)),
    (label: 'FLIRTY A', state: sample(ChromeKissEyeClips.flirtyGlance, 220)),
    (label: 'FLIRTY B', state: sample(ChromeKissEyeClips.flirtyGlance, 780)),
  ];
}
