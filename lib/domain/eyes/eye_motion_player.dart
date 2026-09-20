import 'dart:math' as math;

import 'eye_behaviour_engine.dart';
import 'eye_emotion.dart';
import 'eye_motion_clip.dart';
import 'eye_motion_definition.dart';
import 'eye_motion_library.dart';
import 'eye_motion_transition.dart';
import 'eye_runtime_state.dart';

enum EyeMotionPlaybackStatus { playing, paused, stopped }

enum EyeMotionPlayerPhase { idle, transition, hold, behaviour, moodTransition }

final class EyeMotionClipSample {
  const EyeMotionClipSample({
    required this.state,
    required this.phase,
    required this.elapsed,
    required this.completed,
  });

  final EyeRuntimeState state;
  final EyeMotionPlayerPhase phase;
  final Duration elapsed;
  final bool completed;
}

abstract final class EyeMotionClipSampler {
  static EyeMotionClipSample sample({
    required EyeMotionDefinition definition,
    required EyeMotionClip clip,
    required Duration elapsed,
    required EyeRuntimeState base,
    required EyeRuntimeState initial,
  }) {
    final total = clip.duration.inMicroseconds;
    if (total <= 0) {
      return EyeMotionClipSample(
        state: initial,
        phase: EyeMotionPlayerPhase.idle,
        elapsed: Duration.zero,
        completed: true,
      );
    }
    final raw = math.max(0, elapsed.inMicroseconds);
    final int position;
    final completed =
        clip.playbackMode == EyeMotionPlaybackMode.once && raw >= total;
    switch (clip.playbackMode) {
      case EyeMotionPlaybackMode.once:
        position = math.min(raw, total);
      case EyeMotionPlaybackMode.loop:
        position = raw % total;
      case EyeMotionPlaybackMode.pingPong:
        final cycle = raw % (total * 2);
        position = cycle <= total ? cycle : total * 2 - cycle;
    }

    var cursor = 0;
    var from = clip.playbackMode == EyeMotionPlaybackMode.loop && raw >= total
        ? definition.poses[clip.steps.last.pose]!.applyTo(base)
        : initial;
    for (final step in clip.steps) {
      final target = definition.poses[step.pose]!.applyTo(base);
      final transitionEnd = cursor + step.transition.inMicroseconds;
      if (position <= transitionEnd && step.transition > Duration.zero) {
        final progress = (position - cursor) / step.transition.inMicroseconds;
        final transformed = transformEyeMotionProgress(
          step.transitionStyle,
          progress,
        );
        return EyeMotionClipSample(
          state: EyeRuntimeState.lerp(from, target, transformed),
          phase: EyeMotionPlayerPhase.transition,
          elapsed: Duration(microseconds: position),
          completed: completed,
        );
      }
      cursor = transitionEnd;
      final holdEnd = cursor + step.hold.inMicroseconds;
      if (position <= holdEnd) {
        return EyeMotionClipSample(
          state: target,
          phase: EyeMotionPlayerPhase.hold,
          elapsed: Duration(microseconds: position),
          completed: completed,
        );
      }
      cursor = holdEnd;
      from = target;
    }
    return EyeMotionClipSample(
      state: from,
      phase: EyeMotionPlayerPhase.idle,
      elapsed: Duration(microseconds: position),
      completed: completed,
    );
  }
}

final class EyeMotionPlayer {
  EyeMotionPlayer({
    required EyeBehaviourEngine behaviourEngine,
    EyeMotionDefinition? definition,
    EyeMood initialMood = EyeEmotion.neutral,
    String initialClip = ChromeKissEyeClips.neutralIdle,
  }) : _engine = behaviourEngine,
       definition = definition ?? chromeKissEyeMotionDefinition,
       _mood = initialMood,
       _baseState = EyeRuntimeState.resting(initialMood),
       _state = EyeRuntimeState.resting(initialMood),
       _clipName = initialClip {
    _engine.setMood(initialMood);
    _authoredStart = _state;
    _scheduleNextBehaviour();
  }

