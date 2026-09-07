import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../domain/device/device_snapshot.dart';
import '../../../domain/device/display_profile.dart';
import '../../../l10n/app_localizations.dart';
import 'virtual_screen.dart';

final class CompanionStage extends StatelessWidget {
  const CompanionStage({
    required this.scene,
    required this.displayProfile,
    required this.snapshot,
    required this.diameter,
    this.visualStudyOverride,
    super.key,
  });

  final Scene scene;
  final DisplayProfile displayProfile;
  final DeviceSnapshot snapshot;
  final double diameter;
  final Widget? visualStudyOverride;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
