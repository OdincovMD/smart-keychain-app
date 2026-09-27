import 'dart:math';

import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/neutral_living_idle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Neutral Living Idle determinism', () {
    test('same seed and delta sequence produce the same 60 second trace', () {
      final first = _player(0xC0FFEE);
      final second = _player(0xC0FFEE);

      for (var frame = 0; frame < 3750; frame++) {
        const delta = Duration(milliseconds: 16);
        first.advance(delta);
        second.advance(delta);
        expect(first.state, second.state, reason: 'frame=$frame');
        expect(
          first.diagnostics.activeGesture,
          second.diagnostics.activeGesture,
          reason: 'frame=$frame',
        );
      }
      expect(first.livingIdleStatistics.gazeTransitions, greaterThan(4));
      expect(first.livingIdleStatistics.microSaccadeBursts, greaterThan(2));
      expect(_totalBlinks(first.livingIdleStatistics), greaterThan(4));
    });

    test('seed 4 has a stable 60 second behaviour summary', () {
      final player = _player(4);
      for (var frame = 0; frame < 3750; frame++) {
        player.advance(const Duration(milliseconds: 16));
      }

      final stats = player.livingIdleStatistics;
      expect(stats.gazeTransitions, 14);
      expect(stats.microSaccadeBursts, 10);
      expect(stats.naturalBlinks, 8);
      expect(stats.doubleBlinks, 1);
      expect(stats.slowBlinks, 1);
      expect(stats.signatureMoments, 2);
    });

    test('different seeds produce distinct bounded traces', () {
      final first = _player(7);
      final second = _player(42);
      var distinctFrames = 0;

      for (var frame = 0; frame < 2400; frame++) {
        const delta = Duration(milliseconds: 16);
        first.advance(delta);
        second.advance(delta);
        if (first.state != second.state) distinctFrames++;
        _expectSafe(first, reason: 'seed=7 frame=$frame');
        _expectSafe(second, reason: 'seed=42 frame=$frame');
      }

      expect(distinctFrames, greaterThan(1800));
    });

    test('planner does not repeat a short target sequence', () {
      final player = _player(314159);
      final targets = <String>[];
      var previous = '';
      for (var frame = 0; frame < 2813; frame++) {
        player.advance(const Duration(milliseconds: 16));
        final diagnostics = player.diagnostics;
        final target =
            '${diagnostics.gazeTargetX.toStringAsFixed(3)}:'
            '${diagnostics.gazeTargetY.toStringAsFixed(3)}';
        if (target != previous) {
          targets.add(target);
          previous = target;
        }
      }

      expect(targets.length, greaterThanOrEqualTo(7));
      expect(targets.toSet().length, targets.length);
      final split = targets.length ~/ 2;
      expect(
        targets.take(split),
        isNot(equals(targets.skip(split).take(split))),
      );
    });
  });

  group('Neutral Living Idle layers', () {
    test('gaze and micro-saccades stay independently bounded', () {
      final engine = EyeBehaviourEngine(Random(99));
      for (var frame = 0; frame < 20000; frame++) {
        final sample = engine.advanceLivingIdle(
          const Duration(milliseconds: 16),
        );
        expect(sample.gazeX.abs(), lessThanOrEqualTo(0.72));
        expect(sample.gazeY.abs(), lessThanOrEqualTo(0.42));
        expect(
          sample.microSaccadeX.abs(),
          lessThanOrEqualTo(NeutralLivingIdlePlanner.maximumMicroSaccade),
        );
        expect(sample.microSaccadeY.abs(), lessThanOrEqualTo(0.035));
      }
      expect(engine.livingIdleStatistics.microSaccadeBursts, greaterThan(10));
    });

    test('natural, double and slow blink profiles are distinct', () {
      final natural = _blinkTrace(EyeBlinkVariant.natural);
      final doubleBlink = _blinkTrace(EyeBlinkVariant.doubleBlink);
      final slow = _blinkTrace(EyeBlinkVariant.slow);

      expect(natural.closedRuns, 1);
      expect(doubleBlink.closedRuns, 2);
      expect(slow.closedRuns, 1);
      expect(slow.duration, greaterThan(natural.duration));
      expect(doubleBlink.duration, greaterThan(natural.duration));
      expect(natural.leftRightDifference, greaterThan(0));
    });

    test('wink never appears in ambient scheduling and works by command', () {
      final player = _player(8080);
      for (var frame = 0; frame < 22500; frame++) {
        player.advance(const Duration(milliseconds: 16));
        expect(
          player.diagnostics.activeGesture,
          isNot(EyeMotionActiveGesture.wink),
        );
      }

      final forced = _controlledPlayer(8080);
      forced.trigger(
        EyeBehaviourEngine(Random(8080))
            .forceBlink(variant: EyeBlinkVariant.wink),
      );
      var maximumDifference = 0.0;
      for (var frame = 0; frame < 50; frame++) {
        forced.advance(const Duration(milliseconds: 16));
        maximumDifference = max(
          maximumDifference,
          (forced.state.leftEyelidOpen - forced.state.rightEyelidOpen).abs(),
        );
      }
      expect(maximumDifference, greaterThan(0.7));
    });

    test('pupil micro-variation is slow and bounded', () {
      final engine = EyeBehaviourEngine(Random(17));
      var minimum = 2.0;
      var maximum = 0.0;
      var largestStep = 0.0;
      var previous = 1.0;
      for (var frame = 0; frame < 7500; frame++) {
        final frameState = engine.advanceLivingIdle(
          const Duration(milliseconds: 16),
        );
        final pupil = frameState.pupilFactor;
        minimum = min(minimum, pupil);
        maximum = max(maximum, pupil);
        largestStep = max(largestStep, (pupil - previous).abs());
        previous = pupil;
      }
      expect(minimum, greaterThanOrEqualTo(0.985));
      expect(maximum, lessThanOrEqualTo(1.015));
      expect(maximum - minimum, greaterThan(0.01));
      expect(largestStep, lessThan(0.001));
    });

    test('layer switches remove only their owned contribution', () {
      final engine = EyeBehaviourEngine(Random(23));
      engine.configureLivingIdle(
        const EyeLivingIdleConfiguration(
          ambientGaze: false,
          microSaccades: false,
          blinks: false,
          pupilVariation: false,
          controlledAsymmetry: false,
          signatureMoments: false,
        ),
      );
      for (var frame = 0; frame < 500; frame++) {
        final sample = engine.advanceLivingIdle(
          const Duration(milliseconds: 16),
        );
        expect(sample.microSaccadeX, 0);
        expect(sample.microSaccadeY, 0);
        expect(sample.leftEyelidFactor, 1);
        expect(sample.rightEyelidFactor, 1);
        expect(sample.pupilFactor, 1);
        expect(sample.leftOpennessOffset, 0);
        expect(sample.rightOpennessOffset, 0);
      }
    });
  });

  group('Neutral Living Idle interruption and safety', () {
    test('authored once clip pauses ambient and resumes without a snap', () {
      final player = _player(71);
      player.advance(const Duration(seconds: 8));
      final beforeReactionStats = player.livingIdleStatistics;

      player.play(ChromeKissEyeClips.curiousFollow);
      for (var frame = 0; frame < 120; frame++) {
        player.advance(const Duration(milliseconds: 16));
      }
      expect(
        player.livingIdleStatistics.gazeTransitions,
        beforeReactionStats.gazeTransitions,
      );

      final reactionEnd = player.state;
      player.advance(const Duration(milliseconds: 16));
      expect(player.clipName, ChromeKissEyeClips.neutralIdle);
      expect((player.state.gazeX - reactionEnd.gazeX).abs(), lessThan(0.08));
      expect((player.state.gazeY - reactionEnd.gazeY).abs(), lessThan(0.08));
    });

    test('scheduled signatures enter through the interruption blend', () {
      final player = _player(4);
      var previous = player.state;
      var foundSignature = false;
      for (var frame = 0; frame < 3750; frame++) {
        player.advance(const Duration(milliseconds: 16));
        final gesture = player.diagnostics.activeGesture;
        if (gesture == EyeMotionActiveGesture.neutralCuriousGlance ||
            gesture == EyeMotionActiveGesture.neutralSoftCenterBlink ||
            gesture == EyeMotionActiveGesture.neutralSideHoldReturn) {
          expect((player.state.gazeX - previous.gazeX).abs(), lessThan(0.08));
          expect((player.state.gazeY - previous.gazeY).abs(), lessThan(0.08));
          foundSignature = true;
          break;
        }
        previous = player.state;
      }
      expect(foundSignature, isTrue);
    });

    test('signature interruption resumes from the interpolated state', () {
      final player = _player(73)..advance(const Duration(seconds: 5));
      player.trigger(
        EyeBehaviourEngine(Random(73))
            .playSpecialAction(EyeSpecialAction.neutralSideHoldReturn),
      );
      for (var frame = 0; frame < 100; frame++) {
        player.advance(const Duration(milliseconds: 16));
      }
      final beforeResume = player.state;
      player.advance(const Duration(milliseconds: 16));
      expect((player.state.gazeX - beforeResume.gazeX).abs(), lessThan(0.08));
    });

    test('ten simulated minutes remain finite and pupil-safe', () {
      final player = _player(0x51AFE);
      var minimumPupil = 2.0;
      var maximumPupil = 0.0;
      var minimumLid = 2.0;
      var maximumLid = 0.0;
      var maximumGaze = 0.0;

      for (var frame = 0; frame < 37500; frame++) {
        player.advance(const Duration(milliseconds: 16));
        _expectSafe(player, reason: 'frame=$frame');
        final state = player.state;
        minimumPupil = min(minimumPupil, state.pupilScale);
        maximumPupil = max(maximumPupil, state.pupilScale);
        minimumLid = min(
          minimumLid,
          min(state.leftEyelidOpen, state.rightEyelidOpen),
        );
        maximumLid = max(
          maximumLid,
          max(state.leftEyelidOpen, state.rightEyelidOpen),
        );
        maximumGaze = max(
          maximumGaze,
          sqrt(state.gazeX * state.gazeX + state.gazeY * state.gazeY),
        );
      }

      expect(minimumPupil, greaterThanOrEqualTo(0.55));
      expect(maximumPupil, lessThanOrEqualTo(1.35));
      expect(minimumLid, greaterThanOrEqualTo(0));
      expect(maximumLid, lessThanOrEqualTo(1));
      expect(maximumGaze, lessThanOrEqualTo(sqrt(2)));
      final stats = player.livingIdleStatistics;
      expect(stats.gazeTransitions, greaterThan(50));
      expect(stats.microSaccadeBursts, greaterThan(30));
      expect(_totalBlinks(stats), greaterThan(40));
    });
  });
}

