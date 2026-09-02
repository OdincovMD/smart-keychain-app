import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../domain/eyes/eye_behaviour_engine.dart';
import '../../../domain/eyes/eye_emotion.dart';
import '../../../domain/eyes/eye_runtime_state.dart';
import '../eye_preview_controller.dart';

final class ProceduralEyesView extends ConsumerStatefulWidget {
  const ProceduralEyesView({
    required this.initialEmotion,
    this.animate = true,
    super.key,
  });

  final EyeEmotion initialEmotion;
  final bool animate;

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
    if (widget.animate) {
      _engine = EyeBehaviourEngine(ref.read(eyeRandomProvider));
    }
    _settledState = EyeRuntimeState.resting(widget.initialEmotion);
    _fromState = _settledState;
    _toState = _settledState;
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
      _snapTo(EyeRuntimeState.resting(_settledState.emotion));
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
      ref.listen(
        eyePreviewControllerProvider.select((state) => state.emotion),
        (previous, next) => _changeEmotion(next),
      );
      ref.listen(
        eyePreviewControllerProvider.select((state) => state.blinkRevision),
        (previous, next) {
          if (previous != null && next > previous) _requestBlink();
        },
      );
    }

    final scene = EyePaintScene(
      fromState: _fromState,
      toState: _toState,
      eyeColor: AppColors.mint,
      pupilColor: AppColors.background,
      glintColor: AppColors.amber,
      haloColor: AppColors.mint.withValues(alpha: 0.16),
    );

    return ColoredBox(
      color: Colors.black,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const Key('procedural_eyes_painter'),
            painter: ProceduralEyePainter(scene, progress: _controller),
            isComplex: false,
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
      GazeEyeAction() => await _runGaze(action, revision),
      BlinkEyeAction() => await _runBlink(action, revision),
    };
    if (completed && revision == _sequenceRevision) _scheduleNext();
  }

  Future<bool> _runGaze(GazeEyeAction action, int revision) async {
    final target = EyeRuntimeState.resting(_settledState.emotion)
        .copyWith(gazeX: action.targetX, gazeY: action.targetY);
    if (!await _animateTo(target, action.moveDuration, revision)) return false;
    if (!await _wait(action.holdDuration, revision)) return false;
    return _animateTo(
      EyeRuntimeState.resting(_settledState.emotion),
      action.returnDuration,
      revision,
    );
  }

  Future<bool> _runBlink(BlinkEyeAction action, int revision) async {
    final count = action.isDouble ? 2 : 1;
    for (var index = 0; index < count; index++) {
      final closed = _settledState.copyWith(eyelidOpen: 0.04);
      if (!await _animateTo(closed, BlinkEyeAction.closeDuration, revision)) {
        return false;
      }
      if (!await _wait(BlinkEyeAction.closedDuration, revision)) return false;
      if (!await _animateTo(
        EyeRuntimeState.resting(_settledState.emotion),
        BlinkEyeAction.openDuration,
        revision,
      )) {
        return false;
      }
      if (index + 1 < count &&
          !await _wait(BlinkEyeAction.doubleBlinkGap, revision)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _animateTo(
    EyeRuntimeState target,
    Duration duration,
    int revision,
  ) async {
    if (!_motionEnabled || revision != _sequenceRevision) return false;
    _settledState = _currentState;
    setState(() {
      _fromState = _settledState;
      _toState = target;
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
    if (_settledState.emotion == emotion && _toState.emotion == emotion) return;
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
      const Duration(milliseconds: 180),
      revision,
    );
    if (completed && revision == _sequenceRevision) _scheduleNext();
  }

  void _requestBlink() {
    if (!_motionEnabled) return;
    _cancelSequence();
    final revision = _sequenceRevision;
    unawaited(_runManualBlink(revision));
  }

  Future<void> _runManualBlink(int revision) async {
    final completed = await _runBlink(_engine!.forceBlink(), revision);
    if (completed && revision == _sequenceRevision) _scheduleNext();
  }

  EyeRuntimeState get _currentState {
    final progress = Curves.easeInOutCubic.transform(_controller.value);
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
    required this.eyeColor,
    required this.pupilColor,
    required this.glintColor,
    required this.haloColor,
  });

  final EyeRuntimeState fromState;
  final EyeRuntimeState toState;
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
          eyeColor == other.eyeColor &&
          pupilColor == other.pupilColor &&
          glintColor == other.glintColor &&
          haloColor == other.haloColor;

  @override
  int get hashCode => Object.hash(
    fromState,
    toState,
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
    const Rect.fromLTWH(-26, -34, 52, 68),
    const Radius.circular(24),
  );
  static final RRect _pupilShape = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-8, -14, 16, 28),
    const Radius.circular(8),
  );

  final EyePaintScene scene;
  final Animation<double> progress;
  final Paint _eyePaint;
  final Paint _pupilPaint;
  final Paint _glintPaint;
  final Paint _haloPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 240;
    final originX = (size.width - 240 * scale) / 2;
    final originY = (size.height - 240 * scale) / 2;
    final t = Curves.easeInOutCubic.transform(progress.value);
    final gazeX = _lerp(scene.fromState.gazeX, scene.toState.gazeX, t);
    final gazeY = _lerp(scene.fromState.gazeY, scene.toState.gazeY, t);
    final eyelidOpen = _lerp(
      scene.fromState.eyelidOpen,
      scene.toState.eyelidOpen,
      t,
    );
    final pupilScale = _lerp(
      scene.fromState.pupilScale,
      scene.toState.pupilScale,
      t,
    );
    final cornerLift = _lerp(
      _cornerLift(scene.fromState.emotion),
      _cornerLift(scene.toState.emotion),
      t,
    );
    final eyeScale = _lerp(
      _eyeScale(scene.fromState.emotion),
      _eyeScale(scene.toState.emotion),
      t,
    );
    final verticalShift = _lerp(
      _verticalShift(scene.fromState.emotion),
      _verticalShift(scene.toState.emotion),
      t,
    );

    _eyePaint.color = scene.eyeColor;
    _pupilPaint.color = scene.pupilColor;
    _glintPaint.color = scene.glintColor;
    _haloPaint.color = scene.haloColor;

    canvas
      ..save()
      ..translate(originX, originY)
      ..scale(scale);
    _paintEye(
      canvas,
      centerX: 78,
      centerY: 118 + verticalShift,
      isLeft: true,
      gazeX: gazeX,
      gazeY: gazeY,
      eyelidOpen: eyelidOpen,
      pupilScale: pupilScale,
      cornerLift: cornerLift,
      eyeScale: eyeScale,
    );
    _paintEye(
      canvas,
      centerX: 162,
      centerY: 118 + verticalShift,
      isLeft: false,
      gazeX: gazeX,
      gazeY: gazeY,
      eyelidOpen: eyelidOpen,
      pupilScale: pupilScale,
      cornerLift: cornerLift,
      eyeScale: eyeScale,
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
    required double eyeScale,
  }) {
    final eyeRotation = cornerLift * (isLeft ? -1 : 1);
    final openScale = math.max(0.04, eyelidOpen);

    canvas
      ..save()
      ..translate(centerX, centerY)
      ..rotate(eyeRotation)
      ..scale(eyeScale * 1.1, openScale * 1.1)
      ..drawRRect(_eyeShape, _haloPaint)
      ..restore()
      ..save()
      ..translate(centerX, centerY)
      ..rotate(eyeRotation)
      ..scale(eyeScale, openScale)
      ..drawRRect(_eyeShape, _eyePaint)
      ..restore()
      ..save()
      ..translate(centerX + gazeX * 10, centerY + gazeY * 8)
      ..scale(pupilScale, pupilScale * openScale)
      ..drawRRect(_pupilShape, _pupilPaint)
      ..translate(3, -6)
      ..drawCircle(Offset.zero, 3, _glintPaint)
      ..restore();
  }

  static double _cornerLift(EyeEmotion emotion) {
    return switch (emotion) {
      EyeEmotion.happy => 0.11,
      EyeEmotion.sleepy => -0.035,
      _ => 0,
    };
  }

  static double _eyeScale(EyeEmotion emotion) {
    return emotion == EyeEmotion.surprised ? 1.08 : 1;
  }

  static double _verticalShift(EyeEmotion emotion) {
    return switch (emotion) {
      EyeEmotion.happy => -2,
      EyeEmotion.sleepy => 4,
      _ => 0,
    };
  }

  @override
  bool shouldRepaint(ProceduralEyePainter oldDelegate) =>
      oldDelegate.scene != scene;

  @override
  bool shouldRebuildSemantics(ProceduralEyePainter oldDelegate) => false;
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
