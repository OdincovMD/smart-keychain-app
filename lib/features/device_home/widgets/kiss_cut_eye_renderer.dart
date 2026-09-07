import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/device/display_profile.dart';
import '../../../domain/eyes/eye_emotion.dart';
import '../../../domain/eyes/eye_runtime_state.dart';

enum EyeRendererVariant { legacy, kissCutV2, kissCutV21 }

enum KissCutRendererStyle { v2, v21Pure, v21OpticalGlint }

enum KissCutVisualMood {
  neutral,
  happy,
  sleepy,
  curious,
  annoyed,
  surprised,
  flirty;

  factory KissCutVisualMood.fromEmotion(EyeEmotion emotion) {
    return switch (emotion) {
      EyeEmotion.neutral => KissCutVisualMood.neutral,
      EyeEmotion.happy => KissCutVisualMood.happy,
      EyeEmotion.sleepy => KissCutVisualMood.sleepy,
      EyeEmotion.curious => KissCutVisualMood.curious,
      EyeEmotion.annoyed => KissCutVisualMood.annoyed,
      EyeEmotion.surprised => KissCutVisualMood.surprised,
    };
  }
}

enum KissCutColourway { orchidLilac, icyCool, pearlChampagne }

@immutable
final class KissCutPalette {
  const KissCutPalette({
    required this.edge,
    required this.fieldTop,
    required this.fieldMiddle,
    required this.fieldBottom,
    required this.core,
    required this.highlight,
  });

  static const orchidLilac = KissCutPalette(
    edge: Color(0xFF67314F),
    fieldTop: Color(0xFFFFA0D8),
    fieldMiddle: Color(0xFFE85EC2),
    fieldBottom: Color(0xFF8874E8),
    core: Color(0xFF08070C),
    highlight: Color(0xFFFFF4FA),
  );

  static const icyCool = KissCutPalette(
    edge: Color(0xFF444870),
    fieldTop: Color(0xFFE7E2FF),
    fieldMiddle: Color(0xFFAAA0F3),
    fieldBottom: Color(0xFF68BFC1),
    core: Color(0xFF07090E),
    highlight: Color(0xFFFFFFFF),
  );

  static const pearlChampagne = KissCutPalette(
    edge: Color(0xFF6B5652),
    fieldTop: Color(0xFFFFF6EE),
    fieldMiddle: Color(0xFFEAD7CA),
    fieldBottom: Color(0xFFC89A61),
    core: Color(0xFF0B0808),
    highlight: Color(0xFFFFFFFF),
  );

  static KissCutPalette forColourway(KissCutColourway colourway) {
    return switch (colourway) {
      KissCutColourway.orchidLilac => orchidLilac,
      KissCutColourway.icyCool => icyCool,
      KissCutColourway.pearlChampagne => pearlChampagne,
    };
  }

  final Color edge;
  final Color fieldTop;
  final Color fieldMiddle;
  final Color fieldBottom;
  final Color core;
  final Color highlight;
}

@immutable
final class KissCutPaintScene {
  const KissCutPaintScene({
    required this.fromState,
    required this.toState,
    required this.motionCurve,
    required this.displayShape,
    this.visualMoodOverride,
    this.colourway = KissCutColourway.orchidLilac,
    this.style = KissCutRendererStyle.v2,
    this.monochrome = false,
  });

  final EyeRuntimeState fromState;
  final EyeRuntimeState toState;
  final Curve motionCurve;
  final DisplayShape displayShape;
  final KissCutVisualMood? visualMoodOverride;
  final KissCutColourway colourway;
  final KissCutRendererStyle style;
  final bool monochrome;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KissCutPaintScene &&
            fromState == other.fromState &&
            toState == other.toState &&
            motionCurve == other.motionCurve &&
            displayShape == other.displayShape &&
            visualMoodOverride == other.visualMoodOverride &&
            colourway == other.colourway &&
            style == other.style &&
            monochrome == other.monochrome;
  }

  @override
  int get hashCode => Object.hash(
    fromState,
    toState,
    motionCurve,
    displayShape,
    visualMoodOverride,
    colourway,
    style,
    monochrome,
  );
}

@immutable
final class KissCutEyeGeometry {
  const KissCutEyeGeometry({
    required this.silhouetteBounds,
    required this.pupilBounds,
  });

  final Rect silhouetteBounds;
  final Rect pupilBounds;

  bool get pupilInsideEye {
    const epsilon = 0.000001;
    final safeHorizontalInset = silhouetteBounds.width * 0.19;
    final safeVerticalInset = silhouetteBounds.height * 0.16;
    final safe = Rect.fromLTRB(
      silhouetteBounds.left + safeHorizontalInset,
      silhouetteBounds.top + safeVerticalInset,
      silhouetteBounds.right - safeHorizontalInset,
      silhouetteBounds.bottom - safeVerticalInset,
    );
    return pupilBounds.left >= safe.left - epsilon &&
        pupilBounds.top >= safe.top - epsilon &&
        pupilBounds.right <= safe.right + epsilon &&
        pupilBounds.bottom <= safe.bottom + epsilon;
  }
}

