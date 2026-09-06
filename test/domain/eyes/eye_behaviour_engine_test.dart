import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_character.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';

void main() {
  group('EyeBehaviourEngine', () {
    test('the same seed produces the same action sequence', () {
      final first = EyeBehaviourEngine(Random(0xC0FFEE));
      final second = EyeBehaviourEngine(Random(0xC0FFEE));

      final firstActions = List.generate(80, (_) => first.nextAction());
      final secondActions = List.generate(80, (_) => second.nextAction());

      expect(firstActions, secondActions);
    });

    test('seeded fuzz keeps all generated actions inside safe bounds', () {
      for (var seed = 0; seed < 200; seed++) {
        final engine = EyeBehaviourEngine(
          Random(seed),
          initialMood: EyeEmotion.values[seed % EyeEmotion.values.length],
        );
        for (var index = 0; index < 20; index++) {
          final action = engine.nextAction();
          expect(
            action.delay.inMilliseconds,
            inInclusiveRange(
              480,
              EyeBehaviourEngine.maximumDelay.inMilliseconds,
            ),
            reason: 'seed=$seed index=$index action=$action',
          );
          if (action case GazeEyeAction()) {
            expect(action.targetX, inInclusiveRange(-1.0, 1.0));
            expect(action.targetY, inInclusiveRange(-0.62, 0.62));
            expect(action.anticipationX, inInclusiveRange(-1.0, 1.0));
            expect(action.anticipationY, inInclusiveRange(-1.0, 1.0));
            expect(action.overshootX, inInclusiveRange(-1.0, 1.0));
            expect(action.overshootY, inInclusiveRange(-0.65, 0.65));
            if (action.kind == EyeGazeKind.microSaccade) {
              expect(action.targetX.abs(), lessThanOrEqualTo(0.12));
            }
          }
          if (action case BlinkEyeAction()) {
            expect(
              action.asymmetryDelay.inMilliseconds,
              inInclusiveRange(8, 18),
            );
            expect(action.effectiveCloseDuration, greaterThan(Duration.zero));
            expect(action.effectiveOpenDuration, greaterThan(Duration.zero));
          }
        }
      }
    });

    test('a blink is forced before the no-blink window is exceeded', () {
      final engine = EyeBehaviourEngine(_AlwaysGazeRandom());

      expect(engine.nextAction(), isA<GazeEyeAction>());
      expect(engine.nextAction(), isA<BlinkEyeAction>());
    });

    test('normal, double and slow blink have distinct transitions', () {
      final engine = EyeBehaviourEngine(Random(1));
      final normal = engine.forceBlink();
      final doubleBlink = engine.forceBlink(
        variant: EyeBlinkVariant.doubleBlink,
      );
      final slow = engine.forceBlink(variant: EyeBlinkVariant.slow);

      expect(normal.count, 1);
      expect(normal.delay, Duration.zero);
      expect(doubleBlink.count, 2);
      expect(doubleBlink.isDouble, isTrue);
      expect(slow.count, 1);
      expect(
        slow.effectiveCloseDuration,
        greaterThan(normal.effectiveCloseDuration),
      );
      expect(
        slow.effectiveOpenDuration,
        greaterThan(normal.effectiveOpenDuration),
      );
    });

    test('directed gaze explicitly returns to the current mood center', () {
      final engine = EyeBehaviourEngine(
        Random(4),
        initialMood: EyeEmotion.sleepy,
      );
      final look = engine.look(EyeLookDirection.left);
      final center = engine.look(EyeLookDirection.center);

      expect(look.targetX, lessThan(0));
      expect(look.returnsToCenter, isTrue);
      expect(center.kind, EyeGazeKind.returnToCenter);
      expect(center.targetX, 0);
      expect(center.targetY, engine.moodProfile.restingGazeY);
      expect(center.returnsToCenter, isFalse);
    });

    test('mood changes expression, pace and allowed action weighting', () {
      final character = EyeCharacter.standard;
      final neutral = character.profileFor(EyeEmotion.neutral);
      final sleepy = character.profileFor(EyeEmotion.sleepy);
      final curious = character.profileFor(EyeEmotion.curious);

      expect(sleepy.openness, lessThan(neutral.openness));
      expect(sleepy.movementSpeed, lessThan(neutral.movementSpeed));
      expect(sleepy.slowBlinkWeight, greaterThan(neutral.slowBlinkWeight));
      expect(sleepy.doubleBlinkWeight, 0);
      expect(curious.gazeWeight, greaterThan(neutral.gazeWeight));

      final engine = EyeBehaviourEngine(Random(2));
      engine.setMood(EyeEmotion.annoyed);
      expect(engine.mood, EyeEmotion.annoyed);
      expect(engine.moodProfile.cornerLift, lessThan(0));
    });

    test('special action is immediate and independently triggerable', () {
      final action = EyeBehaviourEngine(Random(8))
          .playSpecialAction(EyeSpecialAction.fireflySearch);

      expect(action.delay, Duration.zero);
      expect(action.type, EyeSpecialAction.fireflySearch);
    });
  });

  group('EyeRuntimeState', () {
    test('every mood has a valid asymmetric-capable resting pose', () {
      for (final mood in EyeEmotion.values) {
        final state = EyeRuntimeState.resting(mood);
        expect(state.gazeX, inInclusiveRange(-1.0, 1.0));
        expect(state.gazeY, inInclusiveRange(-1.0, 1.0));
        expect(state.leftEyelidOpen, inOpenClosedRange(0.0, 1.0));
        expect(state.rightEyelidOpen, inOpenClosedRange(0.0, 1.0));
        expect(state.pupilScale, greaterThan(0));
        expect(state.eyeScaleX, greaterThan(0));
        expect(state.eyeScaleY, greaterThan(0));
        expect(state.motionPhase, EyeMotionPhase.idle);
      }
    });

    test('seeded interpolation never leaves runtime bounds', () {
      final random = Random(0xE1E5);
      for (var seed = 0; seed < 500; seed++) {
        final mood =
            EyeEmotion.values[random.nextInt(EyeEmotion.values.length)];
        final begin = EyeRuntimeState.resting(mood).copyWith(
          gazeX: random.nextDouble() * 2 - 1,
          gazeY: random.nextDouble() * 2 - 1,
          leftEyelidOpen: random.nextDouble(),
        );
        final end = EyeRuntimeState.resting(mood).copyWith(
          gazeX: random.nextDouble() * 2 - 1,
          gazeY: random.nextDouble() * 2 - 1,
          rightEyelidOpen: random.nextDouble(),
        );
        final state = EyeRuntimeState.lerp(begin, end, random.nextDouble());

        expect(
          state.gazeX,
          inInclusiveRange(-1.0, 1.0),
          reason: 'seed=$seed state=$state',
        );
        expect(state.gazeY, inInclusiveRange(-1.0, 1.0));
        expect(state.leftEyelidOpen, inInclusiveRange(0.0, 1.0));
        expect(state.rightEyelidOpen, inInclusiveRange(0.0, 1.0));
        expect(state.pupilScale, greaterThan(0));
      }
    });
  });
}

final class _AlwaysGazeRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => max - 1;
}
