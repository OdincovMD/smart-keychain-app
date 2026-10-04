import 'dart:convert';

import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/features/user_content/look_application_controller.dart';

import 'neutral_realtime_capture.dart';

const applyLookCaptureSeed = 4;
const applyLookCaptureSpeed = 1.0;

const applyLookSuccessSpec = NeutralCaptureSpec(
  name: 'apply-look-success-closeup-seed-4',
  width: 240,
  height: 240,
  framesPerSecond: 30,
  duration: Duration(seconds: 6),
);

const applyLookFailureRetrySpec = NeutralCaptureSpec(
  name: 'apply-look-failure-retry-seed-4',
  width: 240,
  height: 240,
  framesPerSecond: 30,
  duration: Duration(seconds: 6),
);

const applyLookLifecycleSpec = NeutralCaptureSpec(
  name: 'apply-look-lifecycle-390x844-seed-4',
  width: 390,
  height: 844,
  framesPerSecond: 15,
  duration: Duration(seconds: 6),
);

final class ApplyLookTraceBuilder {
  ApplyLookTraceBuilder({required this.spec});

  final NeutralCaptureSpec spec;
  final List<Map<String, Object?>> _samples = [];
  final List<Map<String, Object?>> _moments = [];
  EyeApplyReaction? _previousReaction;
  EyeApplyReactionPhase _previousPhase = EyeApplyReactionPhase.none;

  List<Map<String, Object?>> get samples => List.unmodifiable(_samples);

  void sample(
    EyeMotionPlayer player,
    Duration time,
    LookApplicationStatus applicationStatus,
  ) {
    final state = player.state;
    final diagnostics = player.diagnostics;
    if (diagnostics.activeReaction != _previousReaction ||
        diagnostics.reactionPhase != _previousPhase) {
      _moments.add({
        'timeMs': time.inMilliseconds,
        'reaction': diagnostics.activeReaction?.name ?? 'none',
        'phase': diagnostics.reactionPhase.name,
      });
    }
    _previousReaction = diagnostics.activeReaction;
    _previousPhase = diagnostics.reactionPhase;
    _samples.add({
      'timeMs': time.inMilliseconds,
      'applicationStatus': applicationStatus.name,
      'reaction': diagnostics.activeReaction?.name ?? 'none',
      'reactionPhase': diagnostics.reactionPhase.name,
      'priority': diagnostics.priority.name,
      'interruption': diagnostics.interruptionInProgress,
      'playerPhase': diagnostics.playerPhase.name,
      'gazeX': _rounded(state.gazeX),
      'gazeY': _rounded(state.gazeY),
      'leftEyelid': _rounded(state.leftEyelidOpen),
      'rightEyelid': _rounded(state.rightEyelidOpen),
      'pupilScale': _rounded(state.pupilScale),
      'mood': player.mood.name,
      'ambientSuspended': diagnostics.ambientSuspended,
      'activeGesture': diagnostics.activeGesture.name,
      'glint': _rounded(diagnostics.presentationGlint),
    });
  }

  Map<String, Object?> build() => {
    'metadata': {
      'seed': applyLookCaptureSeed,
      'speed': applyLookCaptureSpeed,
      'fps': spec.framesPerSecond,
      'durationMs': spec.duration.inMilliseconds,
      'frameCount': spec.frameCount,
      'frameTimestampRule': 'floor(frameIndex * 1000000 / fps)',
      'runtimeVersion': 'apply-look-eye-reaction-v1',
      'runtimeMode': 'EyeMotionPlayer.neutralLivingIdle+applyForeground',
      'renderer': 'Kiss Cut V2.1 production + reaction lens glint',
      'captureFormat': 'animated-gif-fallback-no-ffmpeg',
      'reactionMoments': _moments,
      'stateTraceDigest': fnv1a64(jsonEncode(_samples)),
    },
    'samples': _samples,
  };
}

double _rounded(double value) => (value * 100000).round() / 100000;