  final EyeBehaviourEngine _engine;
  final EyeMotionDefinition definition;
  EyeMood _mood;
  late EyeRuntimeState _baseState;
  late EyeRuntimeState _state;
  late EyeRuntimeState _authoredStart;
  String _clipName;
  Duration _clipElapsed = Duration.zero;
  EyeMotionPlaybackStatus _status = EyeMotionPlaybackStatus.playing;
  EyeMotionPlayerPhase _phase = EyeMotionPlayerPhase.idle;
  double _speed = 1;

  EyeBehaviourAction? _scheduledAction;
  Duration _behaviourDelay = Duration.zero;
  EyeBehaviourAction? _activeAction;
  Duration _actionElapsed = Duration.zero;
  bool _initialBlinkPending = true;

  EyeRuntimeState? _moodTransitionFrom;
  EyeRuntimeState? _moodTransitionTo;
  Duration _moodTransitionElapsed = Duration.zero;
  Duration _moodTransitionDuration = Duration.zero;
  EyeRuntimeState? _interruptionFrom;
  Duration _interruptionElapsed = Duration.zero;
  static const _interruptionDuration = Duration(milliseconds: 80);

  EyeRuntimeState get state => _state;
  EyeMood get mood => _mood;
  String get clipName => _clipName;
  Duration get elapsed => _clipElapsed;
  EyeMotionPlaybackStatus get status => _status;
  EyeMotionPlayerPhase get phase => _phase;
  double get speed => _speed;

  void advance(Duration delta) {
    if (_status != EyeMotionPlaybackStatus.playing || delta <= Duration.zero) {
      return;
    }
    final scaled = Duration(
      microseconds: (delta.inMicroseconds * _speed).round(),
    );
    if (_moodTransitionTo != null) {
      _advanceMoodTransition(scaled);
      return;
    }

    _clipElapsed += scaled;
    final clip = definition.clips[_clipName];
    if (clip == null) {
      _state = _baseState;
      _phase = EyeMotionPlayerPhase.idle;
      return;
    }
    final authored = EyeMotionClipSampler.sample(
      definition: definition,
      clip: clip,
      elapsed: _clipElapsed,
      base: _baseState,
      initial: _authoredStart,
    );
    final overlay = _advanceBehaviour(scaled, clip.blinkPolicy);
    final composed = _compose(authored.state, overlay);
    _state = _applyInterruptionBlend(composed, scaled);
    _phase = overlay == null ? authored.phase : EyeMotionPlayerPhase.behaviour;
  }

  void play(String clipName) {
    if (!definition.clips.containsKey(clipName)) return;
    _beginInterruption();
    _authoredStart = _state;
    _clipName = clipName;
    _clipElapsed = Duration.zero;
    _status = EyeMotionPlaybackStatus.playing;
    _clearAction();
    _initialBlinkPending = true;
    _scheduleNextBehaviour();
  }

  void restart() => play(_clipName);

  void pause() {
    if (_status == EyeMotionPlaybackStatus.playing) {
      _status = EyeMotionPlaybackStatus.paused;
    }
  }

  void resume() {
    if (_status != EyeMotionPlaybackStatus.playing) {
      _status = EyeMotionPlaybackStatus.playing;
    }
  }

  void stop({bool snapToMood = false}) {
    _status = EyeMotionPlaybackStatus.stopped;
    _clearAction();
    if (snapToMood) {
      _state = _baseState;
      _authoredStart = _baseState;
      _clipElapsed = Duration.zero;
      _phase = EyeMotionPlayerPhase.idle;
    }
  }

  void setSpeed(double speed) {
    if (!speed.isFinite || speed <= 0 || speed > 4) return;
    _speed = speed;
  }

  void setMood(
    EyeMood mood, {
    Duration transition = const Duration(milliseconds: 220),
  }) {
    if (_mood == mood && _moodTransitionTo == null) return;
    _mood = mood;
    _engine.setMood(mood);
    _moodTransitionFrom = _state;
    _moodTransitionTo = EyeRuntimeState.resting(mood);
    _moodTransitionElapsed = Duration.zero;
    _moodTransitionDuration = transition;
    _status = EyeMotionPlaybackStatus.playing;
    _clearAction();
    _phase = EyeMotionPlayerPhase.moodTransition;
  }

