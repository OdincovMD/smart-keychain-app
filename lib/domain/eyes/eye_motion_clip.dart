import 'eye_motion_transition.dart';

enum EyeMotionPlaybackMode { once, loop, pingPong }

enum EyeMotionBlinkPolicy { natural, suppress, authored }

final class EyeMotionBlinkConfiguration {
  const EyeMotionBlinkConfiguration({
    required this.initialDelay,
    required this.minimumInterval,
    required this.maximumInterval,
    required this.duration,
  });

  final Duration initialDelay;
  final Duration minimumInterval;
  final Duration maximumInterval;
  final Duration duration;

  Map<String, Object> toJson() => {
    'initialDelayMs': initialDelay.inMilliseconds,
    'minIntervalMs': minimumInterval.inMilliseconds,
    'maxIntervalMs': maximumInterval.inMilliseconds,
    'durationMs': duration.inMilliseconds,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeMotionBlinkConfiguration &&
          initialDelay == other.initialDelay &&
          minimumInterval == other.minimumInterval &&
          maximumInterval == other.maximumInterval &&
          duration == other.duration;

  @override
  int get hashCode =>
      Object.hash(initialDelay, minimumInterval, maximumInterval, duration);
}

final class EyeMotionClipMetadata {
  const EyeMotionClipMetadata({this.label, this.description, this.group});

  final String? label;
  final String? description;
  final String? group;

  Map<String, Object> toJson() => {
    'label': ?label,
    'description': ?description,
    'group': ?group,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeMotionClipMetadata &&
          label == other.label &&
          description == other.description &&
          group == other.group;

  @override
  int get hashCode => Object.hash(label, description, group);
}

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
    this.blinkConfiguration,
    this.metadata,
  });

  final String name;
  final EyeMotionPlaybackMode playbackMode;
  final List<EyeMotionStep> steps;
  final EyeMotionBlinkPolicy blinkPolicy;
  final EyeMotionBlinkConfiguration? blinkConfiguration;
  final EyeMotionClipMetadata? metadata;

  Duration get duration =>
      steps.fold(Duration.zero, (total, step) => total + step.duration);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeMotionClip &&
          name == other.name &&
          playbackMode == other.playbackMode &&
          _listEquals(steps, other.steps) &&
          blinkPolicy == other.blinkPolicy &&
          blinkConfiguration == other.blinkConfiguration &&
          metadata == other.metadata;

  @override
  int get hashCode => Object.hash(
    name,
    playbackMode,
    Object.hashAll(steps),
    blinkPolicy,
    blinkConfiguration,
    metadata,
  );
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
