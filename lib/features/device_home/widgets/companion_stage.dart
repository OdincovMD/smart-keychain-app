import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../domain/device/device_snapshot.dart';
import '../../../domain/device/display_profile.dart';
import '../../../l10n/app_localizations.dart';
import 'kiss_cut_eye_renderer.dart';
import 'procedural_eyes_view.dart';
import 'virtual_screen.dart';

final class CompanionStage extends StatelessWidget {
  const CompanionStage({
    required this.scene,
    required this.displayProfile,
    required this.snapshot,
    required this.diameter,
    this.visualStudyOverride,
    this.jewelryMode = false,
    super.key,
  });

  final Scene scene;
  final DisplayProfile displayProfile;
  final DeviceSnapshot snapshot;
  final double diameter;
  final Widget? visualStudyOverride;
  final bool jewelryMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (jewelryMode) {
      return Semantics(
        image: true,
        label: AppLocalizations.of(context).devicePreviewLabel,
        child: ExcludeSemantics(
          child: _JewelryCompanionStage(
            scene: scene,
            displayProfile: displayProfile,
            snapshot: snapshot,
            width: diameter,
            visualStudyOverride: visualStudyOverride,
            confirmationEnabled: !reduceMotion,
            confirmationDuration: motion.delight.duration,
          ),
        ),
      );
    }
    final rimScene = _LensMaterialScene(
      darkReflection: Color.alphaBlend(
        colors.lens.withValues(alpha: 0.58),
        colors.divider,
      ),
      liquidSilver: colors.materialChrome,
      coldHighlight: colors.accentOptical,
      innerDepth: Color.alphaBlend(
        colors.lens.withValues(alpha: 0.72),
        colors.divider,
      ),
    );