  void snapToMood(EyeMood mood) {
    _mood = mood;
    _engine.setMood(mood);
    _baseState = EyeRuntimeState.resting(mood);
    _state = _baseState;
    _authoredStart = _baseState;
    _clipElapsed = Duration.zero;
    _moodTransitionFrom = null;
    _moodTransitionTo = null;
    _interruptionFrom = null;
    _phase = EyeMotionPlayerPhase.idle;
    _clearAction();
  }

  void trigger(EyeBehaviourAction action) {
    _beginInterruption();
    _activeAction = action;
    _actionElapsed = Duration.zero;
    _scheduledAction = null;
    _behaviourDelay = Duration.zero;
    _status = EyeMotionPlaybackStatus.playing;
  }

  void _beginInterruption() {
    _interruptionFrom = _state;
    _interruptionElapsed = Duration.zero;
  }

  EyeRuntimeState _applyInterruptionBlend(
    EyeRuntimeState target,
    Duration delta,
  ) {
    final from = _interruptionFrom;
    if (from == null) return target;
    _interruptionElapsed += delta;
    final progress = _durationProgress(
      _interruptionElapsed,
      _interruptionDuration,
    );
    final state = EyeRuntimeState.lerp(
      from,
      target,
      transformEyeMotionProgress(EyeMotionTransitionStyle.easeOut, progress),
    );
    if (progress >= 1) _interruptionFrom = null;
    return state;
  }

  void _advanceMoodTransition(Duration delta) {
    _moodTransitionElapsed += delta;
    final target = _moodTransitionTo!;
    final duration = _moodTransitionDuration.inMicroseconds;
    final progress = duration == 0
        ? 1.0
        : _moodTransitionElapsed.inMicroseconds / duration;
    _state = EyeRuntimeState.lerp(
      _moodTransitionFrom!,
      target,
      transformEyeMotionProgress(EyeMotionTransitionStyle.easeInOut, progress),
    );
    _phase = EyeMotionPlayerPhase.moodTransition;
    if (progress < 1) return;
    _baseState = target;
    _state = target;
    _authoredStart = target;
    _clipElapsed = Duration.zero;
    _moodTransitionFrom = null;
    _moodTransitionTo = null;
    _scheduleNextBehaviour();
  }

  _EyeBehaviourOverlay? _advanceBehaviour(
    Duration delta,
    EyeMotionBlinkPolicy blinkPolicy,
  ) {
    if (_activeAction == null) {
      _behaviourDelay -= delta;
      if (_behaviourDelay > Duration.zero) return null;
      final next = _scheduledAction;
      if (next == null) {
        _scheduleNextBehaviour();
        return null;
      }
      if (next is BlinkEyeAction &&
          blinkPolicy != EyeMotionBlinkPolicy.natural) {
        _scheduleNextBehaviour();
        return null;
      }
      _activeAction = next;
      _actionElapsed = -_behaviourDelay;
      _scheduledAction = null;
    } else {
      _actionElapsed += delta;
    }

    final overlay = _sampleAction(
      _activeAction!,
      _actionElapsed,
      _engine.moodProfile.restingGazeY,
    );
    if (!overlay.completed) return overlay;
    _clearAction();
    _scheduleNextBehaviour();
    return null;
  }

  void _scheduleNextBehaviour() {
    final clip = definition.clips[_clipName];
    final configuration = clip?.blinkConfiguration;
    final action =
        configuration != null &&
            clip!.blinkPolicy == EyeMotionBlinkPolicy.natural
        ? _initialBlinkPending
              ? _engine.forceBlink(
                  delay: configuration.initialDelay,
                  duration: configuration.duration,
                )
              : _engine.scheduledBlink(
                  minimumDelay: configuration.minimumInterval,
                  maximumDelay: configuration.maximumInterval,
                  duration: configuration.duration,
                )
        : _engine.nextAction();
    if (configuration != null &&
        clip!.blinkPolicy == EyeMotionBlinkPolicy.natural) {
      _initialBlinkPending = false;
    }
    _scheduledAction = action;
    _behaviourDelay = action.delay;
  }

  void _clearAction() {
    _activeAction = null;
    _actionElapsed = Duration.zero;
    _scheduledAction = null;
    _behaviourDelay = Duration.zero;
  }

