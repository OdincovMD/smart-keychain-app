import 'dart:math' as math;

import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apply Look eye reaction', () {
    test('same seed and delta sequence produce the same reaction trace', () {
      final first = _reactionTrace(seed: 4);
      final second = _reactionTrace(seed: 4);

      expect(second, first);
    });

    test('applying settles once and freezes ambient for a long operation', () {
      final player = _player();
      _advance(player, const Duration(seconds: 3));
      final before = player.livingIdleStatistics;

      expect(player.startApplyReaction(EyeApplyReaction.applying), isTrue);
      _advance(player, const Duration(milliseconds: 700));
      final waiting = player.state;
      _advance(player, const Duration(seconds: 30));

      expect(player.state, waiting);
      final after = player.livingIdleStatistics;
      expect(
        (
          after.gazeTransitions,
          after.microSaccadeBursts,
          after.naturalBlinks,
          after.doubleBlinks,
          after.slowBlinks,
          after.signatureMoments,
        ),
        (
          before.gazeTransitions,
          before.microSaccadeBursts,
          before.naturalBlinks,
          before.doubleBlinks,
          before.slowBlinks,
          before.signatureMoments,
        ),
      );
      expect(player.diagnostics.reactionPhase, EyeApplyReactionPhase.waiting);
      expect(player.diagnostics.ambientSuspended, isTrue);
    });

    test('success interrupts from the current pose and returns to ambient', () {
      final player = _player();
      player.startApplyReaction(EyeApplyReaction.applying);
      _advance(player, const Duration(milliseconds: 800));
      final before = player.state;

      expect(player.startApplyReaction(EyeApplyReaction.success), isTrue);
      player.advance(const Duration(milliseconds: 16));

      expect(_poseDistance(before, player.state), lessThan(0.15));
      _advance(player, const Duration(seconds: 2));
      expect(player.diagnostics.activeReaction, isNull);
      expect(player.diagnostics.ambientSuspended, isFalse);
      expect(player.diagnostics.priority, EyeReactionPriority.ambient);
    });

    test('failure has no presentation glint and returns without a snap', () {
      final player = _player();
      player.startApplyReaction(EyeApplyReaction.applying);
      _advance(player, const Duration(milliseconds: 800));
      final before = player.state;
      player.startApplyReaction(EyeApplyReaction.failure);

      var maximumGlint = 0.0;
      for (var i = 0; i < 90; i++) {
        player.advance(const Duration(milliseconds: 16));
        maximumGlint = math.max(
          maximumGlint,
          player.diagnostics.presentationGlint,
        );
        _expectSafe(player);
      }

      expect(maximumGlint, 0);
      expect(_poseDistance(before, player.state), lessThan(1.8));
      expect(player.diagnostics.activeReaction, isNull);
    });

    test('retry may interrupt failure but not a connection recovery hold', () {
      final player = _player();
      player.startApplyReaction(EyeApplyReaction.applying);
      _advance(player, const Duration(milliseconds: 700));
      player.startApplyReaction(EyeApplyReaction.failure);
      _advance(player, const Duration(milliseconds: 220));
      final failurePose = player.state;

      expect(
        player.startApplyReaction(EyeApplyReaction.retryApplying, retry: true),
        isTrue,
      );
      player.advance(const Duration(milliseconds: 16));
      expect(_poseDistance(failurePose, player.state), lessThan(0.4));

      expect(
        player.holdForeground(EyeReactionPriority.connectionRecovery),
        isTrue,
      );
      expect(
        player.startApplyReaction(EyeApplyReaction.retryApplying, retry: true),
        isFalse,
      );
      expect(
        player.diagnostics.priority,
        EyeReactionPriority.connectionRecovery,
      );

      expect(
        player.holdForeground(EyeReactionPriority.intentionalExit),
        isTrue,
      );
      expect(player.startApplyReaction(EyeApplyReaction.success), isFalse);
      expect(player.diagnostics.priority, EyeReactionPriority.intentionalExit);
    });

    test('reduced motion uses stable poses without an advancing clock', () {
      final player = _player();
      for (final reaction in const [
        EyeApplyReaction.applying,
        EyeApplyReaction.success,
        EyeApplyReaction.failure,
      ]) {
        player.showReducedMotionApplyReaction(reaction);
        final pose = player.state;
        player.advance(const Duration(seconds: 30));
        expect(player.state, pose, reason: reaction.name);
        expect(player.status, EyeMotionPlaybackStatus.stopped);
        _expectSafe(player);
      }
    });

    test('all reaction samples remain finite and inside safety bounds', () {
      for (final reaction in EyeApplyReaction.values) {
        final player = _player();
        player.startApplyReaction(
          reaction,
          retry: reaction == EyeApplyReaction.retryApplying,
        );
        for (var i = 0; i < 600; i++) {
          player.advance(const Duration(milliseconds: 16));
          _expectSafe(player);
        }
      }
    });
  });
}

EyeMotionPlayer _player({int seed = 4}) => EyeMotionPlayer(
  behaviourEngine: EyeBehaviourEngine(
    math.Random(seed),
    initialMood: EyeEmotion.neutral,
  ),
  definition: chromeKissEyeMotionDefinition,
  initialMood: EyeEmotion.neutral,
  behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
);

List<String> _reactionTrace({required int seed}) {
  final player = _player(seed: seed);
  player.startApplyReaction(EyeApplyReaction.applying);
  final result = <String>[];
  for (var frame = 0; frame < 240; frame++) {
    if (frame == 45) player.startApplyReaction(EyeApplyReaction.success);
    player.advance(const Duration(microseconds: 33333));
    if (frame % 3 != 0) continue;
    final state = player.state;
    final diagnostics = player.diagnostics;
    result.add(
      '${state.gazeX.toStringAsFixed(6)}|'
      '${state.gazeY.toStringAsFixed(6)}|'
      '${state.leftEyelidOpen.toStringAsFixed(6)}|'
      '${state.rightEyelidOpen.toStringAsFixed(6)}|'
      '${state.pupilScale.toStringAsFixed(6)}|'
      '${diagnostics.activeReaction?.name}|'
      '${diagnostics.reactionPhase.name}',
    );
  }
  return result;
}

void _advance(EyeMotionPlayer player, Duration duration) {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    const step = Duration(milliseconds: 16);
    player.advance(step);
    elapsed += step;
  }
}

double _poseDistance(EyeRuntimeState left, EyeRuntimeState right) =>
    (left.gazeX - right.gazeX).abs() +
    (left.gazeY - right.gazeY).abs() +
    (left.leftEyelidOpen - right.leftEyelidOpen).abs() +
    (left.rightEyelidOpen - right.rightEyelidOpen).abs() +
    (left.pupilScale - right.pupilScale).abs();

void _expectSafe(EyeMotionPlayer player) {
  final state = player.state;
  expect(
    [
      state.gazeX,
      state.gazeY,
      state.leftEyelidOpen,
      state.rightEyelidOpen,
      state.pupilScale,
      state.expressionTilt,
    ].every((value) => value.isFinite),
    isTrue,
  );
  expect(state.gazeX, inInclusiveRange(-1, 1));
  expect(state.gazeY, inInclusiveRange(-1, 1));
  expect(state.leftEyelidOpen, inInclusiveRange(0, 1));
  expect(state.rightEyelidOpen, inInclusiveRange(0, 1));
  expect(state.pupilScale, inInclusiveRange(0.55, 1.35));
}
