import 'eye_character.dart';
import 'eye_emotion.dart';

enum EyeMotionPhase {
  idle,
  anticipation,
  moving,
  overshoot,
  settling,
  closing,
  closed,
  opening,
  special,
}

/// Complete, Flutter-free pose sampled by the procedural renderer.
final class EyeRuntimeState {
  EyeRuntimeState({
    required this.gazeX,
    required this.gazeY,
    required this.pupilScale,
    required this.emotion,
    double? eyelidOpen,
    double? leftEyelidOpen,
    double? rightEyelidOpen,
    this.eyeScaleX = 1,
    this.eyeScaleY = 1,
    this.expressionTilt = 0,
    this.verticalOffset = 0,
    this.velocityX = 0,
    this.velocityY = 0,
    this.motionPhase = EyeMotionPhase.idle,
  }) : assert(gazeX >= -1 && gazeX <= 1),
       assert(gazeY >= -1 && gazeY <= 1),
       assert(eyelidOpen != null || leftEyelidOpen != null),
       assert(eyelidOpen != null || rightEyelidOpen != null),
       assert((leftEyelidOpen ?? eyelidOpen)! >= 0),
       assert((leftEyelidOpen ?? eyelidOpen)! <= 1),
       assert((rightEyelidOpen ?? eyelidOpen)! >= 0),
       assert((rightEyelidOpen ?? eyelidOpen)! <= 1),
       assert(pupilScale > 0),
       assert(eyeScaleX > 0),
       assert(eyeScaleY > 0),
       leftEyelidOpen = leftEyelidOpen ?? eyelidOpen!,
       rightEyelidOpen = rightEyelidOpen ?? eyelidOpen!;

  factory EyeRuntimeState.resting(
    EyeMood mood, {
    EyeCharacter character = EyeCharacter.standard,
  }) {
    final profile = character.profileFor(mood);
    return EyeRuntimeState(
      gazeX: 0,
      gazeY: profile.restingGazeY,
      eyelidOpen: profile.openness,
      pupilScale: profile.pupilScale,
      eyeScaleX: profile.eyeScale,
      eyeScaleY: profile.eyeScale,
      expressionTilt: profile.cornerLift,
      verticalOffset: profile.verticalOffset,
      emotion: mood,
    );
  }

  final double gazeX;
  final double gazeY;
  final double leftEyelidOpen;
  final double rightEyelidOpen;
  final double pupilScale;
  final double eyeScaleX;
  final double eyeScaleY;
  final double expressionTilt;
  final double verticalOffset;
  final double velocityX;
  final double velocityY;
  final EyeMotionPhase motionPhase;
  final EyeEmotion emotion;

  EyeMood get mood => emotion;

  double get eyelidOpen => (leftEyelidOpen + rightEyelidOpen) / 2;

  EyeRuntimeState copyWith({
    double? gazeX,
    double? gazeY,
    double? eyelidOpen,
    double? leftEyelidOpen,
    double? rightEyelidOpen,
    double? pupilScale,
    double? eyeScaleX,
    double? eyeScaleY,
    double? expressionTilt,
    double? verticalOffset,
    double? velocityX,
    double? velocityY,
    EyeMotionPhase? motionPhase,
    EyeEmotion? emotion,
  }) {
    return EyeRuntimeState(
      gazeX: gazeX ?? this.gazeX,
      gazeY: gazeY ?? this.gazeY,
      leftEyelidOpen: leftEyelidOpen ?? eyelidOpen ?? this.leftEyelidOpen,
      rightEyelidOpen: rightEyelidOpen ?? eyelidOpen ?? this.rightEyelidOpen,
      pupilScale: pupilScale ?? this.pupilScale,
      eyeScaleX: eyeScaleX ?? this.eyeScaleX,
      eyeScaleY: eyeScaleY ?? this.eyeScaleY,
      expressionTilt: expressionTilt ?? this.expressionTilt,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      motionPhase: motionPhase ?? this.motionPhase,
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
      leftEyelidOpen: _lerp(begin.leftEyelidOpen, end.leftEyelidOpen, progress),
      rightEyelidOpen: _lerp(
        begin.rightEyelidOpen,
        end.rightEyelidOpen,
        progress,
      ),
      pupilScale: _lerp(begin.pupilScale, end.pupilScale, progress),
      eyeScaleX: _lerp(begin.eyeScaleX, end.eyeScaleX, progress),
      eyeScaleY: _lerp(begin.eyeScaleY, end.eyeScaleY, progress),
      expressionTilt: _lerp(begin.expressionTilt, end.expressionTilt, progress),
      verticalOffset: _lerp(begin.verticalOffset, end.verticalOffset, progress),
      velocityX: _lerp(begin.velocityX, end.velocityX, progress),
      velocityY: _lerp(begin.velocityY, end.velocityY, progress),
      motionPhase: progress < 0.5 ? begin.motionPhase : end.motionPhase,
      emotion: progress < 0.5 ? begin.emotion : end.emotion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeRuntimeState &&
          gazeX == other.gazeX &&
          gazeY == other.gazeY &&
          leftEyelidOpen == other.leftEyelidOpen &&
          rightEyelidOpen == other.rightEyelidOpen &&
          pupilScale == other.pupilScale &&
          eyeScaleX == other.eyeScaleX &&
          eyeScaleY == other.eyeScaleY &&
          expressionTilt == other.expressionTilt &&
          verticalOffset == other.verticalOffset &&
          velocityX == other.velocityX &&
          velocityY == other.velocityY &&
          motionPhase == other.motionPhase &&
          emotion == other.emotion;

  @override
  int get hashCode => Object.hash(
    gazeX,
    gazeY,
    leftEyelidOpen,
    rightEyelidOpen,
    pupilScale,
    eyeScaleX,
    eyeScaleY,
    expressionTilt,
    verticalOffset,
    velocityX,
    velocityY,
    motionPhase,
    emotion,
  );
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