  EyeRuntimeState _compose(
    EyeRuntimeState authored,
    _EyeBehaviourOverlay? overlay,
  ) {
    if (overlay == null) return _safe(authored);
    final response = switch (_mood) {
      EyeEmotion.curious => 1.045,
      EyeEmotion.surprised => 0.94,
      _ => 1.0,
    };
    return _safe(
      authored.copyWith(
        gazeX: authored.gazeX + overlay.gazeX,
        gazeY: authored.gazeY + overlay.gazeY,
        leftEyelidOpen: authored.leftEyelidOpen * overlay.leftEyelidFactor,
        rightEyelidOpen: authored.rightEyelidOpen * overlay.rightEyelidFactor,
        pupilScale: authored.pupilScale * overlay.pupilFactor * response,
        eyeScaleX: authored.eyeScaleX * overlay.eyeScaleXFactor,
        eyeScaleY: authored.eyeScaleY * overlay.eyeScaleYFactor,
        velocityX: overlay.velocityX,
        velocityY: overlay.velocityY,
        motionPhase: overlay.motionPhase,
      ),
    );
  }
}

final class _EyeBehaviourOverlay {
  const _EyeBehaviourOverlay({
    this.gazeX = 0,
    this.gazeY = 0,
    this.leftEyelidFactor = 1,
    this.rightEyelidFactor = 1,
    this.pupilFactor = 1,
    this.eyeScaleXFactor = 1,
    this.eyeScaleYFactor = 1,
    this.velocityX = 0,
    this.velocityY = 0,
    this.motionPhase = EyeMotionPhase.idle,
    this.completed = false,
  });

  final double gazeX;
  final double gazeY;
  final double leftEyelidFactor;
  final double rightEyelidFactor;
  final double pupilFactor;
  final double eyeScaleXFactor;
  final double eyeScaleYFactor;
  final double velocityX;
  final double velocityY;
  final EyeMotionPhase motionPhase;
  final bool completed;
}

_EyeBehaviourOverlay _sampleAction(
  EyeBehaviourAction action,
  Duration elapsed,
  double restingGazeY,
) {
  return switch (action) {
    IdleEyeAction() => const _EyeBehaviourOverlay(completed: true),
    GazeEyeAction() => _sampleGaze(action, elapsed, restingGazeY),
    BlinkEyeAction() => _sampleBlink(action, elapsed),
    SpecialEyeAction() => _sampleSpecial(elapsed),
  };
}

_EyeBehaviourOverlay _sampleGaze(
  GazeEyeAction action,
  Duration elapsed,
  double restingGazeY,
) {
  final targetY = action.targetY - restingGazeY;
  final points =
      <({Duration duration, double x, double y, EyeMotionPhase phase})>[
        (
          duration: action.anticipationDuration,
          x: action.anticipationX,
          y: action.anticipationY - restingGazeY,
          phase: EyeMotionPhase.anticipation,
        ),
        (
          duration: action.moveDuration,
          x: action.targetX,
          y: targetY,
          phase: EyeMotionPhase.moving,
        ),
        (
          duration: action.overshootDuration,
          x: action.overshootX,
          y: action.overshootY - restingGazeY,
          phase: EyeMotionPhase.overshoot,
        ),
        (
          duration: action.settleDuration,
          x: action.targetX,
          y: targetY,
          phase: EyeMotionPhase.settling,
        ),
      ];
  var cursor = Duration.zero;
  var fromX = 0.0;
  var fromY = 0.0;
  for (final point in points) {
    final end = cursor + point.duration;
    if (elapsed <= end) {
      final t = _durationProgress(elapsed - cursor, point.duration);
      final eased = transformEyeMotionProgress(
        point.phase == EyeMotionPhase.anticipation
            ? EyeMotionTransitionStyle.easeIn
            : EyeMotionTransitionStyle.easeOut,
        t,
      );
      return _EyeBehaviourOverlay(
        gazeX: _lerp(fromX, point.x, eased),
        gazeY: _lerp(fromY, point.y, eased),
        velocityX: point.x - fromX,
        velocityY: point.y - fromY,
        motionPhase: point.phase,
      );
    }
    cursor = end;
    fromX = point.x;
    fromY = point.y;
  }
  final holdEnd = cursor + action.holdDuration;
  if (elapsed <= holdEnd) {
    return _EyeBehaviourOverlay(
      gazeX: action.targetX,
      gazeY: targetY,
      motionPhase: EyeMotionPhase.settling,
    );
  }
  final returnElapsed = elapsed - holdEnd;
  if (returnElapsed <= action.returnDuration) {
    final t = transformEyeMotionProgress(
      EyeMotionTransitionStyle.easeInOut,
      _durationProgress(returnElapsed, action.returnDuration),
    );
    return _EyeBehaviourOverlay(
      gazeX: _lerp(action.targetX, 0, t),
      gazeY: _lerp(targetY, 0, t),
      motionPhase: EyeMotionPhase.settling,
    );
  }
  return const _EyeBehaviourOverlay(completed: true);
}

