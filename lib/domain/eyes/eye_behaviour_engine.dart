import 'dart:math';

import 'eye_character.dart';
import 'eye_emotion.dart';

enum EyeBlinkVariant { normal, doubleBlink, slow }

enum EyeGazeKind { directed, microSaccade, returnToCenter }

enum EyeLookDirection { left, right, slightlyUp, slightlyDown, center }

enum EyeSpecialAction { fireflySearch }

sealed class EyeBehaviourAction {
  const EyeBehaviourAction({required this.delay});

  final Duration delay;
}

final class IdleEyeAction extends EyeBehaviourAction {
  const IdleEyeAction({required super.delay});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IdleEyeAction && delay == other.delay;

  @override
  int get hashCode => delay.hashCode;
}

final class GazeEyeAction extends EyeBehaviourAction {
  const GazeEyeAction({
    required super.delay,
    required this.kind,
    required this.targetX,
    required this.targetY,
    required this.anticipationX,
    required this.anticipationY,
    required this.overshootX,
    required this.overshootY,
    required this.anticipationDuration,
    required this.moveDuration,
    required this.overshootDuration,
    required this.settleDuration,
    required this.holdDuration,
    required this.returnDuration,
  });

  final EyeGazeKind kind;
  final double targetX;
  final double targetY;
  final double anticipationX;
  final double anticipationY;
  final double overshootX;
  final double overshootY;
  final Duration anticipationDuration;
  final Duration moveDuration;
  final Duration overshootDuration;
  final Duration settleDuration;
  final Duration holdDuration;
  final Duration returnDuration;

  bool get returnsToCenter => kind != EyeGazeKind.returnToCenter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GazeEyeAction &&
          delay == other.delay &&
          kind == other.kind &&
          targetX == other.targetX &&
          targetY == other.targetY &&
          anticipationX == other.anticipationX &&
          anticipationY == other.anticipationY &&
          overshootX == other.overshootX &&
          overshootY == other.overshootY &&
          anticipationDuration == other.anticipationDuration &&
          moveDuration == other.moveDuration &&
          overshootDuration == other.overshootDuration &&
          settleDuration == other.settleDuration &&
          holdDuration == other.holdDuration &&
          returnDuration == other.returnDuration;

  @override
  int get hashCode => Object.hash(
    delay,
    kind,
    targetX,
    targetY,
    anticipationX,
    anticipationY,
    overshootX,
    overshootY,
    anticipationDuration,
    moveDuration,
    overshootDuration,
    settleDuration,
    holdDuration,
    returnDuration,
  );
}

final class BlinkEyeAction extends EyeBehaviourAction {
  const BlinkEyeAction({
    required super.delay,
    this.variant = EyeBlinkVariant.normal,
    this.asymmetryDelay = const Duration(milliseconds: 12),
    this.leftLeads = true,
    this.authoredDuration,
  });

  static const closeDuration = Duration(milliseconds: 86);
  static const closedDuration = Duration(milliseconds: 42);
  static const openDuration = Duration(milliseconds: 116);
  static const doubleBlinkGap = Duration(milliseconds: 135);

  final EyeBlinkVariant variant;
  final Duration asymmetryDelay;
  final bool leftLeads;
  final Duration? authoredDuration;

  bool get isDouble => variant == EyeBlinkVariant.doubleBlink;

  int get count => isDouble ? 2 : 1;

  Duration get effectiveCloseDuration => authoredDuration == null
      ? switch (variant) {
          EyeBlinkVariant.normal ||
          EyeBlinkVariant.doubleBlink => closeDuration,
          EyeBlinkVariant.slow => const Duration(milliseconds: 230),
        }
      : _authoredBlinkPart(authoredDuration!, 86);

  Duration get effectiveClosedDuration => authoredDuration == null
      ? switch (variant) {
          EyeBlinkVariant.normal ||
          EyeBlinkVariant.doubleBlink => closedDuration,
          EyeBlinkVariant.slow => const Duration(milliseconds: 90),
        }
      : _authoredBlinkPart(authoredDuration!, 42);

