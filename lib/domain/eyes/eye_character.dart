import 'eye_emotion.dart';

/// Immutable personality tuning for the procedural eye character.
final class EyeCharacter {
  const EyeCharacter();

  static const standard = EyeCharacter();

  EyeMoodProfile profileFor(EyeMood mood) {
    return switch (mood) {
      EyeEmotion.neutral => const EyeMoodProfile(
        openness: 0.92,
        pupilScale: 1,
        eyeScale: 1,
        movementSpeed: 1,
        minimumIdle: Duration(milliseconds: 1350),
        maximumIdle: Duration(milliseconds: 3900),
        gazeWeight: 0.38,
        microSaccadeWeight: 0.17,
        normalBlinkWeight: 0.24,
        doubleBlinkWeight: 0.06,
        slowBlinkWeight: 0.04,
        idleWeight: 0.11,
      ),
      EyeEmotion.happy => const EyeMoodProfile(
        openness: 0.72,
        pupilScale: 1.04,
        eyeScale: 1.01,
        cornerLift: 0.1,
        verticalOffset: -0.0101,
        movementSpeed: 1.08,
        minimumIdle: Duration(milliseconds: 1200),
        maximumIdle: Duration(milliseconds: 3400),
        gazeWeight: 0.4,
        microSaccadeWeight: 0.17,
        normalBlinkWeight: 0.2,
        doubleBlinkWeight: 0.09,
        slowBlinkWeight: 0.03,
        idleWeight: 0.11,
      ),
      EyeEmotion.sleepy => const EyeMoodProfile(
        openness: 0.43,
        pupilScale: 0.9,
        eyeScale: 0.98,
        cornerLift: -0.035,
        verticalOffset: 0.0202,
        restingGazeY: 0.2,
        movementSpeed: 0.72,
        minimumIdle: Duration(milliseconds: 1800),
        maximumIdle: Duration(milliseconds: 4800),
        gazeWeight: 0.2,
        microSaccadeWeight: 0.11,
        normalBlinkWeight: 0.21,
        doubleBlinkWeight: 0,
        slowBlinkWeight: 0.25,
        idleWeight: 0.21,
      ),
      EyeEmotion.curious => const EyeMoodProfile(
        openness: 0.96,
        pupilScale: 1.08,
        eyeScale: 1.03,
        cornerLift: 0.025,
        restingGazeY: -0.06,
        movementSpeed: 1.15,
        minimumIdle: Duration(milliseconds: 1050),
        maximumIdle: Duration(milliseconds: 3000),
        gazeWeight: 0.47,
        microSaccadeWeight: 0.2,
        normalBlinkWeight: 0.16,
        doubleBlinkWeight: 0.07,
        slowBlinkWeight: 0,
        idleWeight: 0.08,
      ),
      EyeEmotion.annoyed => const EyeMoodProfile(
        openness: 0.63,
        pupilScale: 0.94,
        eyeScale: 1,
        cornerLift: -0.085,
        verticalOffset: 0.0051,
        movementSpeed: 0.88,
        minimumIdle: Duration(milliseconds: 1650),
        maximumIdle: Duration(milliseconds: 4300),
        gazeWeight: 0.29,
        microSaccadeWeight: 0.13,
        normalBlinkWeight: 0.24,
        doubleBlinkWeight: 0.03,
        slowBlinkWeight: 0.12,
        idleWeight: 0.19,
      ),
      EyeEmotion.surprised => const EyeMoodProfile(
        openness: 1,
        pupilScale: 0.78,
        eyeScale: 1.08,
        movementSpeed: 1.2,
        minimumIdle: Duration(milliseconds: 1250),
        maximumIdle: Duration(milliseconds: 3200),
        gazeWeight: 0.43,
        microSaccadeWeight: 0.2,
        normalBlinkWeight: 0.18,
        doubleBlinkWeight: 0.05,
        slowBlinkWeight: 0.02,
        idleWeight: 0.12,
      ),
    };
  }
}

/// Mood-dependent behaviour and expression parameters.
final class EyeMoodProfile {
  const EyeMoodProfile({
    required this.openness,
    required this.pupilScale,
    required this.eyeScale,
    required this.movementSpeed,
    required this.minimumIdle,
    required this.maximumIdle,
    required this.gazeWeight,
    required this.microSaccadeWeight,
    required this.normalBlinkWeight,
    required this.doubleBlinkWeight,
    required this.slowBlinkWeight,
    required this.idleWeight,
    this.cornerLift = 0,
    this.verticalOffset = 0,
    this.restingGazeY = 0,
  });

  final double openness;
  final double pupilScale;
  final double eyeScale;
  final double cornerLift;
  final double verticalOffset;
  final double restingGazeY;
  final double movementSpeed;
  final Duration minimumIdle;
  final Duration maximumIdle;
  final double gazeWeight;
  final double microSaccadeWeight;
  final double normalBlinkWeight;
  final double doubleBlinkWeight;
  final double slowBlinkWeight;
  final double idleWeight;

  double get totalActionWeight =>
      gazeWeight +
      microSaccadeWeight +
      normalBlinkWeight +
      doubleBlinkWeight +
      slowBlinkWeight +
      idleWeight;
}
