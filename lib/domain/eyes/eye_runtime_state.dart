import 'eye_emotion.dart';

final class EyeRuntimeState {
  const EyeRuntimeState({
    required this.gazeX,
    required this.gazeY,
    required this.eyelidOpen,
    required this.pupilScale,
    required this.emotion,
  }) : assert(gazeX >= -1 && gazeX <= 1),
       assert(gazeY >= -1 && gazeY <= 1),
       assert(eyelidOpen >= 0 && eyelidOpen <= 1),
       assert(pupilScale > 0);

  factory EyeRuntimeState.resting(EyeEmotion emotion) {
    return switch (emotion) {
      EyeEmotion.neutral => const EyeRuntimeState(
        gazeX: 0,
        gazeY: 0,
        eyelidOpen: 0.92,
        pupilScale: 1,
        emotion: EyeEmotion.neutral,
      ),
      EyeEmotion.happy => const EyeRuntimeState(
        gazeX: 0,
        gazeY: 0,
        eyelidOpen: 0.68,
        pupilScale: 1.04,
        emotion: EyeEmotion.happy,
      ),
      EyeEmotion.sleepy => const EyeRuntimeState(
        gazeX: 0,
        gazeY: 0.25,
        eyelidOpen: 0.4,
        pupilScale: 0.9,
        emotion: EyeEmotion.sleepy,
      ),
      EyeEmotion.surprised => const EyeRuntimeState(
        gazeX: 0,
        gazeY: 0,
        eyelidOpen: 1,
        pupilScale: 0.78,
        emotion: EyeEmotion.surprised,
      ),
    };
  }

  final double gazeX;
  final double gazeY;
  final double eyelidOpen;
  final double pupilScale;
  final EyeEmotion emotion;

  EyeRuntimeState copyWith({
    double? gazeX,
    double? gazeY,
    double? eyelidOpen,
    double? pupilScale,
    EyeEmotion? emotion,
  }) {
    return EyeRuntimeState(
      gazeX: gazeX ?? this.gazeX,
      gazeY: gazeY ?? this.gazeY,
      eyelidOpen: eyelidOpen ?? this.eyelidOpen,
      pupilScale: pupilScale ?? this.pupilScale,
      emotion: emotion ?? this.emotion,
    );
  }

  static EyeRuntimeState lerp(
    EyeRuntimeState begin,
    EyeRuntimeState end,
    double t,
  ) {
    final progress = t.clamp(0.0, 1.0);
    return EyeRuntimeState(
      gazeX: _lerp(begin.gazeX, end.gazeX, progress),
      gazeY: _lerp(begin.gazeY, end.gazeY, progress),
      eyelidOpen: _lerp(begin.eyelidOpen, end.eyelidOpen, progress),
      pupilScale: _lerp(begin.pupilScale, end.pupilScale, progress),
      emotion: progress < 0.5 ? begin.emotion : end.emotion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeRuntimeState &&
          gazeX == other.gazeX &&
          gazeY == other.gazeY &&
          eyelidOpen == other.eyelidOpen &&
          pupilScale == other.pupilScale &&
          emotion == other.emotion;

  @override
  int get hashCode =>
      Object.hash(gazeX, gazeY, eyelidOpen, pupilScale, emotion);
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