  Duration get effectiveOpenDuration => authoredDuration == null
      ? switch (variant) {
          EyeBlinkVariant.normal || EyeBlinkVariant.doubleBlink => openDuration,
          EyeBlinkVariant.slow => const Duration(milliseconds: 285),
        }
      : authoredDuration! -
            _authoredBlinkPart(authoredDuration!, 86) -
            _authoredBlinkPart(authoredDuration!, 42);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlinkEyeAction &&
          delay == other.delay &&
          variant == other.variant &&
          asymmetryDelay == other.asymmetryDelay &&
          leftLeads == other.leftLeads &&
          authoredDuration == other.authoredDuration;

  @override
  int get hashCode =>
      Object.hash(delay, variant, asymmetryDelay, leftLeads, authoredDuration);
}

Duration _authoredBlinkPart(Duration duration, int share) =>
    Duration(microseconds: (duration.inMicroseconds * share / 244).round());

/// One-shot original character beat: the eyes follow an imagined firefly.
final class SpecialEyeAction extends EyeBehaviourAction {
  const SpecialEyeAction({required super.delay, required this.type});

  final EyeSpecialAction type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialEyeAction && delay == other.delay && type == other.type;

  @override
  int get hashCode => Object.hash(delay, type);
}

/// Chooses character actions without depending on Flutter or wall-clock APIs.
final class EyeBehaviourEngine {
  EyeBehaviourEngine(
    this._random, {
    this.character = EyeCharacter.standard,
    EyeMood initialMood = EyeEmotion.neutral,
  }) : _mood = initialMood;

  static const minimumDelay = Duration(milliseconds: 1050);
  static const maximumDelay = Duration(milliseconds: 4800);
  static const forcedBlinkAfter = Duration(milliseconds: 7200);

  final Random _random;
  final EyeCharacter character;
  EyeMood _mood;
  Duration _timeSinceBlink = Duration.zero;

  EyeMood get mood => _mood;

  EyeMoodProfile get moodProfile => character.profileFor(_mood);

  void setMood(EyeMood mood) {
    _mood = mood;
  }

  EyeBehaviourAction nextAction() {
    final profile = moodProfile;
    final delay = _durationBetween(profile.minimumIdle, profile.maximumIdle);
    _timeSinceBlink += delay;

    if (_timeSinceBlink >= forcedBlinkAfter) {
      return forceBlink(
        variant: _mood == EyeEmotion.sleepy
            ? EyeBlinkVariant.slow
            : EyeBlinkVariant.normal,
        delay: delay,
      );
    }

    var roll = _random.nextDouble() * profile.totalActionWeight;
    if ((roll -= profile.gazeWeight) < 0) return _gaze(delay);
    if ((roll -= profile.microSaccadeWeight) < 0) {
      return _microSaccade(delay);
    }
    if ((roll -= profile.normalBlinkWeight) < 0) {
      return forceBlink(variant: EyeBlinkVariant.normal, delay: delay);
    }
    if ((roll -= profile.doubleBlinkWeight) < 0) {
      return forceBlink(variant: EyeBlinkVariant.doubleBlink, delay: delay);
    }
    if ((roll -= profile.slowBlinkWeight) < 0) {
      return forceBlink(variant: EyeBlinkVariant.slow, delay: delay);
    }
    return IdleEyeAction(delay: delay);
  }

  BlinkEyeAction forceBlink({
    EyeBlinkVariant variant = EyeBlinkVariant.normal,
    Duration delay = Duration.zero,
    Duration? duration,
  }) {
    _timeSinceBlink = Duration.zero;
    return BlinkEyeAction(
      delay: delay,
      variant: variant,
      asymmetryDelay: Duration(milliseconds: 8 + _random.nextInt(11)),
      leftLeads: _random.nextBool(),
      authoredDuration: duration,
    );
  }

  BlinkEyeAction scheduledBlink({
    required Duration minimumDelay,
    required Duration maximumDelay,
    required Duration duration,
  }) => forceBlink(
    delay: _durationBetween(minimumDelay, maximumDelay),
    duration: duration,
  );

