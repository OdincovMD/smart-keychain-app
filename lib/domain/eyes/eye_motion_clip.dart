import 'eye_motion_transition.dart';

enum EyeMotionPlaybackMode { once, loop, pingPong }

enum EyeMotionBlinkPolicy { natural, suppress, authored }

final class EyeMotionStep {
  const EyeMotionStep({
    required this.pose,
    required this.hold,
    required this.transition,
    required this.transitionStyle,
  });

  final String pose;
  final Duration hold;
  final Duration transition;
  final EyeMotionTransitionStyle transitionStyle;

  Duration get duration => hold + transition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeMotionStep &&
          pose == other.pose &&
          hold == other.hold &&
          transition == other.transition &&
          transitionStyle == other.transitionStyle;

  @override
  int get hashCode => Object.hash(pose, hold, transition, transitionStyle);
}

final class EyeMotionClip {
  const EyeMotionClip({
    required this.name,
    required this.playbackMode,
    required this.steps,
    this.blinkPolicy = EyeMotionBlinkPolicy.natural,
  });

  final String name;
  final EyeMotionPlaybackMode playbackMode;
  final List<EyeMotionStep> steps;
  final EyeMotionBlinkPolicy blinkPolicy;

  Duration get duration =>
      steps.fold(Duration.zero, (total, step) => total + step.duration);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeMotionClip &&
          name == other.name &&
          playbackMode == other.playbackMode &&
          _listEquals(steps, other.steps) &&
          blinkPolicy == other.blinkPolicy;

  @override
  int get hashCode =>
      Object.hash(name, playbackMode, Object.hashAll(steps), blinkPolicy);
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
