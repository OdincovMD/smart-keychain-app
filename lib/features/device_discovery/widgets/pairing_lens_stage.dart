import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/device/display_profile.dart';
import '../../../domain/eyes/eye_emotion.dart';
import '../../../l10n/app_localizations.dart';
import '../../device_home/widgets/kiss_cut_eye_renderer.dart';
import '../../device_home/widgets/procedural_eyes_view.dart';
import '../pairing_presentation_state.dart';

final class PairingLensStage extends StatefulWidget {
  const PairingLensStage({
    required this.state,
    required this.diameter,
    super.key,
  });

  final PairingPresentationState state;
  final double diameter;

  @override
  State<PairingLensStage> createState() => _PairingLensStageState();
}

final class _PairingLensStageState extends State<PairingLensStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _syncMotion();
  }

  @override
  void didUpdateWidget(PairingLensStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncMotion();
  }

  void _syncMotion() {
    _controller.stop();
    _controller.value = 0;
    if (_reduceMotion ?? true) return;

    switch (widget.state) {
      case PairingPresentationState.searching:
        _controller
          ..duration = const Duration(milliseconds: 1800)
          ..repeat();
      case PairingPresentationState.connected:
        _controller
          ..duration = context.chromeKissMotion.delight.duration
          ..forward();
      case PairingPresentationState.idle:
      case PairingPresentationState.found:
      case PairingPresentationState.connecting:
      case PairingPresentationState.error:
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduced = _reduceMotion ?? true;
    final pose = _PairingPose.forState(widget.state);
    final duration = reduced ? Duration.zero : motion.interaction.duration;

    return Semantics(
      key: const Key('pairing_lens_stage'),
      image: true,
      label: _semanticLabel(AppLocalizations.of(context), widget.state),
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: pose.stageScale,
          duration: duration,
          curve: motion.interaction.curve,
          child: SizedBox.square(
            dimension: widget.diameter,
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.lens,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.lens.withValues(alpha: 0.34),
                      blurRadius: 24,
                      spreadRadius: -8,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(7),
                      child: ClipOval(
                        child: AnimatedOpacity(
                          opacity: pose.eyeOpacity,
                          duration: duration,
                          curve: motion.interaction.curve,
                          child: ProceduralEyesView(
                            animate: false,
                            initialEmotion: pose.emotion,
                            rendererVariant: EyeRendererVariant.kissCutV21,
                            displayProfile: const DisplayProfile(
                              width: 240,
                              height: 240,
                              shape: DisplayShape.circle,
                              aspectRatio: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _PairingLensPainter(
                          colors: colors,
                          state: widget.state,
                          progress: _controller,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
final class _PairingPose {
  const _PairingPose({
    required this.emotion,
    required this.eyeOpacity,
    required this.stageScale,
  });

  factory _PairingPose.forState(PairingPresentationState state) {
    return switch (state) {
      PairingPresentationState.idle => const _PairingPose(
        emotion: EyeEmotion.sleepy,
        eyeOpacity: 0.2,
        stageScale: 0.975,
      ),
      PairingPresentationState.searching => const _PairingPose(
        emotion: EyeEmotion.sleepy,
        eyeOpacity: 0.3,
        stageScale: 0.985,
      ),
      PairingPresentationState.found => const _PairingPose(
        emotion: EyeEmotion.curious,
        eyeOpacity: 0.68,
        stageScale: 1,
      ),
      PairingPresentationState.connecting => const _PairingPose(
        emotion: EyeEmotion.curious,
        eyeOpacity: 0.54,
        stageScale: 0.986,
      ),
      PairingPresentationState.connected => const _PairingPose(
        emotion: EyeEmotion.neutral,
        eyeOpacity: 1,
        stageScale: 1,
      ),
      PairingPresentationState.error => const _PairingPose(
        emotion: EyeEmotion.sleepy,
        eyeOpacity: 0.35,
        stageScale: 0.98,
      ),
    };
  }

  final EyeEmotion emotion;
  final double eyeOpacity;
  final double stageScale;
}

String _semanticLabel(AppLocalizations l10n, PairingPresentationState state) {
  return switch (state) {
    PairingPresentationState.idle => l10n.pairingStageDormantLabel,
    PairingPresentationState.searching => l10n.pairingStageSearchingLabel,
    PairingPresentationState.found => l10n.pairingStageFoundLabel,
    PairingPresentationState.connecting => l10n.pairingStageConnectingLabel,
    PairingPresentationState.connected => l10n.pairingStageConnectedLabel,
    PairingPresentationState.error => l10n.pairingStageErrorLabel,
  };
}

final class _PairingLensPainter extends CustomPainter {
  _PairingLensPainter({
    required this.colors,
    required this.state,
    required Animation<double> progress,
  }) : _progress = progress,
       _outerDepthPaint = Paint()
         ..color = Color.alphaBlend(
           colors.lens.withValues(alpha: 0.56),
           colors.divider,
         )
         ..style = PaintingStyle.stroke
         ..strokeWidth = 4.2,
       _chromePaint = Paint()
         ..color = colors.materialChrome.withValues(alpha: 0.78)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.5,
       _chromeHighlightPaint = Paint()
         ..color = colors.materialChrome.withValues(alpha: 0.98)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 2.6,
       _opticalPaint = Paint()
         ..color = colors.accentOptical.withValues(alpha: 0.74)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 1.35,
       _dangerPaint = Paint()
         ..color = colors.danger.withValues(alpha: 0.72)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 1.5,
       _connectedPaint = Paint()
         ..color = colors.accentOptical.withValues(alpha: 0)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 2.1,
       super(repaint: progress);

  final ChromeKissColors colors;
  final PairingPresentationState state;
  final Animation<double> _progress;
  final Paint _outerDepthPaint;
  final Paint _chromePaint;
  final Paint _chromeHighlightPaint;
  final Paint _opticalPaint;
  final Paint _dangerPaint;
  final Paint _connectedPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 3;
    final rim = Rect.fromCircle(center: center, radius: radius);

    canvas
      ..drawCircle(center, radius, _outerDepthPaint)
      ..drawCircle(center, radius, _chromePaint)
      ..drawArc(
        rim,
        math.pi * 1.02,
        math.pi * 0.66,
        false,
        _chromeHighlightPaint,
      );

    switch (state) {
      case PairingPresentationState.searching:
        final eased = Curves.easeInOutSine.transform(_progress.value);
        final start = math.pi * (1.12 + eased * 0.5);
        canvas.drawArc(rim, start, math.pi * 0.24, false, _opticalPaint);
      case PairingPresentationState.connected:
        if (_progress.value > 0 && _progress.value < 1) {
          final eased = Curves.easeOutCubic.transform(_progress.value);
          _connectedPaint.color = colors.accentOptical.withValues(
            alpha: 0.8 * (1 - eased),
          );
          canvas.drawArc(
            rim,
            math.pi * (0.92 + eased * 0.72),
            math.pi * 0.28,
            false,
            _connectedPaint,
          );
        }
      case PairingPresentationState.error:
        canvas.drawArc(
          rim,
          math.pi * 0.14,
          math.pi * 0.16,
          false,
          _dangerPaint,
        );
      case PairingPresentationState.idle:
      case PairingPresentationState.found:
      case PairingPresentationState.connecting:
        break;
    }
  }

  @override
  bool shouldRepaint(_PairingLensPainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.state != state;
  }
}
