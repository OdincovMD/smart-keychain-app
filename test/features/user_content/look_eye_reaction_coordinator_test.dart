import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/features/user_content/look_application_controller.dart';
import 'package:smart_keychain_app/features/user_content/look_eye_reaction_coordinator.dart';

void main() {
  group('LookEyeReactionCoordinator', () {
    test('emits applying intent once for repeated applying status', () {
      final rig = _Rig();

      rig.coordinator.sync(
        LookApplicationStatus.applying,
        reducedMotion: false,
      );
      rig.coordinator.sync(
        LookApplicationStatus.applying,
        reducedMotion: false,
      );

      expect(rig.refreshCount, 1);
      expect(rig.player.diagnostics.activeReaction, EyeApplyReaction.applying);
    });

    test('maps applied only after the controller publishes applied', () {
      final rig = _Rig();
      rig.coordinator.sync(
        LookApplicationStatus.applying,
        reducedMotion: false,
      );

      expect(rig.player.diagnostics.activeReaction, EyeApplyReaction.applying);
      rig.coordinator.sync(LookApplicationStatus.applied, reducedMotion: false);

      expect(rig.player.diagnostics.activeReaction, EyeApplyReaction.success);
      expect(rig.refreshCount, 2);
    });

    test('failure never maps to success and retry starts a new apply', () {
      final rig = _Rig();
      rig.coordinator
        ..sync(LookApplicationStatus.applying, reducedMotion: false)
        ..sync(LookApplicationStatus.failed, reducedMotion: false);

      expect(rig.player.diagnostics.activeReaction, EyeApplyReaction.failure);
      rig.coordinator.sync(
        LookApplicationStatus.applying,
        reducedMotion: false,
      );

      expect(
        rig.player.diagnostics.activeReaction,
        EyeApplyReaction.retryApplying,
      );
      expect(rig.player.diagnostics.presentationGlint, 0);
    });

    test(
      'reduced motion publishes a stable pose and no playing clock state',
      () {
        final rig = _Rig();

        rig.coordinator.sync(
          LookApplicationStatus.applied,
          reducedMotion: true,
        );

        expect(rig.player.status, EyeMotionPlaybackStatus.stopped);
        expect(
          rig.player.diagnostics.reactionPhase,
          EyeApplyReactionPhase.confirmation,
        );
      },
    );

    test('dispose clears only the owned apply foreground action', () {
      final rig = _Rig();
      rig.coordinator.sync(
        LookApplicationStatus.applying,
        reducedMotion: false,
      );

      rig.coordinator.dispose();
      rig.coordinator.sync(LookApplicationStatus.applied, reducedMotion: false);

      expect(rig.player.diagnostics.activeReaction, isNull);
      expect(rig.player.diagnostics.priority, EyeReactionPriority.ambient);
      expect(rig.refreshCount, 1);
    });

    test('dispose is safe after the presentation source is gone', () {
      final player = _Rig().player
        ..startApplyReaction(EyeApplyReaction.applying);
      final coordinator = LookEyeReactionCoordinator(
        player: player,
        refresh: () => throw StateError('disposed presentation source'),
      );

      expect(coordinator.dispose, returnsNormally);
      expect(player.diagnostics.activeReaction, isNull);
    });
  });
}

final class _Rig {
  _Rig()
    : player = EyeMotionPlayer(
        behaviourEngine: EyeBehaviourEngine(
          math.Random(4),
          initialMood: EyeEmotion.neutral,
        ),
        initialMood: EyeEmotion.neutral,
        behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
      ) {
    coordinator = LookEyeReactionCoordinator(
      player: player,
      refresh: () => refreshCount++,
    );
  }

  final EyeMotionPlayer player;
  late final LookEyeReactionCoordinator coordinator;
  var refreshCount = 0;
}