_EyeBehaviourOverlay _sampleBlink(BlinkEyeAction action, Duration elapsed) {
  const anticipation = Duration(milliseconds: 34);
  var cursor = Duration.zero;
  for (var blink = 0; blink < action.count; blink++) {
    final anticipationEnd = cursor + anticipation;
    if (elapsed <= anticipationEnd) {
      final lift = _lerp(
        1,
        1.025,
        _durationProgress(elapsed - cursor, anticipation),
      );
      return _EyeBehaviourOverlay(
        leftEyelidFactor: lift,
        rightEyelidFactor: lift,
        motionPhase: EyeMotionPhase.anticipation,
      );
    }
    cursor = anticipationEnd;
    final leadEnd = cursor + action.asymmetryDelay;
    if (elapsed <= leadEnd) {
      final lead = _lerp(
        1.025,
        0.72,
        _durationProgress(elapsed - cursor, action.asymmetryDelay),
      );
      return _EyeBehaviourOverlay(
        leftEyelidFactor: action.leftLeads ? lead : 1.025,
        rightEyelidFactor: action.leftLeads ? 1.025 : lead,
        motionPhase: EyeMotionPhase.closing,
      );
    }
    cursor = leadEnd;
    final closeEnd = cursor + action.effectiveCloseDuration;
    if (elapsed <= closeEnd) {
      final t = transformEyeMotionProgress(
        EyeMotionTransitionStyle.easeIn,
        _durationProgress(elapsed - cursor, action.effectiveCloseDuration),
      );
      return _EyeBehaviourOverlay(
        leftEyelidFactor: _lerp(action.leftLeads ? 0.72 : 1.025, 0.04, t),
        rightEyelidFactor: _lerp(action.leftLeads ? 1.025 : 0.72, 0.045, t),
        motionPhase: EyeMotionPhase.closing,
      );
    }
    cursor = closeEnd;
    final closedEnd = cursor + action.effectiveClosedDuration;
    if (elapsed <= closedEnd) {
      return const _EyeBehaviourOverlay(
        leftEyelidFactor: 0.04,
        rightEyelidFactor: 0.045,
        motionPhase: EyeMotionPhase.closed,
      );
    }
    cursor = closedEnd;
    final openEnd = cursor + action.effectiveOpenDuration;
    if (elapsed <= openEnd) {
      final t = transformEyeMotionProgress(
        EyeMotionTransitionStyle.easeOut,
        _durationProgress(elapsed - cursor, action.effectiveOpenDuration),
      );
      return _EyeBehaviourOverlay(
        leftEyelidFactor: _lerp(0.04, 1, t),
        rightEyelidFactor: _lerp(0.045, 1, t),
        motionPhase: EyeMotionPhase.opening,
      );
    }
    cursor = openEnd;
    if (blink + 1 < action.count) {
      final gapEnd = cursor + BlinkEyeAction.doubleBlinkGap;
      if (elapsed <= gapEnd) return const _EyeBehaviourOverlay();
      cursor = gapEnd;
    }
  }
  return const _EyeBehaviourOverlay(completed: true);
}

