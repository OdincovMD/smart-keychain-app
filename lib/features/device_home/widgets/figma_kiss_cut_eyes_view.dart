import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/eyes/eye_character.dart';
import '../../../domain/eyes/eye_runtime_state.dart';
import 'eye_motion_ticker.dart';

/// Asset-faithful Kiss Cut renderer for the Home jewelry lens.
///
/// The two exported eye layers reproduce the Figma resting frame. Motion is
/// still driven by [EyeRuntimeState], so blink, gaze and emotion sequences keep
/// using the existing deterministic eye engine.
final class FigmaKissCutEyesView extends StatelessWidget {
  const FigmaKissCutEyesView({
    required this.fromState,
    required this.toState,
    required this.motionCurve,
    required this.progress,
    this.stateSource,
    super.key,
  });

  static const _designSize = 207.0;
  static const _lens = Color(0xFF020205);
  static const _orchid = Color(0xFFFF4FB8);
  static const _champagne = Color(0xFFE7C98B);

  final EyeRuntimeState fromState;
  final EyeRuntimeState toState;
  final Curve motionCurve;
  final Animation<double> progress;
  final EyeMotionStateSource? stateSource;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _lens,
      child: AnimatedBuilder(
        animation: stateSource ?? progress,
        builder: (context, child) {
          final t = motionCurve.transform(progress.value);
          final liveState = stateSource?.state;
          final from = liveState ?? fromState;
          final to = liveState ?? toState;
          final fromProfile = EyeCharacter.standard.profileFor(from.emotion);
          final toProfile = EyeCharacter.standard.profileFor(to.emotion);
          final gazeX = _lerp(from.gazeX, to.gazeX, t);
          final gazeY = _lerp(
            from.gazeY - fromProfile.restingGazeY,
            to.gazeY - toProfile.restingGazeY,
            t,
          );
          final eyeScaleX = _lerp(
            from.eyeScaleX / fromProfile.eyeScale,
            to.eyeScaleX / toProfile.eyeScale,
            t,
          );
          final eyeScaleY = _lerp(
            from.eyeScaleY / fromProfile.eyeScale,
            to.eyeScaleY / toProfile.eyeScale,
            t,
          );
          final leftOpen = _lerp(
            from.leftEyelidOpen / fromProfile.openness,
            to.leftEyelidOpen / toProfile.openness,
            t,
          );
          final rightOpen = _lerp(
            from.rightEyelidOpen / fromProfile.openness,
            to.rightEyelidOpen / toProfile.openness,
            t,
          );
          final verticalOffset = _lerp(
            from.verticalOffset - fromProfile.verticalOffset,
            to.verticalOffset - toProfile.verticalOffset,
            t,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final scale =
                  math.min(constraints.maxWidth, constraints.maxHeight) /
                  _designSize;
              double x(double value) => value * scale;
              final motionOffset = Offset(
                x(gazeX * 3.2),
                x(gazeY * 2.4 + verticalOffset * 18),
              );

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _eye(
                    path: 'assets/chrome_kiss/eye_left_figma.png',
                    left: x(24.725),
                    top: x(60.775),
                    width: x(70.2125),
                    height: x(82.2),
                    openness: leftOpen,
                    scaleX: eyeScaleX,
                    scaleY: eyeScaleY,
                    offset: motionOffset,
                  ),
                  _eye(
                    path: 'assets/chrome_kiss/eye_right_figma.png',
                    left: x(112.0625),
                    top: x(60.775),
                    width: x(70.2125),
                    height: x(82.2),
                    openness: rightOpen,
                    scaleX: eyeScaleX,
                    scaleY: eyeScaleY,
                    offset: motionOffset,
                  ),
                  Positioned(
                    left: x(95.8),
                    top: x(129.6),
                    width: x(15.41),
                    height: x(18),
                    child: Center(
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: _orchid,
                        size: x(10),
                      ),
                    ),
                  ),
                  Positioned(
                    left: x(187.4),
                    top: x(125),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: _champagne,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: x(3.4)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _eye({
    required String path,
    required double left,
    required double top,
    required double width,
    required double height,
    required double openness,
    required double scaleX,
    required double scaleY,
    required Offset offset,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          alignment: Alignment.center,
          scaleX: scaleX,
          scaleY: math.max(0.055, openness) * scaleY,
          child: Image.asset(path, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
