import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_clip.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_transition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';

void main() {
  group('EyeMotionPlayer', () {
    test('same seed and elapsed deltas produce identical samples', () {
      final first = _player(42);
      final second = _player(42);

      for (final delta in const [
        Duration(milliseconds: 16),
        Duration(milliseconds: 37),
        Duration(milliseconds: 900),
        Duration(milliseconds: 2400),
      ]) {
        first.advance(delta);
        second.advance(delta);
        expect(first.state, second.state);
        expect(first.phase, second.phase);
      }
    });

    test('pause and resume do not advance hidden wall-clock time', () {
      final player = _player(7)..advance(const Duration(milliseconds: 700));
      final beforePause = player.state;

      player.pause();
      player.advance(const Duration(hours: 4));
      expect(player.state, beforePause);

      player.resume();
      player.advance(const Duration(milliseconds: 16));
      expect(player.elapsed, const Duration(milliseconds: 716));
    });

    test('clip interruption starts from the currently interpolated pose', () {
      final player = _player(11)..advance(const Duration(milliseconds: 1900));
      final interrupted = player.state;

      player.play(ChromeKissEyeClips.curiousFollow);
      expect(player.state, interrupted);
      player.advance(const Duration(milliseconds: 1));
      expect((player.state.gazeX - interrupted.gazeX).abs(), lessThan(0.03));
    });

    test('mood changes capture the current state and finish at new base', () {
      final player = _player(13)..advance(const Duration(milliseconds: 2100));
      final current = player.state;

      player.setMood(EyeEmotion.sleepy);
      expect(player.state, current);
      player.advance(const Duration(milliseconds: 220));
      expect(player.state.emotion, EyeEmotion.sleepy);
    });

    test('speed changes authored elapsed deterministically', () {
      final player = _player(19)..setSpeed(0.5);
      player.advance(const Duration(seconds: 2));
      expect(player.elapsed, const Duration(seconds: 1));
    });

    test('blink overlay preserves authored gaze and expression', () {
      final player = _player(23)
        ..play(ChromeKissEyeClips.curiousFollow)
        ..advance(const Duration(milliseconds: 400));
      final gazeBeforeBlink = player.state.gazeX;

      player.trigger(
        EyeBehaviourEngine(Random(23))
            .forceBlink(variant: EyeBlinkVariant.slow),
      );
      player.advance(const Duration(milliseconds: 300));

      expect(player.state.leftEyelidOpen, lessThan(0.2));
      expect(player.state.gazeX, greaterThan(0.4));
      expect((player.state.gazeX - gazeBeforeBlink).abs(), lessThan(0.2));
      expect(player.state.expressionTilt, greaterThan(0));
    });

    test('micro-saccade overlays while authored elapsed keeps advancing', () {
      final player = _player(29);
      player.trigger(
        const GazeEyeAction(
          delay: Duration.zero,
          kind: EyeGazeKind.microSaccade,
          targetX: 0.1,
          targetY: -0.05,
          anticipationX: -0.02,
          anticipationY: 0.01,
          overshootX: 0.12,
          overshootY: -0.06,
          anticipationDuration: Duration(milliseconds: 30),
          moveDuration: Duration(milliseconds: 80),
          overshootDuration: Duration(milliseconds: 35),
          settleDuration: Duration(milliseconds: 65),
          holdDuration: Duration(milliseconds: 100),
          returnDuration: Duration(milliseconds: 120),
        ),
      );
      player.advance(const Duration(milliseconds: 160));

      expect(player.elapsed, const Duration(milliseconds: 160));
      expect(player.state.gazeX, inInclusiveRange(-1, 1));
      expect(player.state.gazeY, inInclusiveRange(-1, 1));
    });
  });

  group('EyeMotionClipSampler', () {
    test('distinguishes transition and hold deterministically', () {
      final transition = _sample(
        EyeMotionPlaybackMode.once,
        const Duration(milliseconds: 50),
      );
      final hold = _sample(
        EyeMotionPlaybackMode.once,
        const Duration(milliseconds: 150),
      );

      expect(transition.phase, EyeMotionPlayerPhase.transition);
      expect(transition.state.gazeX, closeTo(0.5, 0.001));
      expect(hold.phase, EyeMotionPlayerPhase.hold);
      expect(hold.state.gazeX, 1);
    });

    test('once clamps, loop wraps, and pingPong reverses', () {
      final once = _sample(
        EyeMotionPlaybackMode.once,
        const Duration(milliseconds: 450),
      );
      final loop = _sample(
        EyeMotionPlaybackMode.loop,
        const Duration(milliseconds: 450),
      );
      final pingPong = _sample(
        EyeMotionPlaybackMode.pingPong,
        const Duration(milliseconds: 550),
      );

      expect(once.completed, isTrue);
      expect(once.state.gazeX, 0);
      expect(loop.completed, isFalse);
      expect(loop.state.gazeX, closeTo(0.5, 0.001));
      expect(pingPong.completed, isFalse);
      expect(pingPong.state.gazeX, closeTo(0.5, 0.001));
    });
  });
}

EyeMotionPlayer _player(int seed) =>
    EyeMotionPlayer(behaviourEngine: EyeBehaviourEngine(Random(seed)));

EyeMotionClipSample _sample(EyeMotionPlaybackMode mode, Duration elapsed) {
  final base = EyeRuntimeState.resting(EyeEmotion.neutral);
  final clip = EyeMotionClip(
    name: 'sample',
    playbackMode: mode,
    blinkPolicy: EyeMotionBlinkPolicy.suppress,
    steps: const [
      EyeMotionStep(
        pose: 'right',
        hold: Duration(milliseconds: 100),
        transition: Duration(milliseconds: 100),
        transitionStyle: EyeMotionTransitionStyle.linear,
      ),
      EyeMotionStep(
        pose: 'center',
        hold: Duration(milliseconds: 100),
        transition: Duration(milliseconds: 100),
        transitionStyle: EyeMotionTransitionStyle.linear,
      ),
    ],
  );
  return EyeMotionClipSampler.sample(
    definition: EyeMotionDefinition(
      poses: const {
        'right': EyeMotionPose(gazeX: 1),
        'center': EyeMotionPose(gazeX: 0),
      },
      clips: {'sample': clip},
    ),
    clip: clip,
    elapsed: elapsed,
    base: base,
    initial: base,
  );
}
