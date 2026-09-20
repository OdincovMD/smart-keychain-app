import 'eye_motion_clip.dart';
import 'eye_motion_definition.dart';
import 'eye_motion_transition.dart';

abstract final class ChromeKissEyeClips {
  static const neutralIdle = 'neutral_idle';
  static const curiousFollow = 'curious_follow';
  static const flirtyGlance = 'flirty_glance';

  static const values = [neutralIdle, curiousFollow, flirtyGlance];
}

final chromeKissEyeMotionDefinition = EyeMotionDefinition(
  metadata: const {
    'title': 'Chrome Kiss original eye motion',
    'authoring': 'clean-room',
  },
  poses: const {
    'rest': EyeMotionPose(
      gazeX: 0,
      gazeY: 0,
      eyeScaleY: 1,
      expressionTilt: 0,
      verticalOffset: 0,
    ),
    'idle_breathe': EyeMotionPose(
      gazeX: -0.025,
      gazeY: -0.012,
      leftEyelidOpen: 0.985,
      rightEyelidOpen: 1,
      eyeScaleY: 1.012,
      expressionTilt: 0.012,
      verticalOffset: -0.008,
    ),
    'idle_notice': EyeMotionPose(
      gazeX: 0.085,
      gazeY: -0.035,
      leftEyelidOpen: 1,
      rightEyelidOpen: 0.97,
      pupilScale: 1.018,
      expressionTilt: 0.018,
    ),
    'curious_anticipation': EyeMotionPose(
      gazeX: -0.09,
      gazeY: 0.035,
      leftEyelidOpen: 0.985,
      rightEyelidOpen: 1,
      pupilScale: 0.98,
    ),
    'curious_focus': EyeMotionPose(
      gazeX: 0.58,
      gazeY: -0.42,
      leftEyelidOpen: 1,
      rightEyelidOpen: 0.965,
      pupilScale: 1.08,
      eyeScaleX: 1.025,
      eyeScaleY: 1.035,
      expressionTilt: 0.035,
      verticalOffset: -0.012,
    ),
    'curious_overshoot': EyeMotionPose(
      gazeX: 0.64,
      gazeY: -0.46,
      leftEyelidOpen: 1,
      rightEyelidOpen: 0.955,
      pupilScale: 1.055,
      expressionTilt: 0.04,
    ),
    'flirty_contact': EyeMotionPose(
      gazeX: 0,
      gazeY: -0.015,
      leftEyelidOpen: 0.9,
      rightEyelidOpen: 1,
      expressionTilt: 0.055,
    ),
    'flirty_glance_pose': EyeMotionPose(
      gazeX: -0.62,
      gazeY: -0.08,
      leftEyelidOpen: 0.66,
      rightEyelidOpen: 0.94,
      pupilScale: 1.025,
      eyeScaleX: 1.035,
      expressionTilt: 0.09,
      verticalOffset: 0.006,
    ),
    'flirty_return': EyeMotionPose(
      gazeX: 0.07,
      gazeY: -0.02,
      leftEyelidOpen: 0.83,
      rightEyelidOpen: 0.98,
      expressionTilt: 0.07,
    ),
  },
  clips: const {
    ChromeKissEyeClips.neutralIdle: EyeMotionClip(
      name: ChromeKissEyeClips.neutralIdle,
      playbackMode: EyeMotionPlaybackMode.loop,
      blinkPolicy: EyeMotionBlinkPolicy.natural,
      steps: [
        EyeMotionStep(
          pose: 'rest',
          hold: Duration(milliseconds: 1550),
          transition: Duration(milliseconds: 180),
          transitionStyle: EyeMotionTransitionStyle.easeOut,
        ),
        EyeMotionStep(
          pose: 'idle_breathe',
          hold: Duration(milliseconds: 920),
          transition: Duration(milliseconds: 420),
          transitionStyle: EyeMotionTransitionStyle.easeInOut,
        ),
        EyeMotionStep(
          pose: 'rest',
          hold: Duration(milliseconds: 1380),
          transition: Duration(milliseconds: 480),
          transitionStyle: EyeMotionTransitionStyle.easeInOut,
        ),
        EyeMotionStep(
          pose: 'idle_notice',
          hold: Duration(milliseconds: 620),
          transition: Duration(milliseconds: 210),
          transitionStyle: EyeMotionTransitionStyle.easeOut,
        ),
        EyeMotionStep(
          pose: 'rest',
          hold: Duration(milliseconds: 1750),
          transition: Duration(milliseconds: 360),
          transitionStyle: EyeMotionTransitionStyle.emphasized,
        ),
      ],
    ),
    ChromeKissEyeClips.curiousFollow: EyeMotionClip(
      name: ChromeKissEyeClips.curiousFollow,
      playbackMode: EyeMotionPlaybackMode.once,
      blinkPolicy: EyeMotionBlinkPolicy.natural,
      steps: [
        EyeMotionStep(
          pose: 'curious_anticipation',
          hold: Duration(milliseconds: 45),
          transition: Duration(milliseconds: 70),
          transitionStyle: EyeMotionTransitionStyle.easeIn,
        ),
        EyeMotionStep(
          pose: 'curious_overshoot',
          hold: Duration(milliseconds: 30),
          transition: Duration(milliseconds: 240),
          transitionStyle: EyeMotionTransitionStyle.easeOut,
        ),
        EyeMotionStep(
          pose: 'curious_focus',
          hold: Duration(milliseconds: 680),
          transition: Duration(milliseconds: 95),
          transitionStyle: EyeMotionTransitionStyle.emphasized,
        ),
        EyeMotionStep(
          pose: 'rest',
          hold: Duration(milliseconds: 180),
          transition: Duration(milliseconds: 420),
          transitionStyle: EyeMotionTransitionStyle.easeInOut,
        ),
      ],
    ),
    ChromeKissEyeClips.flirtyGlance: EyeMotionClip(
      name: ChromeKissEyeClips.flirtyGlance,
      playbackMode: EyeMotionPlaybackMode.once,
      blinkPolicy: EyeMotionBlinkPolicy.natural,
      steps: [
        EyeMotionStep(
          pose: 'flirty_contact',
          hold: Duration(milliseconds: 180),
          transition: Duration(milliseconds: 180),
          transitionStyle: EyeMotionTransitionStyle.easeOut,
        ),
        EyeMotionStep(
          pose: 'flirty_glance_pose',
          hold: Duration(milliseconds: 420),
          transition: Duration(milliseconds: 310),
          transitionStyle: EyeMotionTransitionStyle.emphasized,
        ),
        EyeMotionStep(
          pose: 'flirty_return',
          hold: Duration(milliseconds: 180),
          transition: Duration(milliseconds: 390),
          transitionStyle: EyeMotionTransitionStyle.easeInOut,
        ),
        EyeMotionStep(
          pose: 'rest',
          hold: Duration(milliseconds: 150),
          transition: Duration(milliseconds: 310),
          transitionStyle: EyeMotionTransitionStyle.easeOut,
        ),
      ],
    ),
  },
);
