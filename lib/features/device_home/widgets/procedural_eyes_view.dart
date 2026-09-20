import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../domain/device/display_profile.dart';
import '../../../domain/eyes/eye_behaviour_engine.dart';
import '../../../domain/eyes/eye_emotion.dart';
import '../../../domain/eyes/eye_motion_library.dart';
import '../../../domain/eyes/eye_motion_definition.dart';
import '../../../domain/eyes/eye_motion_player.dart';
import '../../../domain/eyes/eye_runtime_state.dart';
import '../eye_preview_controller.dart';
import 'eye_motion_ticker.dart';
import 'figma_kiss_cut_eyes_view.dart';
import 'kiss_cut_eye_renderer.dart';

final class ProceduralEyesView extends ConsumerStatefulWidget {
  const ProceduralEyesView({
    required this.initialEmotion,
    this.animate = true,
    this.displayProfile,
    this.rendererVariant = EyeRendererVariant.legacy,
    this.kissCutVisualMoodOverride,
    this.kissCutColourway = KissCutColourway.orchidLilac,
    this.motionDefinition,
    this.onRuntimeReady,
    super.key,
  });

  final EyeEmotion initialEmotion;
  final bool animate;
  final DisplayProfile? displayProfile;
  final EyeRendererVariant rendererVariant;
  final KissCutVisualMood? kissCutVisualMoodOverride;
  final KissCutColourway kissCutColourway;
  final EyeMotionDefinition? motionDefinition;
  final ValueChanged<EyeMotionTicker>? onRuntimeReady;

  @override
  ConsumerState<ProceduralEyesView> createState() => _ProceduralEyesViewState();
}