@immutable
final class KissCutGeometrySnapshot {
  const KissCutGeometrySnapshot({
    required this.left,
    required this.right,
    required this.contentRadiusFraction,
  });

  factory KissCutGeometrySnapshot.fromState(
    EyeRuntimeState state, {
    KissCutVisualMood? visualMoodOverride,
    KissCutRendererStyle style = KissCutRendererStyle.v2,
  }) {
    final mood =
        visualMoodOverride ?? KissCutVisualMood.fromEmotion(state.emotion);
    final tuning = _tuningFor(mood, style);
    final left = _geometryFor(
      state: state,
      tuning: tuning,
      isLeft: true,
      openness: state.leftEyelidOpen,
    );
    final right = _geometryFor(
      state: state,
      tuning: tuning,
      isLeft: false,
      openness: state.rightEyelidOpen,
    );
    final farthest = math.max(
      _farthestCorner(left.silhouetteBounds),
      _farthestCorner(right.silhouetteBounds),
    );
    return KissCutGeometrySnapshot(
      left: left,
      right: right,
      contentRadiusFraction: farthest * KissCutEyePainter.faceScale,
    );
  }

  final KissCutEyeGeometry left;
  final KissCutEyeGeometry right;
  final double contentRadiusFraction;
}

final class KissCutStudyPose {
  const KissCutStudyPose._();

  static EyeRuntimeState forMood(
    KissCutVisualMood mood, {
    KissCutRendererStyle style = KissCutRendererStyle.v2,
  }) {
    if (style != KissCutRendererStyle.v2) return _v21PoseFor(mood);
    return switch (mood) {
      KissCutVisualMood.neutral => EyeRuntimeState.resting(
        EyeEmotion.neutral,
      ).copyWith(leftEyelidOpen: 0.93, rightEyelidOpen: 0.91),
      KissCutVisualMood.happy => EyeRuntimeState.resting(
        EyeEmotion.happy,
      ).copyWith(gazeY: -0.05, leftEyelidOpen: 0.77),
      KissCutVisualMood.sleepy => EyeRuntimeState.resting(
        EyeEmotion.sleepy,
      ).copyWith(leftEyelidOpen: 0.46, rightEyelidOpen: 0.42),
      KissCutVisualMood.curious =>
        EyeRuntimeState.resting(EyeEmotion.curious).copyWith(
          gazeX: 0.34,
          gazeY: -0.27,
          pupilScale: 0.88,
          leftEyelidOpen: 1,
          rightEyelidOpen: 0.86,
        ),
      KissCutVisualMood.annoyed =>
        EyeRuntimeState.resting(EyeEmotion.annoyed).copyWith(
          gazeX: -0.4,
          gazeY: 0.04,
          leftEyelidOpen: 0.65,
          rightEyelidOpen: 0.59,
        ),
      KissCutVisualMood.surprised => EyeRuntimeState.resting(
        EyeEmotion.surprised,
      ).copyWith(pupilScale: 0.72, eyelidOpen: 1),
      KissCutVisualMood.flirty =>
        EyeRuntimeState.resting(EyeEmotion.neutral).copyWith(
          gazeX: 0.12,
          pupilScale: 0.96,
          leftEyelidOpen: 0.86,
          rightEyelidOpen: 0.71,
          expressionTilt: 0.055,
        ),
    };
  }

  static EyeRuntimeState _v21PoseFor(KissCutVisualMood mood) {
    return switch (mood) {
      KissCutVisualMood.neutral => EyeRuntimeState.resting(
        EyeEmotion.neutral,
      ).copyWith(gazeX: 0.025, leftEyelidOpen: 0.96, rightEyelidOpen: 0.93),
      KissCutVisualMood.happy =>
        EyeRuntimeState.resting(EyeEmotion.happy).copyWith(
          gazeY: -0.035,
          leftEyelidOpen: 0.92,
          rightEyelidOpen: 0.89,
          pupilScale: 0.97,
        ),
      KissCutVisualMood.sleepy => EyeRuntimeState.resting(
        EyeEmotion.sleepy,
      ).copyWith(gazeY: 0.12, leftEyelidOpen: 0.5, rightEyelidOpen: 0.46),
      KissCutVisualMood.curious =>
        EyeRuntimeState.resting(EyeEmotion.curious).copyWith(
          gazeX: 0.36,
          gazeY: -0.3,
          pupilScale: 0.86,
          leftEyelidOpen: 1,
          rightEyelidOpen: 0.94,
        ),
      KissCutVisualMood.annoyed =>
        EyeRuntimeState.resting(EyeEmotion.annoyed).copyWith(
          gazeX: -0.44,
          gazeY: 0.05,
          leftEyelidOpen: 0.88,
          rightEyelidOpen: 0.84,
          pupilScale: 0.93,
        ),
      KissCutVisualMood.surprised => EyeRuntimeState.resting(
        EyeEmotion.surprised,
      ).copyWith(pupilScale: 0.69, eyelidOpen: 1),
      KissCutVisualMood.flirty =>
        EyeRuntimeState.resting(EyeEmotion.neutral).copyWith(
          gazeX: 0.04,
          pupilScale: 0.95,
          leftEyelidOpen: 0.96,
          rightEyelidOpen: 0.92,
          expressionTilt: 0.035,
        ),
    };
  }
}