    return Semantics(
      image: true,
      label: AppLocalizations.of(context).devicePreviewLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const Key('companion_stage'),
          dimension: diameter,
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.lens,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.lens.withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child:
                                visualStudyOverride ??
                                VirtualScreen(
                                  scene: scene,
                                  displayProfile: displayProfile,
                                  snapshot: snapshot,
                                ),
                          ),
                          const IgnorePointer(child: _LensDepthOverlay()),
                        ],
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      key: const Key('companion_stage_rim'),
                      painter: _LensMaterialPainter(rimScene),
                    ),
                  ),
                  _StageConfirmationGlint(
                    sceneId: scene.id,
                    enabled: !reduceMotion,
                    duration: motion.delight.duration,
                    color: colors.accentOptical,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _JewelryCompanionStage extends StatelessWidget {
  const _JewelryCompanionStage({
    required this.scene,
    required this.displayProfile,
    required this.snapshot,
    required this.width,
    required this.confirmationEnabled,
    required this.confirmationDuration,
    this.visualStudyOverride,
  });

  static const _designWidth = 274.0;
  static const _designHeight = 333.9375;

  final Scene scene;
  final DisplayProfile displayProfile;
  final DeviceSnapshot snapshot;
  final double width;
  final bool confirmationEnabled;
  final Duration confirmationDuration;
  final Widget? visualStudyOverride;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final scale = width / _designWidth;
    double x(double value) => value * scale;

    return SizedBox(
      key: const Key('companion_stage'),
      width: width,
      height: _designHeight * scale,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _asset(
              'assets/chrome_kiss/key_ring.png',
              left: x(82.2),
              top: x(-10.3),
              width: x(109.6),
              height: x(123.3),
            ),
            _asset(
              'assets/chrome_kiss/key_ring_opening.png',
              left: x(118.2),
              top: x(16.3),
              width: x(37.7),
              height: x(53.1),
            ),
            _asset(
              'assets/chrome_kiss/pendant_chrome_shell.png',
              left: x(-15.4),
              top: x(46.2),
              width: x(304.8),
              height: x(304.8),
            ),
            _asset(
              'assets/chrome_kiss/pendant_lens.png',
              left: x(20.6),
              top: x(73.6),
              width: x(232.9),
              height: x(232.9),
            ),
            Positioned(
              left: x(33.5),
              top: x(86.5),
              width: x(207),
              height: x(207),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: visualStudyOverride ?? _jewelryScreen(context),
                    ),
                    const IgnorePointer(child: _LensDepthOverlay()),
                    if (scene.content is StaticImageContent)
                      IgnorePointer(
                        child: CustomPaint(
                          key: const Key('companion_stage_makeup'),
                          painter: _CompanionMakeupPainter(
                            _CompanionMakeupScene(
                              liner: colors.accentOptical,
                              sparkle: colors.materialChampagne,
                              heart: colors.accentPrimary,
                            ),
                          ),
                        ),
                      ),
                    _StageConfirmationGlint(
                      sceneId: scene.id,
                      enabled: confirmationEnabled,
                      duration: confirmationDuration,
                      color: colors.accentOptical,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              key: const Key('companion_stage_rim'),
              left: x(28.2),
              top: x(81.3),
              width: x(217.5),
              height: x(217.5),
              child: Image.asset(
                'assets/chrome_kiss/lens_inner_rim.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            _asset(
              'assets/chrome_kiss/lens_glint_lilac.png',
              left: x(40),
              top: x(102),
              width: x(26),
              height: x(26),
            ),
            _asset(
              'assets/chrome_kiss/lens_glint_white.png',
              left: x(213),
              top: x(251),
              width: x(11),
              height: x(11),
            ),
            _asset(
              'assets/chrome_kiss/lens_glint_orchid.png',
              left: x(225),
              top: x(117),
              width: x(18),
              height: x(18),
            ),
            _asset(
              'assets/chrome_kiss/bow_left.png',
              left: x(197),
              top: x(75),
              width: x(34.5),
              height: x(30.5),
            ),
            _asset(
              'assets/chrome_kiss/bow_right.png',
              left: x(235),
              top: x(63),
              width: x(34.5),
              height: x(30.5),
            ),
            _asset(
              'assets/chrome_kiss/bow_knot.png',
              left: x(224),
              top: x(80),
              width: x(19),
              height: x(19),
            ),
            _asset(
              'assets/chrome_kiss/charm_ring.png',
              left: x(244),
              top: x(98),
              width: x(24),
              height: x(24),
            ),
            Positioned(
              left: x(248),
              top: x(118),
              width: x(17),
              height: x(16),
              child: Icon(
                Icons.favorite_rounded,
                color: colors.accentPrimary,
                size: x(16.27),
                shadows: [
                  Shadow(
                    color: colors.accentPrimary.withValues(alpha: 0.72),
                    blurRadius: x(8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jewelryScreen(BuildContext context) {
    return switch (scene.content) {
      final ProceduralEyesContent content => Stack(
        fit: StackFit.expand,
        children: [
          KeyedSubtree(
            key: ValueKey(scene.id),
            child: ProceduralEyesView(
              initialEmotion: content.defaultEmotion,
              displayProfile: displayProfile,
              rendererVariant: EyeRendererVariant.kissCutV21,
              useProductionMotionDefinition: true,
            ),
          ),
          IgnorePointer(
            child: AnimatedContainer(
              key: const Key('figma_jewelry_brightness_overlay'),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              color: context.chromeKiss.lens.withValues(
                alpha: ((0.8 - snapshot.brightness) / 0.8).clamp(0, 1),
              ),
            ),
          ),
        ],
      ),
      _ => VirtualScreen(
        scene: scene,
        displayProfile: displayProfile,
        snapshot: snapshot,
      ),
    };
  }

  Widget _asset(
    String path, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Image.asset(
        path,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

@immutable
final class _CompanionMakeupScene {
  const _CompanionMakeupScene({
    required this.liner,
    required this.sparkle,
    required this.heart,
  });

  final Color liner;
  final Color sparkle;
  final Color heart;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CompanionMakeupScene &&
            liner == other.liner &&
            sparkle == other.sparkle &&
            heart == other.heart;
  }

  @override
  int get hashCode => Object.hash(liner, sparkle, heart);
}

final class _CompanionMakeupPainter extends CustomPainter {
  _CompanionMakeupPainter(this.scene)
    : _linerPaint = Paint()
        ..color = scene.liner.withValues(alpha: 0.86)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 0.014,
      _sparklePaint = Paint()
        ..color = scene.sparkle.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.01,
      _heartPaint = Paint()
        ..color = scene.heart.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 0.012;

  static final Path _liner = Path()
    ..moveTo(0.14, 0.43)
    ..quadraticBezierTo(0.29, 0.29, 0.46, 0.4)
    ..moveTo(0.54, 0.4)
    ..quadraticBezierTo(0.71, 0.28, 0.86, 0.39)
    ..moveTo(0.18, 0.36)
    ..lineTo(0.13, 0.31)
    ..moveTo(0.23, 0.32)
    ..lineTo(0.2, 0.26)
    ..moveTo(0.8, 0.32)
    ..lineTo(0.83, 0.26)
    ..moveTo(0.85, 0.36)
    ..lineTo(0.89, 0.31);
  static final Path _sparkle = Path()
    ..moveTo(0.2, 0.57)
    ..lineTo(0.2, 0.64)
    ..moveTo(0.165, 0.605)
    ..lineTo(0.235, 0.605)
    ..moveTo(0.49, 0.69)
    ..lineTo(0.49, 0.73)
    ..moveTo(0.47, 0.71)
    ..lineTo(0.51, 0.71);
  static final Path _heart = Path()
    ..moveTo(0.81, 0.57)
    ..cubicTo(0.76, 0.52, 0.7, 0.58, 0.81, 0.67)
    ..cubicTo(0.92, 0.58, 0.86, 0.52, 0.81, 0.57);

  final _CompanionMakeupScene scene;
  final Paint _linerPaint;
  final Paint _sparklePaint;
  final Paint _heartPaint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width, size.height)
      ..drawPath(_liner, _linerPaint)
      ..drawPath(_sparkle, _sparklePaint)
      ..drawPath(_heart, _heartPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_CompanionMakeupPainter oldDelegate) {
    return oldDelegate.scene != scene;
  }
}

final class _LensDepthOverlay extends StatelessWidget {
  const _LensDepthOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.18, -0.2),
              radius: 0.92,
              colors: [
                colors.materialChrome.withValues(alpha: 0.025),
                colors.lens.withValues(alpha: 0),
                colors.lens.withValues(alpha: 0.38),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.materialChrome.withValues(alpha: 0.035),
                colors.lens.withValues(alpha: 0),
                colors.lens.withValues(alpha: 0.2),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
final class _LensMaterialScene {
  const _LensMaterialScene({
    required this.darkReflection,
    required this.liquidSilver,
    required this.coldHighlight,
    required this.innerDepth,
  });

  final Color darkReflection;
  final Color liquidSilver;
  final Color coldHighlight;
  final Color innerDepth;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _LensMaterialScene &&
            darkReflection == other.darkReflection &&
            liquidSilver == other.liquidSilver &&
            coldHighlight == other.coldHighlight &&
            innerDepth == other.innerDepth;
  }

  @override
  int get hashCode =>
      Object.hash(darkReflection, liquidSilver, coldHighlight, innerDepth);
}

final class _LensMaterialPainter extends CustomPainter {
  _LensMaterialPainter(this.scene)
    : _darkReflectionPaint = Paint()
        ..color = scene.darkReflection
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4,
      _liquidSilverPaint = Paint()
        ..color = scene.liquidSilver.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45,
      _silverEmphasisPaint = Paint()
        ..color = scene.liquidSilver.withValues(alpha: 0.96)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.7,
      _coldHighlightPaint = Paint()
        ..color = scene.coldHighlight.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.15,
      _lowerReflectionPaint = Paint()
        ..color = scene.darkReflection.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5,
      _innerDepthPaint = Paint()
        ..color = scene.innerDepth.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

  final _LensMaterialScene scene;
  final Paint _darkReflectionPaint;
  final Paint _liquidSilverPaint;
  final Paint _silverEmphasisPaint;
  final Paint _coldHighlightPaint;
  final Paint _lowerReflectionPaint;
  final Paint _innerDepthPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 2.8;
    final rimRect = Rect.fromCircle(center: center, radius: radius);

    canvas
      ..drawCircle(center, radius, _darkReflectionPaint)
      ..drawCircle(center, radius, _liquidSilverPaint)
      ..drawArc(
        rimRect,
        math.pi * 0.98,
        math.pi * 0.72,
        false,
        _silverEmphasisPaint,
      )
      ..drawArc(
        rimRect,
        math.pi * 1.16,
        math.pi * 0.22,
        false,
        _coldHighlightPaint,
      )
      ..drawArc(
        rimRect,
        math.pi * -0.08,
        math.pi * 0.58,
        false,
        _lowerReflectionPaint,
      )
      ..drawCircle(center, radius - 4.7, _innerDepthPaint);
  }

  @override
  bool shouldRepaint(_LensMaterialPainter oldDelegate) {
    return oldDelegate.scene != scene;
  }
}

final class _StageConfirmationGlint extends StatefulWidget {
  const _StageConfirmationGlint({
    required this.sceneId,
    required this.enabled,
    required this.duration,
    required this.color,
  });

  final String sceneId;
  final bool enabled;
  final Duration duration;
  final Color color;

  @override
  State<_StageConfirmationGlint> createState() =>
      _StageConfirmationGlintState();
}

final class _StageConfirmationGlintState extends State<_StageConfirmationGlint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(_StageConfirmationGlint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!widget.enabled) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (oldWidget.sceneId != widget.sceneId) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: const Key('companion_stage_confirmation'),
        painter: _StageConfirmationPainter(
          color: widget.color,
          progress: _controller,
        ),
      ),
    );
  }
}

final class _StageConfirmationPainter extends CustomPainter {
  _StageConfirmationPainter({required this.color, required this.progress})
    : _paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2,
      super(repaint: progress);

  final Color color;
  final Animation<double> progress;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress.value);
    final visibility = math.sin(math.pi * t).clamp(0.0, 1.0);
    if (visibility <= 0) return;

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4.1;
    final rect = Rect.fromCircle(center: center, radius: radius);
    _paint.color = color.withValues(alpha: visibility * 0.72);
    canvas.drawArc(
      rect,
      math.pi * (1.02 + t * 0.18),
      math.pi * 0.16,
      false,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_StageConfirmationPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
