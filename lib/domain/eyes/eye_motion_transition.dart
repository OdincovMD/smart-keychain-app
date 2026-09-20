enum EyeMotionTransitionStyle { linear, easeIn, easeOut, easeInOut, emphasized }

double transformEyeMotionProgress(
  EyeMotionTransitionStyle style,
  double progress,
) {
  final t = progress.clamp(0.0, 1.0);
  return switch (style) {
    EyeMotionTransitionStyle.linear => t,
    EyeMotionTransitionStyle.easeIn => t * t * t,
    EyeMotionTransitionStyle.easeOut => 1 - _cube(1 - t),
    EyeMotionTransitionStyle.easeInOut =>
      t < 0.5 ? 4 * t * t * t : 1 - _cube(-2 * t + 2) / 2,
    EyeMotionTransitionStyle.emphasized => t * t * (3 - 2 * t),
  };
}

double _cube(double value) => value * value * value;