final class _ProceduralEyesViewState extends ConsumerState<ProceduralEyesView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _complete = AlwaysStoppedAnimation<double>(1);

  late EyeBehaviourEngine _engine;
  late EyeMotionTicker _runtime;
  var _motionEnabled = false;
  var _lifecycleActive = true;
  var _manuallyPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createRuntime();
  }

  void _createRuntime({int? seed, EyeMood? initialMood}) {
    final random = seed == null
        ? (widget.animate ? ref.read(eyeRandomProvider) : math.Random(0))
        : math.Random(seed);
    final mood = initialMood ?? widget.initialEmotion;
    final preview = widget.animate
        ? ref.read(eyePreviewControllerProvider)
        : null;
    _engine = EyeBehaviourEngine(random, initialMood: mood);
    final player = EyeMotionPlayer(
      behaviourEngine: _engine,
      definition: widget.motionDefinition,
      initialMood: mood,
      initialClip: preview?.clipName ?? ChromeKissEyeClips.neutralIdle,
    )..setSpeed(preview?.playbackSpeed ?? 1);
    if (!widget.animate) player.stop(snapToMood: true);
    _runtime = EyeMotionTicker(vsync: this, player: player);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRuntimeReady?.call(_runtime);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextMotionEnabled =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (_motionEnabled == nextMotionEnabled) return;
    _motionEnabled = nextMotionEnabled;
    if (_motionEnabled && _lifecycleActive) {
      _runtime.start();
    } else {
      _runtime.stop(snapToMood: true);
    }
  }

  @override
  void didUpdateWidget(ProceduralEyesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionDefinition != widget.motionDefinition) {
      final shouldRun = _motionEnabled && _lifecycleActive && !_manuallyPaused;
      final mood = _runtime.player.mood;
      _runtime.dispose();
      _createRuntime(initialMood: mood);
      if (shouldRun) _runtime.start();
      return;
    }
    if (oldWidget.initialEmotion != widget.initialEmotion) {
      if (widget.animate && _motionEnabled) {
        _runtime.player.setMood(widget.initialEmotion);
      } else {
        _runtime.player.snapToMood(widget.initialEmotion);
        _runtime.refresh();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleActive = state == AppLifecycleState.resumed;
    if (_lifecycleActive && _motionEnabled && !_manuallyPaused) {
      _runtime.start();
    } else {
      _runtime.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animate) {
      ref
        ..listen(
          eyePreviewControllerProvider.select((state) => state.emotion),
          (previous, next) => _changeEmotion(next),
        )
        ..listen(
          eyePreviewControllerProvider.select(
            (state) => (state.commandRevision, state.command),
          ),
          (previous, next) {
            if (previous != null && next.$1 > previous.$1 && next.$2 != null) {
              _requestCommand(next.$2!);
            }
          },
        )
        ..listen(
          eyePreviewControllerProvider.select((state) => state.randomSeed),
          (previous, next) => _changeRandomSeed(next),
        )
        ..listen(
          eyePreviewControllerProvider.select((state) => state.clipName),
          (previous, next) {
            _runtime.player.play(next);
            _runtime.refresh();
          },
        )
        ..listen(
          eyePreviewControllerProvider.select(
            (state) => (state.playbackRevision, state.playbackCommand),
          ),
          (previous, next) {
            if (previous == null || next.$1 <= previous.$1) return;
            _handlePlaybackCommand(next.$2);
          },
        )
        ..listen(
          eyePreviewControllerProvider.select((state) => state.playbackSpeed),
          (previous, next) => _runtime.player.setSpeed(next),
        );
    }

    final current = _runtime.state;
    final scene = EyePaintScene(
      fromState: current,
      toState: current,
      motionCurve: Curves.linear,
      displayShape: widget.displayProfile?.shape ?? DisplayShape.circle,
      eyeColor: AppColors.mint,
      pupilColor: AppColors.background,
      glintColor: AppColors.amber,
      haloColor: AppColors.mint.withValues(alpha: 0.16),
    );
    if (widget.rendererVariant == EyeRendererVariant.figmaJewelry) {
      return ExcludeSemantics(
        child: RepaintBoundary(
          child: FigmaKissCutEyesView(
            key: const Key('figma_kiss_cut_eyes'),
            fromState: current,
            toState: current,
            motionCurve: Curves.linear,
            progress: _complete,
            stateSource: _runtime,
          ),
        ),
      );
    }
    final painter = switch (widget.rendererVariant) {
      EyeRendererVariant.legacy => ProceduralEyePainter(
        scene,
        progress: _complete,
        stateSource: _runtime,
      ),
      EyeRendererVariant.kissCutV2 => KissCutEyePainter(
        KissCutPaintScene(
          fromState: current,
          toState: current,
          motionCurve: Curves.linear,
          displayShape: widget.displayProfile?.shape ?? DisplayShape.circle,
          visualMoodOverride: widget.kissCutVisualMoodOverride,
          colourway: widget.kissCutColourway,
          style: KissCutRendererStyle.v2,
        ),
        progress: _complete,
        stateSource: _runtime,
      ),
      EyeRendererVariant.kissCutV21 => KissCutEyePainter(
        KissCutPaintScene(
          fromState: current,
          toState: current,
          motionCurve: Curves.linear,
          displayShape: widget.displayProfile?.shape ?? DisplayShape.circle,
          visualMoodOverride: widget.kissCutVisualMoodOverride,
          colourway: widget.kissCutColourway,
          style: KissCutRendererStyle.v21OpticalGlint,
        ),
        progress: _complete,
        stateSource: _runtime,
      ),
      EyeRendererVariant.figmaJewelry => null,
    };
    final painterKey = switch (widget.rendererVariant) {
      EyeRendererVariant.legacy => const Key('procedural_eyes_painter'),
      EyeRendererVariant.kissCutV2 ||
      EyeRendererVariant.kissCutV21 => const Key('kiss_cut_eye_painter'),
      EyeRendererVariant.figmaJewelry => const Key('figma_kiss_cut_eyes'),
    };

    return ColoredBox(
      color: widget.rendererVariant == EyeRendererVariant.legacy
          ? Colors.black
          : KissCutEyePainter.lensColor,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            key: painterKey,
            painter: painter,
            isComplex: widget.rendererVariant != EyeRendererVariant.legacy,
            willChange: _motionEnabled,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  void _changeEmotion(EyeEmotion emotion) {
    if (_motionEnabled) {
      _runtime.player.setMood(emotion);
    } else {
      _runtime.player.snapToMood(emotion);
    }
    _runtime.refresh();
  }

  void _changeRandomSeed(int? seed) {
    if (!widget.animate) return;
    final wasEnabled = _motionEnabled && _lifecycleActive;
    final mood = _runtime.player.mood;
    _runtime.dispose();
    _createRuntime(seed: seed, initialMood: mood);
    if (wasEnabled) _runtime.start();
    setState(() {});
  }

  void _requestCommand(EyeDebugCommand command) {
    if (!_motionEnabled) return;
    final action = switch (command) {
      EyeDebugCommand.blink => _engine.forceBlink(),
      EyeDebugCommand.doubleBlink => _engine.forceBlink(
        variant: EyeBlinkVariant.doubleBlink,
      ),
      EyeDebugCommand.lookLeft => _engine.look(EyeLookDirection.left),
      EyeDebugCommand.lookRight => _engine.look(EyeLookDirection.right),
      EyeDebugCommand.specialAction => _engine.playSpecialAction(
        EyeSpecialAction.fireflySearch,
      ),
    };
    _runtime.player.trigger(action);
    _runtime.refresh();
  }

  void _handlePlaybackCommand(EyePlaybackCommand? command) {
    switch (command) {
      case EyePlaybackCommand.play:
        _manuallyPaused = false;
        if (_motionEnabled && _lifecycleActive) _runtime.start();
      case EyePlaybackCommand.pause:
        _manuallyPaused = true;
        _runtime.pause();
      case EyePlaybackCommand.restart:
        _manuallyPaused = false;
        _runtime.player.restart();
        if (_motionEnabled && _lifecycleActive) _runtime.start();
        _runtime.refresh();
      case null:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runtime.dispose();
    super.dispose();
  }
}

@immutable
final class EyePaintScene {
  const EyePaintScene({
    required this.fromState,
    required this.toState,
    required this.motionCurve,
    required this.displayShape,
    required this.eyeColor,
    required this.pupilColor,
    required this.glintColor,
    required this.haloColor,
  });

  final EyeRuntimeState fromState;
  final EyeRuntimeState toState;
  final Curve motionCurve;
  final DisplayShape displayShape;
  final Color eyeColor;
  final Color pupilColor;
  final Color glintColor;
  final Color haloColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyePaintScene &&
          fromState == other.fromState &&
          toState == other.toState &&
          motionCurve == other.motionCurve &&
          displayShape == other.displayShape &&
          eyeColor == other.eyeColor &&
          pupilColor == other.pupilColor &&
          glintColor == other.glintColor &&
          haloColor == other.haloColor;

  @override
  int get hashCode => Object.hash(
    fromState,
    toState,
    motionCurve,
    displayShape,
    eyeColor,
    pupilColor,
    glintColor,
    haloColor,
  );
}

final class ProceduralEyePainter extends CustomPainter {
  ProceduralEyePainter(this.scene, {required this.progress, this.stateSource})
    : _eyePaint = Paint()..style = PaintingStyle.fill,
      _pupilPaint = Paint()..style = PaintingStyle.fill,
      _glintPaint = Paint()..style = PaintingStyle.fill,
      _haloPaint = Paint()..style = PaintingStyle.fill,
      super(repaint: stateSource ?? progress);

  static final RRect _eyeShape = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-0.1313, -0.1717, 0.2626, 0.3434),
    const Radius.circular(0.1212),
  );
  static final RRect _pupilShape = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-0.0404, -0.0707, 0.0808, 0.1414),
    const Radius.circular(0.0404),
  );

  final EyePaintScene scene;
  final Animation<double> progress;
  final EyeMotionStateSource? stateSource;
  final Paint _eyePaint;
  final Paint _pupilPaint;
  final Paint _glintPaint;
  final Paint _haloPaint;

  EyeRuntimeState get currentState =>
      stateSource?.state ??
      EyeRuntimeState.lerp(
        scene.fromState,
        scene.toState,
        scene.motionCurve.transform(progress.value),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final availableDiameter = math.min(size.width, size.height);
    final safeScale = switch (scene.displayShape) {
      DisplayShape.circle => 0.825,
    };
    final t = scene.motionCurve.transform(progress.value);
    final liveState = stateSource?.state;
    final gazeX =
        liveState?.gazeX ??
        _lerp(scene.fromState.gazeX, scene.toState.gazeX, t);
    final gazeY =
        liveState?.gazeY ??
        _lerp(scene.fromState.gazeY, scene.toState.gazeY, t);
    final leftOpen = _lerp(
      liveState?.leftEyelidOpen ?? scene.fromState.leftEyelidOpen,
      liveState?.leftEyelidOpen ?? scene.toState.leftEyelidOpen,
      liveState == null ? t : 1,
    );
    final rightOpen = _lerp(
      liveState?.rightEyelidOpen ?? scene.fromState.rightEyelidOpen,
      liveState?.rightEyelidOpen ?? scene.toState.rightEyelidOpen,
      liveState == null ? t : 1,
    );
    final pupilScale = _lerp(
      liveState?.pupilScale ?? scene.fromState.pupilScale,
      liveState?.pupilScale ?? scene.toState.pupilScale,
      liveState == null ? t : 1,
    );
    final eyeScaleX = _lerp(
      liveState?.eyeScaleX ?? scene.fromState.eyeScaleX,
      liveState?.eyeScaleX ?? scene.toState.eyeScaleX,
      liveState == null ? t : 1,
    );
    final eyeScaleY = _lerp(
      liveState?.eyeScaleY ?? scene.fromState.eyeScaleY,
      liveState?.eyeScaleY ?? scene.toState.eyeScaleY,
      liveState == null ? t : 1,
    );
    final cornerLift = _lerp(
      liveState?.expressionTilt ?? scene.fromState.expressionTilt,
      liveState?.expressionTilt ?? scene.toState.expressionTilt,
      liveState == null ? t : 1,
    );
    final verticalShift = _lerp(
      liveState?.verticalOffset ?? scene.fromState.verticalOffset,
      liveState?.verticalOffset ?? scene.toState.verticalOffset,
      liveState == null ? t : 1,
    );

    _eyePaint.color = scene.eyeColor;
    _pupilPaint.color = scene.pupilColor;
    _glintPaint.color = scene.glintColor;
    _haloPaint.color = scene.haloColor;

    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(availableDiameter * safeScale);
    _paintEye(
      canvas,
      centerX: -0.2121,
      centerY: -0.0101 + verticalShift,
      isLeft: true,
      gazeX: gazeX,
      gazeY: gazeY,
      eyelidOpen: leftOpen,
      pupilScale: pupilScale,
      cornerLift: cornerLift,
      eyeScaleX: eyeScaleX * 0.992,
      eyeScaleY: eyeScaleY * 1.006,
    );
    _paintEye(
      canvas,
      centerX: 0.2121,
      centerY: -0.0101 + verticalShift,
      isLeft: false,
      gazeX: gazeX,
      gazeY: gazeY,
      eyelidOpen: rightOpen,
      pupilScale: pupilScale,
      cornerLift: cornerLift,
      eyeScaleX: eyeScaleX * 1.008,
      eyeScaleY: eyeScaleY * 0.994,
    );
    canvas.restore();
  }

  void _paintEye(
    Canvas canvas, {
    required double centerX,
    required double centerY,
    required bool isLeft,
    required double gazeX,
    required double gazeY,
    required double eyelidOpen,
    required double pupilScale,
    required double cornerLift,
    required double eyeScaleX,
    required double eyeScaleY,
  }) {
    final eyeRotation = cornerLift * (isLeft ? -1 : 1);
    final openScale = math.max(0.035, eyelidOpen);

    canvas
      ..save()
      ..translate(centerX, centerY)
      ..rotate(eyeRotation)
      ..scale(eyeScaleX * 1.1, eyeScaleY * openScale * 1.1)
      ..drawRRect(_eyeShape, _haloPaint)
      ..restore()
      ..save()
      ..translate(centerX, centerY)
      ..rotate(eyeRotation)
      ..scale(eyeScaleX, eyeScaleY * openScale)
      ..drawRRect(_eyeShape, _eyePaint)
      ..restore()
      ..save()
      ..translate(centerX + gazeX * 0.0505, centerY + gazeY * 0.0404)
      ..scale(pupilScale, pupilScale * openScale)
      ..drawRRect(_pupilShape, _pupilPaint)
      ..translate(isLeft ? 0.0152 : -0.0152, -0.0303)
      ..drawCircle(Offset.zero, 0.0152, _glintPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(ProceduralEyePainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.stateSource != stateSource;

  @override
  bool shouldRebuildSemantics(ProceduralEyePainter oldDelegate) => false;
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
