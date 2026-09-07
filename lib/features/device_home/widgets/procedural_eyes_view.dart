import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../domain/device/display_profile.dart';
import '../../../domain/eyes/eye_behaviour_engine.dart';
import '../../../domain/eyes/eye_emotion.dart';
import '../../../domain/eyes/eye_runtime_state.dart';
import '../eye_preview_controller.dart';
import 'kiss_cut_eye_renderer.dart';

final class ProceduralEyesView extends ConsumerStatefulWidget {
  const ProceduralEyesView({
    required this.initialEmotion,
    this.animate = true,
    this.displayProfile,
    this.rendererVariant = EyeRendererVariant.legacy,
    this.kissCutVisualMoodOverride,
    this.kissCutColourway = KissCutColourway.orchidLilac,
    super.key,
  });

  final EyeEmotion initialEmotion;
  final bool animate;
  final DisplayProfile? displayProfile;
  final EyeRendererVariant rendererVariant;
  final KissCutVisualMood? kissCutVisualMoodOverride;
  final KissCutColourway kissCutColourway;

  @override
  ConsumerState<ProceduralEyesView> createState() => _ProceduralEyesViewState();
}

final class _ProceduralEyesViewState extends ConsumerState<ProceduralEyesView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  EyeBehaviourEngine? _engine;
  late EyeRuntimeState _fromState;
  late EyeRuntimeState _toState;
  late EyeRuntimeState _settledState;
  Curve _motionCurve = Curves.easeInOutCubic;

  Timer? _timer;
  Completer<bool>? _waitCompleter;
  var _sequenceRevision = 0;
  var _motionEnabled = false;
  var _motionStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );
    _settledState = EyeRuntimeState.resting(widget.initialEmotion);
    _fromState = _settledState;
    _toState = _settledState;
    if (widget.animate) _createEngine();
  }

  void _createEngine({int? seed}) {
    final random = seed == null
        ? ref.read(eyeRandomProvider)
        : math.Random(seed);
    _engine = EyeBehaviourEngine(random, initialMood: _settledState.mood);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextMotionEnabled =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (_motionEnabled == nextMotionEnabled) return;

    _motionEnabled = nextMotionEnabled;
    if (_motionEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _motionEnabled && !_motionStarted) {
          _motionStarted = true;
          _scheduleNext();
        }
      });
    } else {
      _motionStarted = false;
      _cancelSequence();
      _snapTo(EyeRuntimeState.resting(_settledState.mood));
    }
  }

  @override
  void didUpdateWidget(ProceduralEyesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialEmotion != widget.initialEmotion && !widget.animate) {
      _snapTo(EyeRuntimeState.resting(widget.initialEmotion));
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
        );
    }

    final scene = EyePaintScene(
      fromState: _fromState,
      toState: _toState,
      motionCurve: _motionCurve,
      displayShape: widget.displayProfile?.shape ?? DisplayShape.circle,
      eyeColor: AppColors.mint,
      pupilColor: AppColors.background,
      glintColor: AppColors.amber,
      haloColor: AppColors.mint.withValues(alpha: 0.16),
    );
    final painter = switch (widget.rendererVariant) {
      EyeRendererVariant.legacy => ProceduralEyePainter(
        scene,
        progress: _controller,
      ),
      EyeRendererVariant.kissCutV2 => KissCutEyePainter(
        KissCutPaintScene(
          fromState: _fromState,
          toState: _toState,
          motionCurve: _motionCurve,
          displayShape: widget.displayProfile?.shape ?? DisplayShape.circle,
          visualMoodOverride: widget.kissCutVisualMoodOverride,
          colourway: widget.kissCutColourway,
          style: KissCutRendererStyle.v2,
        ),
        progress: _controller,
      ),
      EyeRendererVariant.kissCutV21 => KissCutEyePainter(
        KissCutPaintScene(
          fromState: _fromState,
          toState: _toState,
          motionCurve: _motionCurve,
          displayShape: widget.displayProfile?.shape ?? DisplayShape.circle,
          visualMoodOverride: widget.kissCutVisualMoodOverride,
          colourway: widget.kissCutColourway,
          style: KissCutRendererStyle.v21Pure,
        ),
        progress: _controller,
      ),
    };
    final painterKey = switch (widget.rendererVariant) {
      EyeRendererVariant.legacy => const Key('procedural_eyes_painter'),
      EyeRendererVariant.kissCutV2 ||
      EyeRendererVariant.kissCutV21 => const Key('kiss_cut_eye_painter'),
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

  void _scheduleNext() {
    if (!_motionEnabled || !mounted) return;
    final action = _engine!.nextAction();
    final revision = _sequenceRevision;
    _timer = Timer(action.delay, () {
      if (!mounted || revision != _sequenceRevision) return;
      unawaited(_runAction(action, revision));
    });
  }

  Future<void> _runAction(EyeBehaviourAction action, int revision) async {
    final completed = switch (action) {
      IdleEyeAction() => true,
      GazeEyeAction() => await _runGaze(action, revision),
      BlinkEyeAction() => await _runBlink(action, revision),
      SpecialEyeAction() => await _runSpecialAction(action, revision),
    };
    if (completed && revision == _sequenceRevision) _scheduleNext();
  }

  Future<bool> _runGaze(GazeEyeAction action, int revision) async {
    final resting = EyeRuntimeState.resting(_settledState.mood);
    if (!await _animateTo(
      resting.copyWith(
        gazeX: action.anticipationX,
        gazeY: action.anticipationY,
        velocityX: -action.targetX,
        velocityY: -action.targetY,
        motionPhase: EyeMotionPhase.anticipation,
      ),
      action.anticipationDuration,
      revision,
      curve: Curves.easeInCubic,
    )) {
      return false;
    }
    if (!await _animateTo(
      resting.copyWith(
        gazeX: action.targetX,
        gazeY: action.targetY,
        velocityX: action.targetX,
        velocityY: action.targetY,
        motionPhase: EyeMotionPhase.moving,
      ),
      action.moveDuration,
      revision,
      curve: Curves.easeOutCubic,
    )) {
      return false;
    }
    if (!await _animateTo(
      resting.copyWith(
        gazeX: action.overshootX,
        gazeY: action.overshootY,
        motionPhase: EyeMotionPhase.overshoot,
      ),
      action.overshootDuration,
      revision,
      curve: Curves.easeOutCubic,
    )) {
      return false;
    }
    if (!await _animateTo(
      resting.copyWith(
        gazeX: action.targetX,
        gazeY: action.targetY,
        motionPhase: EyeMotionPhase.settling,
      ),
      action.settleDuration,
      revision,
      curve: Curves.easeOutBack,
    )) {
      return false;
    }
    if (!await _wait(action.holdDuration, revision)) return false;
    if (!action.returnsToCenter) {
      return _animateTo(resting, action.settleDuration, revision);
    }
    return _animateTo(
      resting,
      action.returnDuration,
      revision,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  Future<bool> _runBlink(BlinkEyeAction action, int revision) async {
    final resting = EyeRuntimeState.resting(_settledState.mood);
    for (var index = 0; index < action.count; index++) {
      final leadState = action.leftLeads
          ? resting.copyWith(
              leftEyelidOpen: 0.06,
              motionPhase: EyeMotionPhase.closing,
            )
          : resting.copyWith(
              rightEyelidOpen: 0.06,
              motionPhase: EyeMotionPhase.closing,
            );
      if (!await _animateTo(
        leadState,
        action.asymmetryDelay,
        revision,
        curve: Curves.easeIn,
      )) {
        return false;
      }
      final closed = resting.copyWith(
        leftEyelidOpen: 0.035,
        rightEyelidOpen: 0.045,
        motionPhase: EyeMotionPhase.closed,
      );
      if (!await _animateTo(
        closed,
        action.effectiveCloseDuration,
        revision,
        curve: Curves.easeInCubic,
      )) {
        return false;
      }
      if (!await _wait(action.effectiveClosedDuration, revision)) return false;
      if (!await _animateTo(
        resting.copyWith(motionPhase: EyeMotionPhase.opening),
        action.effectiveOpenDuration,
        revision,
        curve: Curves.easeOutCubic,
      )) {
        return false;
      }
      if (index + 1 < action.count &&
          !await _wait(BlinkEyeAction.doubleBlinkGap, revision)) {
        return false;
      }
    }
    return _animateTo(resting, const Duration(milliseconds: 28), revision);
  }

  Future<bool> _runSpecialAction(SpecialEyeAction action, int revision) async {
    final resting = EyeRuntimeState.resting(_settledState.mood);
    final lifted = resting.copyWith(
      gazeX: 0.28,
      gazeY: -0.42,
      pupilScale: resting.pupilScale * 0.84,
      eyeScaleX: resting.eyeScaleX * 1.045,
      eyeScaleY: resting.eyeScaleY * 1.06,
      leftEyelidOpen: (resting.leftEyelidOpen + 0.035).clamp(0, 1),
      motionPhase: EyeMotionPhase.special,
    );
    if (!await _animateTo(
      lifted,
      const Duration(milliseconds: 210),
      revision,
      curve: Curves.easeOutBack,
    )) {
      return false;
    }
    if (!await _wait(const Duration(milliseconds: 130), revision)) return false;
    if (!await _animateTo(
      lifted.copyWith(
        gazeX: -0.52,
        gazeY: -0.12,
        pupilScale: resting.pupilScale * 1.1,
        rightEyelidOpen: (resting.rightEyelidOpen - 0.06).clamp(0.08, 1),
      ),
      const Duration(milliseconds: 270),
      revision,
      curve: Curves.easeInOutCubicEmphasized,
    )) {
      return false;
    }
    if (!await _animateTo(
      resting.copyWith(
        gazeX: 0.12,
        gazeY: 0.12,
        motionPhase: EyeMotionPhase.settling,
      ),
      const Duration(milliseconds: 180),
      revision,
      curve: Curves.easeOutCubic,
    )) {
      return false;
    }
    return _animateTo(
      resting,
      const Duration(milliseconds: 290),
      revision,
      curve: Curves.easeInOutCubic,
    );
  }

  Future<bool> _animateTo(
    EyeRuntimeState target,
    Duration duration,
    int revision, {
    Curve curve = Curves.easeInOutCubic,
  }) async {
    if (!_motionEnabled || revision != _sequenceRevision) return false;
    _settledState = _currentState;
    setState(() {
      _fromState = _settledState;
      _toState = target;
      _motionCurve = curve;
    });
    _controller.duration = duration;
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      return false;
    }
    if (!mounted || revision != _sequenceRevision) return false;
    _settledState = target;
    return true;
  }

  Future<bool> _wait(Duration duration, int revision) {
    if (!_motionEnabled || revision != _sequenceRevision) {
      return Future<bool>.value(false);
    }
    final completer = Completer<bool>();
    _waitCompleter = completer;
    _timer = Timer(duration, () {
      if (_waitCompleter == completer) _waitCompleter = null;
      completer.complete(mounted && revision == _sequenceRevision);
    });
    return completer.future;
  }

  void _changeEmotion(EyeEmotion emotion) {
    if (_settledState.mood == emotion && _toState.mood == emotion) return;
    _engine?.setMood(emotion);
    _cancelSequence();
    final target = EyeRuntimeState.resting(emotion);
    if (!_motionEnabled) {
      _snapTo(target);
      return;
    }
    final revision = _sequenceRevision;
    unawaited(_transitionEmotion(target, revision));
  }

  Future<void> _transitionEmotion(EyeRuntimeState target, int revision) async {
    final completed = await _animateTo(
      target,
      const Duration(milliseconds: 220),
      revision,
      curve: Curves.easeInOutCubic,
    );
    if (completed && revision == _sequenceRevision) _scheduleNext();
  }

  void _changeRandomSeed(int? seed) {
    if (!widget.animate) return;
    _cancelSequence();
    _createEngine(seed: seed);
    if (_motionEnabled) _scheduleNext();
  }

  void _requestCommand(EyeDebugCommand command) {
    if (!_motionEnabled) return;
    _cancelSequence();
    final action = switch (command) {
      EyeDebugCommand.blink => _engine!.forceBlink(),
      EyeDebugCommand.doubleBlink => _engine!.forceBlink(
        variant: EyeBlinkVariant.doubleBlink,
      ),
      EyeDebugCommand.lookLeft => _engine!.look(EyeLookDirection.left),
      EyeDebugCommand.lookRight => _engine!.look(EyeLookDirection.right),
      EyeDebugCommand.specialAction => _engine!.playSpecialAction(
        EyeSpecialAction.fireflySearch,
      ),
    };
    final revision = _sequenceRevision;
    unawaited(_runAction(action, revision));
  }

  EyeRuntimeState get _currentState {
    final progress = _motionCurve.transform(_controller.value);
    return EyeRuntimeState.lerp(_fromState, _toState, progress);
  }

  void _cancelSequence() {
    _sequenceRevision++;
    _timer?.cancel();
    _timer = null;
    final completer = _waitCompleter;
    _waitCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(false);
    _settledState = _currentState;
    _controller.stop();
  }

  void _snapTo(EyeRuntimeState state) {
    _settledState = state;
    _controller.value = 1;
    if (!mounted) {
      _fromState = state;
      _toState = state;
      return;
    }
    setState(() {
      _fromState = state;
      _toState = state;
      _motionCurve = Curves.linear;
    });
  }

  @override
  void dispose() {
    _sequenceRevision++;
    _timer?.cancel();
    final completer = _waitCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(false);
    _controller.dispose();
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
  ProceduralEyePainter(this.scene, {required this.progress})
    : _eyePaint = Paint()..style = PaintingStyle.fill,
      _pupilPaint = Paint()..style = PaintingStyle.fill,
      _glintPaint = Paint()..style = PaintingStyle.fill,
      _haloPaint = Paint()..style = PaintingStyle.fill,
      super(repaint: progress);

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
  final Paint _eyePaint;
  final Paint _pupilPaint;
  final Paint _glintPaint;
  final Paint _haloPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final availableDiameter = math.min(size.width, size.height);
    final safeScale = switch (scene.displayShape) {
      DisplayShape.circle => 0.825,
    };
    final t = scene.motionCurve.transform(progress.value);
    final gazeX = _lerp(scene.fromState.gazeX, scene.toState.gazeX, t);
    final gazeY = _lerp(scene.fromState.gazeY, scene.toState.gazeY, t);
    final leftOpen = _lerp(
      scene.fromState.leftEyelidOpen,
      scene.toState.leftEyelidOpen,
      t,
    );
    final rightOpen = _lerp(
      scene.fromState.rightEyelidOpen,
      scene.toState.rightEyelidOpen,
      t,
    );
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
    final cornerLift = _lerp(
      scene.fromState.expressionTilt,
      scene.toState.expressionTilt,
      t,
    );
    final verticalShift = _lerp(
      scene.fromState.verticalOffset,
      scene.toState.verticalOffset,
      t,
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
      oldDelegate.scene != scene;

  @override
  bool shouldRebuildSemantics(ProceduralEyePainter oldDelegate) => false;
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
