import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_clip.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_transition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

void main() {
  late EyeMotionDefinition definition;

  setUpAll(() {
    final decoded = decodeEyeMotionDefinition(
      File(BundledEyeMotionDefinitionLoader.productionAssetPath)
          .readAsStringSync(),
    );
    expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
    definition = (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>).value;
  });

  test('production asset decodes with only project-owned pose references', () {
    expect(definition.clips.keys, ChromeKissProductionEyeClips.values);
    expect(definition.poses.keys, everyElement(startsWith('ck_')));
    for (final clip in definition.clips.values) {
      expect(
        clip.steps.map((step) => step.pose),
        everyElement(allOf(startsWith('ck_'), isIn(definition.poses.keys))),
      );
    }
  });

  test('kiss-idle preserves the authored timeline and blink settings', () {
    final clip = definition.clips[ChromeKissProductionEyeClips.kissIdle]!;

    expect(clip.playbackMode, EyeMotionPlaybackMode.loop);
    expect(clip.steps, const [
      EyeMotionStep(
        pose: 'ck_idle_notice',
        hold: Duration(milliseconds: 2600),
        transition: Duration(milliseconds: 750),
        transitionStyle: EyeMotionTransitionStyle.easeInOut,
      ),
      EyeMotionStep(
        pose: 'ck_rest',
        hold: Duration(milliseconds: 3400),
        transition: Duration(milliseconds: 900),
        transitionStyle: EyeMotionTransitionStyle.easeInOut,
      ),
    ]);
    expect(
      clip.blinkConfiguration,
      const EyeMotionBlinkConfiguration(
        initialDelay: Duration(milliseconds: 1800),
        minimumInterval: Duration(milliseconds: 3200),
        maximumInterval: Duration(milliseconds: 5800),
        duration: Duration(milliseconds: 240),
      ),
    );
    expect(
      clip.metadata,
      const EyeMotionClipMetadata(
        label: 'Kiss Idle',
        description: 'Slow living-eye drift with relaxed randomized blinking.',
        group: 'Cycle de vie',
      ),
    );
  });

  test('kiss-flirty-scan preserves authored timeline and blink settings', () {
    final clip = definition.clips[ChromeKissProductionEyeClips.kissFlirtyScan]!;

    expect(clip.playbackMode, EyeMotionPlaybackMode.loop);
    expect(
      clip.steps.map(
        (step) => (
          step.pose,
          step.hold.inMilliseconds,
          step.transition.inMilliseconds,
          step.transitionStyle,
        ),
      ),
      const [
        ('ck_flirty_open', 1200, 320, EyeMotionTransitionStyle.easeInOut),
        ('ck_flirty_wide', 850, 260, EyeMotionTransitionStyle.easeInOut),
        ('ck_flirty_up', 650, 220, EyeMotionTransitionStyle.easeInOut),
        ('ck_flirty_return', 1350, 360, EyeMotionTransitionStyle.easeInOut),
      ],
    );
    expect(
      clip.blinkConfiguration,
      const EyeMotionBlinkConfiguration(
        initialDelay: Duration(milliseconds: 900),
        minimumInterval: Duration(milliseconds: 2400),
        maximumInterval: Duration(milliseconds: 4600),
        duration: Duration(milliseconds: 220),
      ),
    );
    expect(
      clip.metadata,
      const EyeMotionClipMetadata(
        label: 'Kiss Flirty Scan',
        description: 'Asymmetric curious scan with a playful return to center.',
        group: 'Réactions',
      ),
    );
  });

  test('loop boundaries are continuous', () {
    final base = EyeRuntimeState.resting(EyeEmotion.neutral);
    for (final clip in definition.clips.values) {
      final before = EyeMotionClipSampler.sample(
        definition: definition,
        clip: clip,
        elapsed: clip.duration - const Duration(milliseconds: 1),
        base: base,
        initial: base,
      ).state;
      final boundary = EyeMotionClipSampler.sample(
        definition: definition,
        clip: clip,
        elapsed: clip.duration,
        base: base,
        initial: base,
      ).state;

      expect(
        _maximumDelta(before, boundary),
        lessThan(0.01),
        reason: clip.name,
      );
    }
  });
}

double _maximumDelta(EyeRuntimeState first, EyeRuntimeState second) {
  final deltas = [
    (first.gazeX - second.gazeX).abs(),
    (first.gazeY - second.gazeY).abs(),
    (first.leftEyelidOpen - second.leftEyelidOpen).abs(),
    (first.rightEyelidOpen - second.rightEyelidOpen).abs(),
    (first.pupilScale - second.pupilScale).abs(),
    (first.eyeScaleX - second.eyeScaleX).abs(),
    (first.eyeScaleY - second.eyeScaleY).abs(),
    (first.expressionTilt - second.expressionTilt).abs(),
    (first.verticalOffset - second.verticalOffset).abs(),
  ];
  return deltas.reduce((maximum, value) => value > maximum ? value : maximum);
}
