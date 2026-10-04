import '../../domain/eyes/eye_behaviour_engine.dart';
import '../../domain/eyes/eye_motion_player.dart';
import 'look_application_controller.dart';

/// Feature adapter from Look Application lifecycle state to the eye domain.
///
/// It owns no clock and no animation state. Repeated provider emissions are
/// deliberately ignored; all choreography is sampled by the shared player.
final class LookEyeReactionCoordinator {
  LookEyeReactionCoordinator({required this.player, required this.refresh});

  final EyeMotionPlayer player;
  final void Function() refresh;
  LookApplicationStatus? _lastStatus;
  bool? _lastReducedMotion;
  var _disposed = false;

  LookApplicationStatus? get lastStatus => _lastStatus;

  void sync(LookApplicationStatus status, {required bool reducedMotion}) {
    if (_disposed ||
        (_lastStatus == status && _lastReducedMotion == reducedMotion)) {
      return;
    }
    final previous = _lastStatus;
    _lastStatus = status;
    _lastReducedMotion = reducedMotion;

    if (status == LookApplicationStatus.ready) {
      player.clearApplyReaction();
      refresh();
      return;
    }

    final reaction = switch (status) {
      LookApplicationStatus.applying =>
        previous == LookApplicationStatus.failed
            ? EyeApplyReaction.retryApplying
            : EyeApplyReaction.applying,
      LookApplicationStatus.applied => EyeApplyReaction.success,
      LookApplicationStatus.failed => EyeApplyReaction.failure,
      LookApplicationStatus.ready => throw StateError('Handled above.'),
    };
    if (reducedMotion) {
      player.showReducedMotionApplyReaction(reaction);
    } else {
      player.startApplyReaction(
        reaction,
        retry: previous == LookApplicationStatus.failed,
      );
    }
    refresh();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    player.clearApplyReaction();
  }
}