EyeMotionPlayer _player(int seed) => EyeMotionPlayer(
  behaviourEngine: EyeBehaviourEngine(Random(seed)),
  behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
);

EyeMotionPlayer _controlledPlayer(int seed) =>
    EyeMotionPlayer(behaviourEngine: EyeBehaviourEngine(Random(seed)));

int _totalBlinks(EyeLivingIdleStatistics statistics) =>
    statistics.naturalBlinks + statistics.doubleBlinks + statistics.slowBlinks;

void _expectSafe(EyeMotionPlayer player, {required String reason}) {
  final state = player.state;
  for (final value in <double>[
    state.gazeX,
    state.gazeY,
    state.leftEyelidOpen,
    state.rightEyelidOpen,
    state.pupilScale,
    state.eyeScaleX,
    state.eyeScaleY,
    state.expressionTilt,
    state.verticalOffset,
    state.velocityX,
    state.velocityY,
  ]) {
    expect(value.isFinite, isTrue, reason: reason);
  }
  expect(state.gazeX, inInclusiveRange(-1.0, 1.0), reason: reason);
  expect(state.gazeY, inInclusiveRange(-1.0, 1.0), reason: reason);
  expect(state.leftEyelidOpen, inInclusiveRange(0.0, 1.0), reason: reason);
  expect(state.rightEyelidOpen, inInclusiveRange(0.0, 1.0), reason: reason);
  expect(state.pupilScale, inInclusiveRange(0.55, 1.35), reason: reason);
}

({Duration duration, int closedRuns, double leftRightDifference}) _blinkTrace(
  EyeBlinkVariant variant,
) {
  final player = _controlledPlayer(101);
  player.trigger(EyeBehaviourEngine(Random(101)).forceBlink(variant: variant));
  var duration = Duration.zero;
  var closedRuns = 0;
  var wasClosed = false;
  var maximumDifference = 0.0;
  for (var frame = 0; frame < 120; frame++) {
    const delta = Duration(milliseconds: 8);
    player.advance(delta);
    duration += delta;
    final state = player.state;
    final closed = state.eyelidOpen < 0.2;
    if (closed && !wasClosed) closedRuns++;
    wasClosed = closed;
    maximumDifference = max(
      maximumDifference,
      (state.leftEyelidOpen - state.rightEyelidOpen).abs(),
    );
    if (frame > 5 &&
        player.diagnostics.activeGesture == EyeMotionActiveGesture.none) {
      break;
    }
  }
  return (
    duration: duration,
    closedRuns: closedRuns,
    leftRightDifference: maximumDifference,
  );
}