  GazeEyeAction look(EyeLookDirection direction) {
    if (direction == EyeLookDirection.center) {
      return _createGaze(
        delay: Duration.zero,
        kind: EyeGazeKind.returnToCenter,
        targetX: 0,
        targetY: moodProfile.restingGazeY,
      );
    }
    final (x, y) = switch (direction) {
      EyeLookDirection.left => (-0.76, -0.02),
      EyeLookDirection.right => (0.76, -0.02),
      EyeLookDirection.slightlyUp => (0.12, -0.48),
      EyeLookDirection.slightlyDown => (-0.08, 0.42),
      EyeLookDirection.center => (0.0, moodProfile.restingGazeY),
    };
    return _createGaze(
      delay: Duration.zero,
      kind: EyeGazeKind.directed,
      targetX: x,
      targetY: y,
    );
  }

  SpecialEyeAction playSpecialAction(EyeSpecialAction type) {
    return SpecialEyeAction(delay: Duration.zero, type: type);
  }

  GazeEyeAction _gaze(Duration delay) {
    final directionRoll = _random.nextDouble();
    final direction = switch (directionRoll) {
      < 0.32 => EyeLookDirection.left,
      < 0.64 => EyeLookDirection.right,
      < 0.82 => EyeLookDirection.slightlyUp,
      _ => EyeLookDirection.slightlyDown,
    };
    final base = look(direction);
    final magnitude = 0.78 + _random.nextDouble() * 0.22;
    return _createGaze(
      delay: delay,
      kind: EyeGazeKind.directed,
      targetX: base.targetX * magnitude,
      targetY: base.targetY * magnitude,
    );
  }

  GazeEyeAction _microSaccade(Duration delay) {
    var x = (_random.nextDouble() * 2 - 1) * 0.12;
    var y = (_random.nextDouble() * 2 - 1) * 0.075;
    if (x.abs() + y.abs() < 0.035) x = x.isNegative ? -0.04 : 0.04;
    return _createGaze(
      delay: _durationBetween(
        const Duration(milliseconds: 480),
        delay < const Duration(milliseconds: 1100)
            ? const Duration(milliseconds: 1100)
            : delay,
      ),
      kind: EyeGazeKind.microSaccade,
      targetX: x,
      targetY: moodProfile.restingGazeY + y,
    );
  }

  GazeEyeAction _createGaze({
    required Duration delay,
    required EyeGazeKind kind,
    required double targetX,
    required double targetY,
  }) {
    final speed = moodProfile.movementSpeed;
    final isMicro = kind == EyeGazeKind.microSaccade;
    final dx = targetX;
    final dy = targetY - moodProfile.restingGazeY;
    final overshootFactor = isMicro ? 0.025 : 0.055;
    return GazeEyeAction(
      delay: delay,
      kind: kind,
      targetX: targetX.clamp(-1, 1),
      targetY: targetY.clamp(-0.62, 0.62),
      anticipationX: (-dx * 0.045).clamp(-1, 1),
      anticipationY: (moodProfile.restingGazeY - dy * 0.035).clamp(-1, 1),
      overshootX: (targetX + dx * overshootFactor).clamp(-1, 1),
      overshootY: (targetY + dy * overshootFactor).clamp(-0.65, 0.65),
      anticipationDuration: _scaled(
        Duration(milliseconds: isMicro ? 24 : 54),
        speed,
      ),
      moveDuration: _scaled(
        Duration(milliseconds: isMicro ? 92 : 235 + _random.nextInt(91)),
        speed,
      ),
      overshootDuration: _scaled(
        Duration(milliseconds: isMicro ? 32 : 58),
        speed,
      ),
      settleDuration: _scaled(Duration(milliseconds: isMicro ? 48 : 82), speed),
      holdDuration: isMicro
          ? _durationBetween(
              const Duration(milliseconds: 170),
              const Duration(milliseconds: 420),
            )
          : _durationBetween(
              const Duration(milliseconds: 520),
              const Duration(milliseconds: 1250),
            ),
      returnDuration: _scaled(
        Duration(milliseconds: isMicro ? 125 : 285 + _random.nextInt(111)),
        speed,
      ),
    );
  }

  Duration _durationBetween(Duration minimum, Duration maximum) {
    final range = maximum.inMilliseconds - minimum.inMilliseconds;
    return Duration(
      milliseconds: minimum.inMilliseconds + _random.nextInt(range + 1),
    );
  }
}

Duration _scaled(Duration duration, double speed) =>
    Duration(microseconds: (duration.inMicroseconds / speed).round());
