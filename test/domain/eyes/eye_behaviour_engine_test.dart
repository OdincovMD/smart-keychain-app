import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';

void main() {
  group('EyeBehaviourEngine', () {
    test('the same seed produces the same action sequence', () {
      final first = EyeBehaviourEngine(Random(0xC0FFEE));
      final second = EyeBehaviourEngine(Random(0xC0FFEE));

      final firstActions = List.generate(40, (_) => first.nextAction());
      final secondActions = List.generate(40, (_) => second.nextAction());

      expect(firstActions, secondActions);
    });

    test('generated actions stay inside documented bounds', () {
      final engine = EyeBehaviourEngine(Random(42));

      for (var seed = 0; seed < 500; seed++) {
        final action = engine.nextAction();
        expect(
          action.delay.inMilliseconds,
          inInclusiveRange(
            EyeBehaviourEngine.minimumDelay.inMilliseconds,
            EyeBehaviourEngine.maximumDelay.inMilliseconds,
          ),
          reason: 'seed=$seed action=$action',
        );
        if (action case GazeEyeAction()) {
          expect(action.targetX, inInclusiveRange(-1.0, 1.0));
          expect(action.targetY, inInclusiveRange(-0.55, 0.55));
          expect(action.targetX.abs(), greaterThanOrEqualTo(0.45));
          expect(
            action.moveDuration.inMilliseconds,
            inInclusiveRange(220, 320),
          );
          expect(
            action.holdDuration.inMilliseconds,
            inInclusiveRange(450, 1100),
          );
          expect(
            action.returnDuration.inMilliseconds,
            inInclusiveRange(260, 360),
          );
        }
      }
    });

    test('a blink is forced before the no-blink window is exceeded', () {
      final engine = EyeBehaviourEngine(_AlwaysGazeRandom());

      expect(engine.nextAction(), isA<GazeEyeAction>());
      expect(engine.nextAction(), isA<BlinkEyeAction>());
    });

    test('manual blink is immediate and single', () {
      final action = EyeBehaviourEngine(Random(1)).forceBlink();

      expect(action.delay, Duration.zero);
      expect(action.isDouble, isFalse);
    });
  });

  group('EyeRuntimeState', () {
    test('every emotion has a valid open resting pose', () {
      for (final emotion in EyeEmotion.values) {
        final state = EyeRuntimeState.resting(emotion);
        expect(state.gazeX, inInclusiveRange(-1.0, 1.0));
        expect(state.gazeY, inInclusiveRange(-1.0, 1.0));
        expect(state.eyelidOpen, inOpenClosedRange(0.0, 1.0));
        expect(state.pupilScale, greaterThan(0));
      }
    });

    test('seeded interpolation never leaves runtime bounds', () {
      final random = Random(0xE1E5);
      for (var seed = 0; seed < 500; seed++) {
        final emotion =
            EyeEmotion.values[random.nextInt(EyeEmotion.values.length)];
        final begin = EyeRuntimeState.resting(emotion).copyWith(
          gazeX: random.nextDouble() * 2 - 1,
          gazeY: random.nextDouble() * 2 - 1,
        );
        final end = EyeRuntimeState.resting(emotion).copyWith(
          gazeX: random.nextDouble() * 2 - 1,
          gazeY: random.nextDouble() * 2 - 1,
          eyelidOpen: random.nextDouble(),
        );
        final state = EyeRuntimeState.lerp(begin, end, random.nextDouble());

        expect(
          state.gazeX,
          inInclusiveRange(-1.0, 1.0),
          reason: 'seed=$seed state=$state',
        );
        expect(state.gazeY, inInclusiveRange(-1.0, 1.0));
        expect(state.eyelidOpen, inInclusiveRange(0.0, 1.0));
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