_EyeBehaviourOverlay _sampleSpecial(Duration elapsed) {
  const first = Duration(milliseconds: 210);
  const hold = Duration(milliseconds: 130);
  const second = Duration(milliseconds: 270);
  const settle = Duration(milliseconds: 180);
  const end = Duration(milliseconds: 290);
  if (elapsed <= first) {
    final t = transformEyeMotionProgress(
      EyeMotionTransitionStyle.easeOut,
      _durationProgress(elapsed, first),
    );
    return _EyeBehaviourOverlay(
      gazeX: _lerp(0, 0.28, t),
      gazeY: _lerp(0, -0.42, t),
      pupilFactor: _lerp(1, 0.84, t),
      eyeScaleXFactor: _lerp(1, 1.045, t),
      eyeScaleYFactor: _lerp(1, 1.06, t),
      motionPhase: EyeMotionPhase.special,
    );
  }
  if (elapsed <= first + hold) {
    return const _EyeBehaviourOverlay(
      gazeX: 0.28,
      gazeY: -0.42,
      pupilFactor: 0.84,
      eyeScaleXFactor: 1.045,
      eyeScaleYFactor: 1.06,
      motionPhase: EyeMotionPhase.special,
    );
  }
  final secondStart = first + hold;
  if (elapsed <= secondStart + second) {
    final t = transformEyeMotionProgress(
      EyeMotionTransitionStyle.easeInOut,
      _durationProgress(elapsed - secondStart, second),
    );
    return _EyeBehaviourOverlay(
      gazeX: _lerp(0.28, -0.52, t),
      gazeY: _lerp(-0.42, -0.12, t),
      pupilFactor: _lerp(0.84, 1.1, t),
      rightEyelidFactor: _lerp(1, 0.92, t),
      motionPhase: EyeMotionPhase.special,
    );
  }
  final settleStart = secondStart + second;
  if (elapsed <= settleStart + settle) {
    final t = transformEyeMotionProgress(
      EyeMotionTransitionStyle.easeOut,
      _durationProgress(elapsed - settleStart, settle),
    );
    return _EyeBehaviourOverlay(
      gazeX: _lerp(-0.52, 0.12, t),
      gazeY: _lerp(-0.12, 0.12, t),
      pupilFactor: _lerp(1.1, 1, t),
      rightEyelidFactor: _lerp(0.92, 1, t),
      motionPhase: EyeMotionPhase.settling,
    );
  }
  final endStart = settleStart + settle;
  if (elapsed <= endStart + end) {
    final t = transformEyeMotionProgress(
      EyeMotionTransitionStyle.easeInOut,
      _durationProgress(elapsed - endStart, end),
    );
    return _EyeBehaviourOverlay(
      gazeX: _lerp(0.12, 0, t),
      gazeY: _lerp(0.12, 0, t),
      motionPhase: EyeMotionPhase.settling,
    );
  }
  return const _EyeBehaviourOverlay(completed: true);
}

EyeRuntimeState _safe(EyeRuntimeState state) {
  return EyeRuntimeState(
    gazeX: _finite(state.gazeX, 0).clamp(-1.0, 1.0),
    gazeY: _finite(state.gazeY, 0).clamp(-1.0, 1.0),
    leftEyelidOpen: _finite(state.leftEyelidOpen, 1).clamp(0.0, 1.0),
    rightEyelidOpen: _finite(state.rightEyelidOpen, 1).clamp(0.0, 1.0),
    pupilScale: _finite(state.pupilScale, 1).clamp(0.55, 1.35),
    eyeScaleX: _finite(state.eyeScaleX, 1).clamp(0.65, 1.35),
    eyeScaleY: _finite(state.eyeScaleY, 1).clamp(0.65, 1.35),
    expressionTilt: _finite(state.expressionTilt, 0).clamp(-0.35, 0.35),
    verticalOffset: _finite(state.verticalOffset, 0).clamp(-0.25, 0.25),
    velocityX: _finite(state.velocityX, 0).clamp(-2.0, 2.0),
    velocityY: _finite(state.velocityY, 0).clamp(-2.0, 2.0),
    motionPhase: state.motionPhase,
    emotion: state.emotion,
  );
}

double _finite(double value, double fallback) =>
    value.isFinite ? value : fallback;

double _durationProgress(Duration elapsed, Duration duration) =>
    duration == Duration.zero
    ? 1
    : (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
