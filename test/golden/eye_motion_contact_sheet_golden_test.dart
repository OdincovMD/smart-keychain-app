@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

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

  final production = _productionDefinition();
  for (final clipName in ChromeKissProductionEyeClips.values) {
    for (final size in [240.0, 64.0]) {
      testWidgets('$clipName production contact sheet at ${size.toInt()} px', (
        tester,
      ) async {
        final frames = _productionFrames(production, clipName);
        final width = size * frames.length + 16 * (frames.length + 1);
        tester.view
          ..physicalSize = Size(width, size + 56)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ColoredBox(
              key: Key('${clipName}_contact_sheet'),
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
          find.byKey(Key('${clipName}_contact_sheet')),
          matchesGoldenFile(
            'baselines/production_${clipName.replaceAll('-', '_')}_contact_sheet_${size.toInt()}.png',
          ),
        );
      });
    }
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

EyeMotionDefinition _productionDefinition() {
  final decoded = decodeEyeMotionDefinition(
    File(BundledEyeMotionDefinitionLoader.productionAssetPath)
        .readAsStringSync(),
  );
  return switch (decoded) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError(
      'Production motion fixture failed to decode: ${failure.code}',
    ),
  };
}

List<({String label, EyeRuntimeState state})> _productionFrames(
  EyeMotionDefinition definition,
  String clipName,
) {
  final base = EyeRuntimeState.resting(EyeEmotion.neutral);
  final clip = definition.clips[clipName]!;
  final first = clip.steps.first;
  final second = clip.steps[1];
  EyeRuntimeState sample(Duration elapsed) => EyeMotionClipSampler.sample(
    definition: definition,
    clip: clip,
    elapsed: elapsed,
    base: base,
    initial: base,
  ).state;

  final blink = EyeMotionPlayer(
    behaviourEngine: EyeBehaviourEngine(Random(0xC1A0)),
    definition: definition,
    initialClip: clipName,
  );
  final blinkConfiguration = clip.blinkConfiguration!;
  blink
    ..advance(blinkConfiguration.initialDelay)
    ..advance(
      Duration(microseconds: blinkConfiguration.duration.inMicroseconds ~/ 3),
    );

  final firstDuration = first.transition + first.hold;
  return [
    (label: 'START', state: sample(Duration.zero)),
    (label: 'TARGET 1', state: sample(first.transition)),
    (
      label: 'TRANSITION',
      state: sample(firstDuration + second.transition ~/ 2),
    ),
    (
      label: 'HOLD',
      state: sample(firstDuration + second.transition + second.hold ~/ 2),
    ),
    (label: 'TARGET 2', state: sample(firstDuration + second.transition)),
    (label: 'BLINK', state: blink.state),
    (label: 'LOOP', state: sample(clip.duration)),
  ];
}