final class KissCutEyesView extends StatelessWidget {
  const KissCutEyesView({
    required this.state,
    this.visualMoodOverride,
    this.colourway = KissCutColourway.orchidLilac,
    this.style = KissCutRendererStyle.v2,
    this.monochrome = false,
    this.displayShape = DisplayShape.circle,
    super.key,
  });

  static const _complete = AlwaysStoppedAnimation<double>(1);

  final EyeRuntimeState state;
  final KissCutVisualMood? visualMoodOverride;
  final KissCutColourway colourway;
  final KissCutRendererStyle style;
  final bool monochrome;
  final DisplayShape displayShape;

  @override
  Widget build(BuildContext context) {
    final scene = KissCutPaintScene(
      fromState: state,
      toState: state,
      motionCurve: Curves.linear,
      displayShape: displayShape,
      visualMoodOverride: visualMoodOverride,
      colourway: colourway,
      style: style,
      monochrome: monochrome,
    );
    return ColoredBox(
      color: KissCutEyePainter.lensColor,
      child: RepaintBoundary(
        child: CustomPaint(
          key: const Key('kiss_cut_eye_painter'),
          painter: KissCutEyePainter(
            scene,
            progress: KissCutEyesView._complete,
          ),
          isComplex: true,
          willChange: false,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

final class KissCutEyePainter extends CustomPainter {
  KissCutEyePainter(this.scene, {required this.progress})
    : _edgePaint = Paint()..style = PaintingStyle.fill,
      _fieldPaint = Paint()..style = PaintingStyle.fill,
      _shadePaint = Paint()..style = PaintingStyle.fill,
      _innerFalloffPaint = Paint()..style = PaintingStyle.fill,
      _coreEdgePaint = Paint()..style = PaintingStyle.fill,
      _corePaint = Paint()..style = PaintingStyle.fill,
      _highlightPaint = Paint()..style = PaintingStyle.fill,
      _glintPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.11,
      _lensPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = lensColor,
      super(repaint: progress) {
    final palette = KissCutPalette.forColourway(scene.colourway);
    _edgePaint.color = scene.monochrome ? _monochrome : palette.edge;
    _fieldPaint.shader = scene.monochrome
        ? null
        : ui.Gradient.linear(
            const Offset(0, -0.56),
            const Offset(0.18, 0.58),
            [palette.fieldTop, palette.fieldMiddle, palette.fieldBottom],
            const [0, 0.48, 1],
          );
    _fieldPaint.color = scene.monochrome ? _monochrome : palette.fieldMiddle;
    _shadePaint.shader = ui.Gradient.linear(
      const Offset(-0.2, -0.45),
      const Offset(0.28, 0.58),
      scene.monochrome
          ? const [Colors.transparent, Colors.transparent]
          : const [Color(0x00000000), Color(0x70000000)],
    );
    _innerFalloffPaint.shader = ui.Gradient.radial(
      const Offset(-0.12, -0.15),
      0.74,
      scene.monochrome || scene.style == KissCutRendererStyle.v2
          ? const [Colors.transparent, Colors.transparent]
          : [
              palette.fieldTop.withValues(alpha: 0.1),
              palette.edge.withValues(alpha: 0.62),
            ],
      const [0.38, 1],
    );
    _coreEdgePaint.color = scene.monochrome ? _monochrome : palette.edge;
    _corePaint
      ..color = scene.monochrome ? _monochrome : palette.core
      ..shader = scene.monochrome || scene.style == KissCutRendererStyle.v2
          ? null
          : ui.Gradient.linear(
              const Offset(-0.42, -0.5),
              const Offset(0.42, 0.54),
              [
                Color.alphaBlend(
                  palette.fieldMiddle.withValues(alpha: 0.2),
                  palette.core,
                ),
                palette.core,
                Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.7),
                  palette.core,
                ),
              ],
              const [0, 0.46, 1],
            );
    _highlightColor = scene.monochrome ? Colors.transparent : palette.highlight;
    _glintColor = scene.monochrome
        ? Colors.transparent
        : Color.alphaBlend(
            palette.fieldTop.withValues(alpha: 0.7),
            palette.highlight,
          );
  }

  static const faceScale = 0.86;
  static const lensColor = Color(0xFF020205);
  static const _monochrome = Color(0xFFF8F4FA);
  static const _unitRect = Rect.fromLTRB(-0.6, -0.62, 0.6, 0.62);
  static final Path _v2Silhouette = _buildV2Silhouette();
  static final Path _v21Silhouette = _buildV21Silhouette();
  static final Path _v2Core = _buildV2Core();
  static final Path _v21Core = _buildV21Core();
  static final Path _v21Highlight = _buildV21Highlight();
  static final Path _v21LeadGlint = _buildV21LeadGlint();
  static final Path _v21ResponseGlint = _buildV21ResponseGlint();
  static final Path _upperLidMask = _buildUpperLidMask();
  static final Path _lowerLidMask = _buildLowerLidMask();

  final KissCutPaintScene scene;
  final Animation<double> progress;
  final Paint _edgePaint;
  final Paint _fieldPaint;
  final Paint _shadePaint;
  final Paint _innerFalloffPaint;
  final Paint _coreEdgePaint;
  final Paint _corePaint;
  final Paint _highlightPaint;
  final Paint _glintPaint;
  final Paint _lensPaint;
  late final Color _highlightColor;
  late final Color _glintColor;
  final _ResolvedKissCutEye _left = _ResolvedKissCutEye();
  final _ResolvedKissCutEye _right = _ResolvedKissCutEye();

  @override
  void paint(Canvas canvas, Size size) {
    final availableDiameter = math.min(size.width, size.height);
    final t = scene.motionCurve.transform(progress.value);
    final gazeX = _lerp(scene.fromState.gazeX, scene.toState.gazeX, t);
    final gazeY = _lerp(scene.fromState.gazeY, scene.toState.gazeY, t);
    final pupilScale = _lerp(
      scene.fromState.pupilScale,
      scene.toState.pupilScale,
      t,
    );
    final eyeScaleX = _lerp(
      scene.fromState.eyeScaleX,
      scene.toState.eyeScaleX,
      t,
    );
    final eyeScaleY = _lerp(
      scene.fromState.eyeScaleY,
      scene.toState.eyeScaleY,
      t,
    );
    final expressionTilt = _lerp(
      scene.fromState.expressionTilt,
      scene.toState.expressionTilt,
      t,
    );
    final verticalOffset = _lerp(
      scene.fromState.verticalOffset,
      scene.toState.verticalOffset,
      t,
    );
    final mood =
        scene.visualMoodOverride ??
        KissCutVisualMood.fromEmotion(
          t < 0.5 ? scene.fromState.emotion : scene.toState.emotion,
        );
    final tuning = _tuningFor(mood, scene.style);

    _resolveEye(
      target: _left,
      isLeft: true,
      openness: _lerp(
        scene.fromState.leftEyelidOpen,
        scene.toState.leftEyelidOpen,
        t,
      ),
      gazeX: gazeX,
      gazeY: gazeY,
      pupilScale: pupilScale,
      eyeScaleX: eyeScaleX,
      eyeScaleY: eyeScaleY,
      expressionTilt: expressionTilt,
      verticalOffset: verticalOffset,
      tuning: tuning,
    );
    _resolveEye(
      target: _right,
      isLeft: false,
      openness: _lerp(
        scene.fromState.rightEyelidOpen,
        scene.toState.rightEyelidOpen,
        t,
      ),
      gazeX: gazeX,
      gazeY: gazeY,
      pupilScale: pupilScale,
      eyeScaleX: eyeScaleX,
      eyeScaleY: eyeScaleY,
      expressionTilt: expressionTilt,
      verticalOffset: verticalOffset,
      tuning: tuning,
    );

    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(availableDiameter * faceScale);
    _paintEye(canvas, _left, isLeft: true, compact: availableDiameter < 96);
    _paintEye(canvas, _right, isLeft: false, compact: availableDiameter < 96);
    canvas.restore();
  }

  void _paintEye(
    Canvas canvas,
    _ResolvedKissCutEye eye, {
    required bool isLeft,
    required bool compact,
  }) {
    final polished = scene.style != KissCutRendererStyle.v2;
    final silhouette = polished ? _v21Silhouette : _v2Silhouette;
    final core = polished ? _v21Core : _v2Core;
    canvas
      ..save()
      ..translate(eye.centerX, eye.centerY)
      ..rotate(eye.rotation);
    if (isLeft) canvas.scale(-1, 1);
    canvas
      ..scale(eye.halfWidth * 2, eye.halfHeight / 0.54)
      ..drawPath(silhouette, _edgePaint)
      ..save()
      ..scale(polished ? 0.925 : 0.91, polished ? 0.935 : 0.92)
      ..drawPath(silhouette, _fieldPaint)
      ..clipPath(silhouette)
      ..drawRect(_unitRect, _shadePaint)
      ..drawRect(_unitRect, _innerFalloffPaint)
      ..restore();
    if (polished) {
      canvas
        ..save()
        ..translate(0, eye.upperDrop)
        ..rotate(eye.upperLidTilt)
        ..drawPath(_upperLidMask, _lensPaint)
        ..restore();
    }
    canvas
      ..save()
      ..translate(0, -eye.lowerLift)
      ..drawPath(_lowerLidMask, _lensPaint)
      ..restore()
      ..restore();

    if (scene.monochrome) return;

    canvas
      ..save()
      ..translate(eye.pupilCenterX, eye.pupilCenterY)
      ..rotate(eye.coreRotation)
      ..scale(
        eye.pupilHalfWidth * eye.coreWidthScale * (polished ? 2.32 : 2.25),
        eye.pupilHalfHeight * eye.coreHeightScale * (polished ? 2.22 : 2.18),
      )
      ..drawPath(core, _coreEdgePaint)
      ..restore()
      ..save()
      ..translate(eye.pupilCenterX, eye.pupilCenterY)
      ..rotate(eye.coreRotation)
      ..scale(
        eye.pupilHalfWidth * eye.coreWidthScale * 2,
        eye.pupilHalfHeight * eye.coreHeightScale * 2,
      )
      ..drawPath(core, _corePaint)
      ..restore();

    _highlightPaint.color = _highlightColor.withValues(
      alpha: eye.highlightAlpha * (isLeft ? 1 : 0.58),
    );
    if (polished) {
      canvas
        ..save()
        ..translate(
          eye.pupilCenterX - eye.pupilHalfWidth * 0.43,
          eye.pupilCenterY - eye.pupilHalfHeight * 0.45,
        )
        ..rotate(-0.24)
        ..scale(
          compact ? (isLeft ? 0.014 : 0.009) : (isLeft ? 0.017 : 0.011),
          compact ? (isLeft ? 0.01 : 0.006) : (isLeft ? 0.012 : 0.007),
        )
        ..drawPath(_v21Highlight, _highlightPaint)
        ..restore();
      if (scene.style == KissCutRendererStyle.v21OpticalGlint) {
        _paintOpticalGlint(canvas, eye, isLeft: isLeft, compact: compact);
      }
      _paintV21LidOcclusion(canvas, eye, isLeft: isLeft);
      return;
    }

    final highlightRadius = compact
        ? (isLeft ? 0.013 : 0.008)
        : (isLeft ? 0.015 : 0.01);
    canvas.drawCircle(
      Offset(
        eye.pupilCenterX - eye.pupilHalfWidth * 0.48,
        eye.pupilCenterY - eye.pupilHalfHeight * 0.45,
      ),
      highlightRadius,
      _highlightPaint,
    );
  }

  void _paintOpticalGlint(
    Canvas canvas,
    _ResolvedKissCutEye eye, {
    required bool isLeft,
    required bool compact,
  }) {
    _glintPaint.color = _glintColor.withValues(
      alpha: eye.highlightAlpha * (isLeft ? 0.58 : 0.24),
    );
    canvas
      ..save()
      ..translate(eye.pupilCenterX, eye.pupilCenterY)
      ..scale(
        eye.pupilHalfWidth * (compact ? 2.85 : 3.2),
        eye.pupilHalfHeight * (compact ? 2.35 : 2.65),
      )
      ..drawPath(isLeft ? _v21LeadGlint : _v21ResponseGlint, _glintPaint)
      ..restore();
  }

  void _paintV21LidOcclusion(
    Canvas canvas,
    _ResolvedKissCutEye eye, {
    required bool isLeft,
  }) {
    canvas
      ..save()
      ..translate(eye.centerX, eye.centerY)
      ..rotate(eye.rotation);
    if (isLeft) canvas.scale(-1, 1);
    canvas
      ..scale(eye.halfWidth * 2, eye.halfHeight / 0.54)
      ..save()
      ..translate(0, eye.upperDrop)
      ..rotate(eye.upperLidTilt)
      ..drawPath(_upperLidMask, _lensPaint)
      ..restore()
      ..save()
      ..translate(0, -eye.lowerLift)
      ..drawPath(_lowerLidMask, _lensPaint)
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(KissCutEyePainter oldDelegate) {
    return oldDelegate.scene != scene;
  }

  @override
  bool shouldRebuildSemantics(KissCutEyePainter oldDelegate) => false;
}

final class _ResolvedKissCutEye {
  double centerX = 0;
  double centerY = 0;
  double halfWidth = 0;
  double halfHeight = 0;
  double pupilCenterX = 0;
  double pupilCenterY = 0;
  double pupilHalfWidth = 0;
  double pupilHalfHeight = 0;
  double rotation = 0;
  double upperDrop = 0;
  double upperLidTilt = 0;
  double lowerLift = 0;
  double coreWidthScale = 1;
  double coreHeightScale = 1;
  double coreRotation = 0;
  double highlightAlpha = 1;
}

final class _KissCutMoodTuning {
  const _KissCutMoodTuning({
    this.widthScale = 1,
    this.heightScale = 1,
    this.leftOpennessScale = 1,
    this.rightOpennessScale = 1,
    this.rotation = 0,
    this.leftUpperDrop = 0,
    this.rightUpperDrop = 0,
    this.upperLidTilt = 0,
    this.lowerLift = 0.025,
    this.coreWidthScale = 1,
    this.coreHeightScale = 1,
    this.coreRotation = 0,
    this.highlightAlpha = 1,
  });

  final double widthScale;
  final double heightScale;
  final double leftOpennessScale;
  final double rightOpennessScale;
  final double rotation;
  final double leftUpperDrop;
  final double rightUpperDrop;
  final double upperLidTilt;
  final double lowerLift;
  final double coreWidthScale;
  final double coreHeightScale;
  final double coreRotation;
  final double highlightAlpha;
}

_KissCutMoodTuning _tuningFor(
  KissCutVisualMood mood,
  KissCutRendererStyle style,
) {
  return style == KissCutRendererStyle.v2
      ? _v2TuningFor(mood)
      : _v21TuningFor(mood);
}

_KissCutMoodTuning _v2TuningFor(KissCutVisualMood mood) {
  return switch (mood) {
    KissCutVisualMood.neutral => const _KissCutMoodTuning(),
    KissCutVisualMood.happy => const _KissCutMoodTuning(
      widthScale: 1.08,
      heightScale: 1.02,
      rotation: 0.025,
      lowerLift: 0.105,
    ),
    KissCutVisualMood.sleepy => const _KissCutMoodTuning(
      widthScale: 1.03,
      heightScale: 0.94,
      leftOpennessScale: 1.04,
      rightOpennessScale: 0.96,
      rotation: -0.015,
      lowerLift: 0.018,
      highlightAlpha: 0.52,
    ),
    KissCutVisualMood.curious => const _KissCutMoodTuning(
      widthScale: 0.98,
      heightScale: 1.04,
      leftOpennessScale: 1.05,
      rightOpennessScale: 0.93,
      rotation: 0.018,
      lowerLift: 0.035,
    ),
    KissCutVisualMood.annoyed => const _KissCutMoodTuning(
      widthScale: 1.04,
      heightScale: 0.94,
      leftOpennessScale: 0.97,
      rightOpennessScale: 0.92,
      rotation: -0.048,
      lowerLift: 0.018,
      highlightAlpha: 0.72,
    ),
    KissCutVisualMood.surprised => const _KissCutMoodTuning(
      widthScale: 0.91,
      heightScale: 1.1,
      rotation: 0.008,
      lowerLift: 0,
    ),
    KissCutVisualMood.flirty => const _KissCutMoodTuning(
      widthScale: 1.06,
      heightScale: 1.01,
      leftOpennessScale: 1.02,
      rightOpennessScale: 0.88,
      rotation: 0.042,
      lowerLift: 0.045,
      highlightAlpha: 0.88,
    ),
  };
}

_KissCutMoodTuning _v21TuningFor(KissCutVisualMood mood) {
  return switch (mood) {
    KissCutVisualMood.neutral => const _KissCutMoodTuning(
      widthScale: 1.025,
      heightScale: 1.015,
      lowerLift: 0.035,
      coreWidthScale: 0.94,
      coreHeightScale: 1.06,
      coreRotation: -0.012,
    ),
    KissCutVisualMood.happy => const _KissCutMoodTuning(
      widthScale: 1.09,
      heightScale: 1,
      leftUpperDrop: -0.012,
      rightUpperDrop: -0.006,
      lowerLift: 0.075,
      coreWidthScale: 0.98,
      coreHeightScale: 1.02,
    ),
    KissCutVisualMood.sleepy => const _KissCutMoodTuning(
      widthScale: 1.035,
      heightScale: 0.98,
      leftUpperDrop: 0.068,
      rightUpperDrop: 0.083,
      upperLidTilt: -0.01,
      lowerLift: 0.014,
      coreWidthScale: 1.04,
      coreHeightScale: 0.92,
      highlightAlpha: 0.48,
    ),
    KissCutVisualMood.curious => const _KissCutMoodTuning(
      widthScale: 1,
      heightScale: 1.02,
      leftUpperDrop: -0.022,
      rightUpperDrop: 0.058,
      upperLidTilt: 0.012,
      lowerLift: 0.032,
      coreWidthScale: 0.88,
      coreHeightScale: 1.08,
      coreRotation: -0.02,
    ),
    KissCutVisualMood.annoyed => const _KissCutMoodTuning(
      widthScale: 1.055,
      heightScale: 0.98,
      leftUpperDrop: 0.078,
      rightUpperDrop: 0.094,
      upperLidTilt: -0.032,
      rotation: -0.026,
      lowerLift: 0.01,
      coreWidthScale: 1.06,
      coreHeightScale: 0.9,
      coreRotation: 0.025,
      highlightAlpha: 0.68,
    ),
    KissCutVisualMood.surprised => const _KissCutMoodTuning(
      widthScale: 0.92,
      heightScale: 1.08,
      leftUpperDrop: -0.018,
      rightUpperDrop: -0.014,
      rotation: 0.006,
      lowerLift: -0.004,
      coreWidthScale: 0.86,
      coreHeightScale: 1.05,
    ),
    KissCutVisualMood.flirty => const _KissCutMoodTuning(
      widthScale: 1.065,
      heightScale: 1.005,
      leftUpperDrop: 0.018,
      rightUpperDrop: 0.088,
      upperLidTilt: 0.018,
      rotation: 0.026,
      lowerLift: 0.052,
      coreWidthScale: 0.94,
      coreHeightScale: 1.06,
      coreRotation: -0.018,
      highlightAlpha: 0.86,
    ),
  };
}

KissCutEyeGeometry _geometryFor({
  required EyeRuntimeState state,
  required _KissCutMoodTuning tuning,
  required bool isLeft,
  required double openness,
}) {
  final centerX = isLeft ? -0.205 : 0.205;
  final centerY = state.verticalOffset;
  final opennessScale = isLeft
      ? tuning.leftOpennessScale
      : tuning.rightOpennessScale;
  final halfWidth = 0.142 * state.eyeScaleX * tuning.widthScale;
  final halfHeight = math.max(
    0.018,
    0.19 *
        openness.clamp(0.0, 1.0) *
        opennessScale *
        state.eyeScaleY *
        tuning.heightScale,
  );
  final pupilHalfWidth = 0.041 * state.pupilScale;
  final pupilHalfHeight = math.min(
    halfHeight * 0.38,
    0.072 * state.pupilScale * math.max(0.42, openness),
  );
  final allowedX = math.max(0.0, halfWidth * 0.49 - pupilHalfWidth);
  final allowedY = math.max(0.0, halfHeight * 0.46 - pupilHalfHeight);
  final pupilCenterX =
      centerX + (state.gazeX * 0.052).clamp(-allowedX, allowedX);
  final pupilCenterY =
      centerY + (state.gazeY * 0.044).clamp(-allowedY, allowedY);
  const coreEdgeScale = 1.125;
  return KissCutEyeGeometry(
    silhouetteBounds: Rect.fromLTRB(
      centerX - halfWidth,
      centerY - halfHeight,
      centerX + halfWidth,
      centerY + halfHeight,
    ),
    pupilBounds: Rect.fromLTRB(
      pupilCenterX - pupilHalfWidth * coreEdgeScale,
      pupilCenterY - pupilHalfHeight * coreEdgeScale,
      pupilCenterX + pupilHalfWidth * coreEdgeScale,
      pupilCenterY + pupilHalfHeight * coreEdgeScale,
    ),
  );
}

void _resolveEye({
  required _ResolvedKissCutEye target,
  required bool isLeft,
  required double openness,
  required double gazeX,
  required double gazeY,
  required double pupilScale,
  required double eyeScaleX,
  required double eyeScaleY,
  required double expressionTilt,
  required double verticalOffset,
  required _KissCutMoodTuning tuning,
}) {
  final opennessScale = isLeft
      ? tuning.leftOpennessScale
      : tuning.rightOpennessScale;
  target
    ..centerX = isLeft ? -0.205 : 0.205
    ..centerY = verticalOffset
    ..halfWidth = 0.142 * eyeScaleX * tuning.widthScale
    ..halfHeight = math.max(
      0.018,
      0.19 *
          openness.clamp(0.0, 1.0) *
          opennessScale *
          eyeScaleY *
          tuning.heightScale,
    )
    ..pupilHalfWidth = 0.041 * pupilScale;
  target.pupilHalfHeight = math.min(
    target.halfHeight * 0.38,
    0.072 * pupilScale * math.max(0.42, openness),
  );
  final allowedX = math.max(
    0.0,
    target.halfWidth * 0.49 - target.pupilHalfWidth,
  );
  final allowedY = math.max(
    0.0,
    target.halfHeight * 0.46 - target.pupilHalfHeight,
  );
  target
    ..pupilCenterX = target.centerX + (gazeX * 0.052).clamp(-allowedX, allowedX)
    ..pupilCenterY = target.centerY + (gazeY * 0.044).clamp(-allowedY, allowedY)
    ..rotation = (isLeft ? -1 : 1) * (tuning.rotation + expressionTilt * 0.32)
    ..upperDrop = isLeft ? tuning.leftUpperDrop : tuning.rightUpperDrop
    ..upperLidTilt = (isLeft ? -1 : 1) * tuning.upperLidTilt
    ..lowerLift = tuning.lowerLift
    ..coreWidthScale = tuning.coreWidthScale
    ..coreHeightScale = tuning.coreHeightScale
    ..coreRotation = (isLeft ? -1 : 1) * tuning.coreRotation
    ..highlightAlpha = tuning.highlightAlpha;
}

double _farthestCorner(Rect bounds) {
  final x = math.max(bounds.left.abs(), bounds.right.abs());
  final y = math.max(bounds.top.abs(), bounds.bottom.abs());
  return math.sqrt(x * x + y * y);
}

Path _buildV2Silhouette() {
  return Path()
    ..moveTo(-0.02, -0.52)
    ..cubicTo(-0.3, -0.52, -0.5, -0.29, -0.5, 0.06)
    ..cubicTo(-0.5, 0.36, -0.29, 0.54, 0, 0.54)
    ..cubicTo(0.3, 0.54, 0.5, 0.34, 0.5, 0.05)
    ..lineTo(0.5, -0.29)
    ..lineTo(0.37, -0.48)
    ..cubicTo(0.24, -0.52, 0.1, -0.53, -0.02, -0.52)
    ..close();
}

Path _buildV21Silhouette() {
  return Path()
    ..moveTo(-0.08, -0.54)
    ..cubicTo(-0.31, -0.55, -0.49, -0.34, -0.52, -0.04)
    ..cubicTo(-0.55, 0.28, -0.35, 0.53, -0.04, 0.56)
    ..cubicTo(0.28, 0.59, 0.5, 0.37, 0.52, 0.06)
    ..cubicTo(0.53, -0.1, 0.5, -0.23, 0.45, -0.33)
    ..quadraticBezierTo(0.42, -0.4, 0.36, -0.45)
    ..cubicTo(0.25, -0.52, 0.08, -0.55, -0.08, -0.54)
    ..close();
}

Path _buildV2Core() {
  return Path()
    ..moveTo(-0.04, -0.5)
    ..cubicTo(-0.33, -0.49, -0.49, -0.26, -0.47, 0.04)
    ..cubicTo(-0.45, 0.33, -0.25, 0.5, 0.04, 0.5)
    ..cubicTo(0.31, 0.49, 0.48, 0.27, 0.46, -0.04)
    ..cubicTo(0.44, -0.32, 0.25, -0.51, -0.04, -0.5)
    ..close();
}

Path _buildV21Core() {
  return Path()
    ..moveTo(-0.08, -0.51)
    ..cubicTo(-0.34, -0.49, -0.5, -0.25, -0.47, 0.05)
    ..cubicTo(-0.44, 0.34, -0.24, 0.51, 0.05, 0.49)
    ..cubicTo(0.31, 0.47, 0.47, 0.24, 0.45, -0.07)
    ..cubicTo(0.43, -0.34, 0.19, -0.53, -0.08, -0.51)
    ..close();
}

Path _buildV21Highlight() {
  return Path()
    ..moveTo(-0.62, -0.12)
    ..cubicTo(-0.48, -0.52, -0.08, -0.68, 0.28, -0.48)
    ..cubicTo(0.62, -0.3, 0.62, 0.08, 0.34, 0.36)
    ..cubicTo(0.04, 0.64, -0.42, 0.48, -0.6, 0.14)
    ..cubicTo(-0.65, 0.04, -0.66, -0.04, -0.62, -0.12)
    ..close();
}

Path _buildV21LeadGlint() {
  return Path()
    ..moveTo(-0.5, -0.3)
    ..cubicTo(-0.61, -0.1, -0.58, 0.16, -0.42, 0.33);
}

Path _buildV21ResponseGlint() {
  return Path()
    ..moveTo(-0.46, -0.24)
    ..cubicTo(-0.53, -0.1, -0.51, 0.04, -0.43, 0.16);
}

Path _buildUpperLidMask() {
  return Path()
    ..moveTo(-0.64, -0.66)
    ..lineTo(0.64, -0.66)
    ..lineTo(0.64, -0.3)
    ..cubicTo(0.52, -0.32, 0.44, -0.4, 0.36, -0.45)
    ..cubicTo(0.14, -0.54, -0.21, -0.55, -0.64, -0.45)
    ..close();
}

Path _buildLowerLidMask() {
  return Path()
    ..moveTo(-0.62, 0.42)
    ..quadraticBezierTo(0, 0.22, 0.62, 0.42)
    ..lineTo(0.62, 0.64)
    ..lineTo(-0.62, 0.64)
    ..close();
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
