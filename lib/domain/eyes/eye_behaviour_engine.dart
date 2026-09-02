import 'dart:math';

sealed class EyeBehaviourAction {
  const EyeBehaviourAction({required this.delay});

  final Duration delay;
}

final class GazeEyeAction extends EyeBehaviourAction {
  const GazeEyeAction({
    required super.delay,
    required this.targetX,
    required this.targetY,
    required this.moveDuration,
    required this.holdDuration,
    required this.returnDuration,
  });

  final double targetX;
  final double targetY;
  final Duration moveDuration;
  final Duration holdDuration;
  final Duration returnDuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GazeEyeAction &&
          delay == other.delay &&
          targetX == other.targetX &&
          targetY == other.targetY &&
          moveDuration == other.moveDuration &&
          holdDuration == other.holdDuration &&
          returnDuration == other.returnDuration;

  @override
  int get hashCode => Object.hash(
    delay,
    targetX,
    targetY,
    moveDuration,
    holdDuration,
    returnDuration,
  );
}

final class BlinkEyeAction extends EyeBehaviourAction {
  const BlinkEyeAction({required super.delay, required this.isDouble});

  static const closeDuration = Duration(milliseconds: 85);
  static const closedDuration = Duration(milliseconds: 45);
  static const openDuration = Duration(milliseconds: 110);
  static const doubleBlinkGap = Duration(milliseconds: 120);

  final bool isDouble;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlinkEyeAction &&
          delay == other.delay &&
          isDouble == other.isDouble;

  @override
  int get hashCode => Object.hash(delay, isDouble);
}

final class EyeBehaviourEngine {
  EyeBehaviourEngine(this._random);

  static const minimumDelay = Duration(milliseconds: 1200);
  static const maximumDelay = Duration(milliseconds: 3600);
  static const forcedBlinkAfter = Duration(milliseconds: 6500);

  final Random _random;
  Duration _timeSinceBlink = Duration.zero;

  EyeBehaviourAction nextAction() {
    final delay = _durationBetween(minimumDelay, maximumDelay);
    _timeSinceBlink += delay;

    if (_timeSinceBlink >= forcedBlinkAfter) {
      _timeSinceBlink = Duration.zero;
      return BlinkEyeAction(delay: delay, isDouble: false);
    }

    final roll = _random.nextDouble();
    if (roll < 0.55) return _gaze(delay);

    _timeSinceBlink = Duration.zero;
    return BlinkEyeAction(delay: delay, isDouble: roll >= 0.9);
  }

  BlinkEyeAction forceBlink() {
    _timeSinceBlink = Duration.zero;
    return const BlinkEyeAction(delay: Duration.zero, isDouble: false);
  }

  GazeEyeAction _gaze(Duration delay) {
    final direction = _random.nextBool() ? 1.0 : -1.0;
    final magnitude = 0.45 + _random.nextDouble() * 0.55;
    return GazeEyeAction(
      delay: delay,
      targetX: direction * magnitude,
      targetY: -0.55 + _random.nextDouble() * 1.1,
      moveDuration: _durationBetween(
        const Duration(milliseconds: 220),
        const Duration(milliseconds: 320),
      ),
      holdDuration: _durationBetween(
        const Duration(milliseconds: 450),
        const Duration(milliseconds: 1100),
      ),
      returnDuration: _durationBetween(
        const Duration(milliseconds: 260),
        const Duration(milliseconds: 360),
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
