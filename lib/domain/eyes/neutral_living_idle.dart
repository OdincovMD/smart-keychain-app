import 'dart:math' as math;

enum EyeLivingIdlePhase {
  resting,
  gazeTransition,
  gazeDwell,
  microSaccade,
  blink,
  signature,
  suspended,
}

enum EyeLivingIdleSchedulerState {
  waiting,
  movingToInterest,
  holdingInterest,
  microBurst,
  blinking,
  signatureReady,
  suspended,
}

enum EyeLivingBlinkType { natural, doubleBlink, slow }

enum EyeNeutralSignature { curiousGlance, softCenterBlink, sideHoldReturn }

final class EyeLivingIdleConfiguration {
  const EyeLivingIdleConfiguration({
    this.ambientGaze = true,
    this.microSaccades = true,
    this.blinks = true,
    this.pupilVariation = true,
    this.controlledAsymmetry = true,
    this.signatureMoments = true,
  });

  final bool ambientGaze;
  final bool microSaccades;
  final bool blinks;
  final bool pupilVariation;
  final bool controlledAsymmetry;
  final bool signatureMoments;

  EyeLivingIdleConfiguration copyWith({
    bool? ambientGaze,
    bool? microSaccades,
    bool? blinks,
    bool? pupilVariation,
    bool? controlledAsymmetry,
    bool? signatureMoments,
  }) {
    return EyeLivingIdleConfiguration(
      ambientGaze: ambientGaze ?? this.ambientGaze,
      microSaccades: microSaccades ?? this.microSaccades,
      blinks: blinks ?? this.blinks,
      pupilVariation: pupilVariation ?? this.pupilVariation,
      controlledAsymmetry: controlledAsymmetry ?? this.controlledAsymmetry,
      signatureMoments: signatureMoments ?? this.signatureMoments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeLivingIdleConfiguration &&
          ambientGaze == other.ambientGaze &&
          microSaccades == other.microSaccades &&
          blinks == other.blinks &&
          pupilVariation == other.pupilVariation &&
          controlledAsymmetry == other.controlledAsymmetry &&
          signatureMoments == other.signatureMoments;

  @override
  int get hashCode => Object.hash(
    ambientGaze,
    microSaccades,
    blinks,
    pupilVariation,
    controlledAsymmetry,
    signatureMoments,
  );
}

final class EyeLivingIdleStatistics {
  const EyeLivingIdleStatistics({
    required this.gazeTransitions,
    required this.microSaccadeBursts,
    required this.naturalBlinks,
    required this.doubleBlinks,
    required this.slowBlinks,
    required this.signatureMoments,
  });

  final int gazeTransitions;
  final int microSaccadeBursts;
  final int naturalBlinks;
  final int doubleBlinks;
  final int slowBlinks;
  final int signatureMoments;
}

final class EyeLivingIdleDiagnostics {
  const EyeLivingIdleDiagnostics({
    required this.phase,
    required this.schedulerState,
    required this.gazeTargetX,
    required this.gazeTargetY,
    required this.activeBlink,
    required this.pupilFactor,
    required this.statistics,
  });

  final EyeLivingIdlePhase phase;
  final EyeLivingIdleSchedulerState schedulerState;
  final double gazeTargetX;
  final double gazeTargetY;
  final EyeLivingBlinkType? activeBlink;
  final double pupilFactor;
  final EyeLivingIdleStatistics statistics;
}

final class EyeLivingIdleFrame {
  const EyeLivingIdleFrame({
    required this.gazeX,
    required this.gazeY,
    required this.microSaccadeX,
    required this.microSaccadeY,
    required this.leftEyelidFactor,
    required this.rightEyelidFactor,
    required this.pupilFactor,
    required this.leftOpennessOffset,
    required this.rightOpennessOffset,
    required this.expressionTiltOffset,
    required this.velocityX,
    required this.velocityY,
    required this.diagnostics,
  });

  final double gazeX;
  final double gazeY;
  final double microSaccadeX;
  final double microSaccadeY;
  final double leftEyelidFactor;
  final double rightEyelidFactor;
  final double pupilFactor;
  final double leftOpennessOffset;
  final double rightOpennessOffset;
  final double expressionTiltOffset;
  final double velocityX;
  final double velocityY;
  final EyeLivingIdleDiagnostics diagnostics;
}

/// Seeded, delta-driven Neutral behaviour. It owns no clock or Flutter object.
final class NeutralLivingIdlePlanner {
  NeutralLivingIdlePlanner(
    this._random, {
    this._configuration = const EyeLivingIdleConfiguration(),
  }) {
    _gazeDwellMicros = _betweenMicros(1800000, 4200000);
    _microWaitMicros = _betweenMicros(1200000, 3800000);
    _blinkWaitMicros = _betweenMicros(2900000, 6500000);
    _signatureWaitMicros = _betweenMicros(19000000, 43000000);
    _pupilDurationMicros = _betweenMicros(1700000, 3900000);
    _asymmetryDurationMicros = _betweenMicros(1600000, 3600000);
  }

  static const maximumGazeX = 0.72;
  static const maximumGazeY = 0.42;
  static const maximumMicroSaccade = 0.045;
  static const minimumPupilFactor = 0.985;
  static const maximumPupilFactor = 1.015;

  final math.Random _random;
  EyeLivingIdleConfiguration _configuration;

  double _gazeX = 0;
  double _gazeY = 0;
  double _velocityX = 0;
  double _velocityY = 0;
  double _targetX = 0;
  double _targetY = 0;
  double _lastInterestX = 0;
  double _lastInterestY = 0;
  var _gazeTransitioning = false;
  var _gazeDwellMicros = 0;
  var _sinceGazeSettledMicros = 0;

  double _microX = 0;
  double _microY = 0;
  double _microFromX = 0;
  double _microFromY = 0;
  double _microTargetX = 0;
  double _microTargetY = 0;
  var _microWaitMicros = 0;
  var _microElapsedMicros = 0;
  var _microDurationMicros = 1;
  var _microBurstRemaining = 0;
  var _microPhase = _MicroPhase.waiting;

  var _blinkWaitMicros = 0;
  var _blinkElapsedMicros = 0;
  EyeLivingBlinkType? _activeBlink;
  var _blinkLeftLeads = true;
  double _leftBlinkFactor = 1;
  double _rightBlinkFactor = 1;

  double _pupilFrom = 1;
  double _pupilTo = 1;
  double _pupilFactor = 1;
  var _pupilElapsedMicros = 0;
  var _pupilDurationMicros = 1;

  double _leftAsymmetryFrom = 0;
  double _leftAsymmetryTo = 0;
  double _rightAsymmetryFrom = 0;
  double _rightAsymmetryTo = 0;
  double _tiltFrom = 0;
  double _tiltTo = 0;
  double _leftAsymmetry = 0;
  double _rightAsymmetry = 0;
  double _tiltAsymmetry = 0;
  var _asymmetryElapsedMicros = 0;
  var _asymmetryDurationMicros = 1;

  var _signatureWaitMicros = 0;
  EyeNeutralSignature? _pendingSignature;
  EyeNeutralSignature? _lastSignature;

  var _gazeTransitions = 0;
  var _microSaccadeBursts = 0;
  var _naturalBlinks = 0;
  var _doubleBlinks = 0;
  var _slowBlinks = 0;
  var _signatureMoments = 0;

  EyeLivingIdleConfiguration get configuration => _configuration;

  EyeLivingIdleStatistics get statistics => EyeLivingIdleStatistics(
    gazeTransitions: _gazeTransitions,
    microSaccadeBursts: _microSaccadeBursts,
    naturalBlinks: _naturalBlinks,
    doubleBlinks: _doubleBlinks,
    slowBlinks: _slowBlinks,
    signatureMoments: _signatureMoments,
  );

  void configure(EyeLivingIdleConfiguration configuration) {
    _configuration = configuration;
    if (!configuration.ambientGaze) {
      _targetX = 0;
      _targetY = 0;
      _gazeTransitioning = true;
    }
    if (!configuration.microSaccades) _resetMicroSaccade();
    if (!configuration.blinks) _resetBlink();
    if (!configuration.pupilVariation) _pupilFactor = 1;
    if (!configuration.controlledAsymmetry) {
      _leftAsymmetry = 0;
      _rightAsymmetry = 0;
      _tiltAsymmetry = 0;
    }
    if (!configuration.signatureMoments) _pendingSignature = null;
  }

  void deferBlink() {
    _blinkWaitMicros = math.max(_blinkWaitMicros, 1800000);
    _resetBlink();
  }

  EyeNeutralSignature? takeScheduledSignature() {
    final signature = _pendingSignature;
    _pendingSignature = null;
    return signature;
  }

  EyeLivingIdleFrame advance(Duration delta) {
    var remaining = math.max(0, delta.inMicroseconds);
    while (remaining > 0) {
      final step = math.min(remaining, 16000);
      _advanceStep(step);
      remaining -= step;
    }
    return _frame();
  }

  EyeLivingIdleFrame currentFrame() => _frame();

  void _advanceStep(int micros) {
    final seconds = micros / Duration.microsecondsPerSecond;
    _advanceGaze(micros, seconds);
    _advanceMicroSaccade(micros);
    _advanceBlink(micros);
    _advancePupil(micros);
    _advanceAsymmetry(micros);
    _advanceSignature(micros);
  }

  void _advanceGaze(int micros, double seconds) {
    if (_configuration.ambientGaze && !_gazeTransitioning) {
      _gazeDwellMicros -= micros;
      _sinceGazeSettledMicros += micros;
      if (_gazeDwellMicros <= 0) _selectInterestPoint();
    }

    const stiffness = 30.0;
    const damping = 8.25;
    final accelerationX =
        (_targetX - _gazeX) * stiffness - _velocityX * damping;
    final accelerationY =
        (_targetY - _gazeY) * stiffness - _velocityY * damping;
    _velocityX += accelerationX * seconds;
    _velocityY += accelerationY * seconds;
    _gazeX = (_gazeX + _velocityX * seconds).clamp(-maximumGazeX, maximumGazeX);
    _gazeY = (_gazeY + _velocityY * seconds).clamp(-maximumGazeY, maximumGazeY);

    final distance = math.sqrt(
      math.pow(_targetX - _gazeX, 2) + math.pow(_targetY - _gazeY, 2),
    );
    final speed = _velocityX.abs() + _velocityY.abs();
    if (_gazeTransitioning && distance < 0.006 && speed < 0.035) {
      _gazeX = _targetX;
      _gazeY = _targetY;
      _velocityX = 0;
      _velocityY = 0;
      _gazeTransitioning = false;
      _sinceGazeSettledMicros = 0;
      final calmCenter = _targetX.abs() < 0.22 && _targetY.abs() < 0.15;
      _gazeDwellMicros = calmCenter
          ? _betweenMicros(2200000, 5600000)
          : _betweenMicros(1100000, 3300000);
      _microWaitMicros = _betweenMicros(850000, 3200000);
    }
  }

  void _selectInterestPoint() {
    var candidateX = 0.0;
    var candidateY = 0.0;
    for (var attempt = 0; attempt < 6; attempt++) {
      final roll = _random.nextDouble();
      if (roll < 0.56) {
        candidateX = _signed(0.03, 0.19);
        candidateY = _signed(0.01, 0.11);
      } else if (roll < 0.72) {
        candidateX = -_between(0.34, 0.68);
        candidateY = _signed(0.015, 0.15);
      } else if (roll < 0.88) {
        candidateX = _between(0.34, 0.68);
        candidateY = _signed(0.015, 0.15);
      } else if (roll < 0.95) {
        candidateX = _signed(0.03, 0.2);
        candidateY = -_between(0.22, 0.39);
      } else {
        candidateX = _signed(0.02, 0.16);
        candidateY = _between(0.18, 0.34);
      }
      final distance = math.sqrt(
        math.pow(candidateX - _lastInterestX, 2) +
            math.pow(candidateY - _lastInterestY, 2),
      );
      if (distance >= 0.12) break;
    }
    _targetX = candidateX.clamp(-maximumGazeX, maximumGazeX);
    _targetY = candidateY.clamp(-maximumGazeY, maximumGazeY);
    _lastInterestX = _targetX;
    _lastInterestY = _targetY;
    _gazeTransitioning = true;
    _gazeTransitions++;
    _resetMicroSaccade();
  }

  void _advanceMicroSaccade(int micros) {
    if (!_configuration.microSaccades || _gazeTransitioning) {
      if (_microPhase != _MicroPhase.waiting) _resetMicroSaccade();
      return;
    }
    switch (_microPhase) {
      case _MicroPhase.waiting:
        _microWaitMicros -= micros;
        if (_microWaitMicros <= 0 && _sinceGazeSettledMicros > 420000) {
          _microBurstRemaining = 1 + _random.nextInt(3);
          _microSaccadeBursts++;
          _beginMicroMovement();
        }
      case _MicroPhase.moving:
        _microElapsedMicros += micros;
        final t = _smooth(
          (_microElapsedMicros / _microDurationMicros).clamp(0.0, 1.0),
        );
        _microX = _lerp(_microFromX, _microTargetX, t);
        _microY = _lerp(_microFromY, _microTargetY, t);
        if (_microElapsedMicros >= _microDurationMicros) {
          _microPhase = _MicroPhase.pause;
          _microElapsedMicros = 0;
          _microDurationMicros = _betweenMicros(42000, 105000);
        }
      case _MicroPhase.pause:
        _microElapsedMicros += micros;
        if (_microElapsedMicros >= _microDurationMicros) {
          _microBurstRemaining--;
          if (_microBurstRemaining > 0) {
            _beginMicroMovement();
          } else if (_random.nextDouble() < 0.28) {
            _microPhase = _MicroPhase.waiting;
            _microWaitMicros = _betweenMicros(1700000, 4300000);
          } else {
            _microFromX = _microX;
            _microFromY = _microY;
            _microTargetX = 0;
            _microTargetY = 0;
            _microElapsedMicros = 0;
            _microDurationMicros = _betweenMicros(75000, 130000);
            _microPhase = _MicroPhase.returning;
          }
        }
      case _MicroPhase.returning:
        _microElapsedMicros += micros;
        final t = _smooth(
          (_microElapsedMicros / _microDurationMicros).clamp(0.0, 1.0),
        );
        _microX = _lerp(_microFromX, 0, t);
        _microY = _lerp(_microFromY, 0, t);
        if (_microElapsedMicros >= _microDurationMicros) {
          _resetMicroSaccade();
        }
    }
  }

  void _beginMicroMovement() {
    _microFromX = _microX;
    _microFromY = _microY;
    _microTargetX = _signed(0.018, maximumMicroSaccade);
    _microTargetY = _signed(0.01, 0.035);
    _microElapsedMicros = 0;
    _microDurationMicros = _betweenMicros(56000, 92000);
    _microPhase = _MicroPhase.moving;
  }

  void _resetMicroSaccade() {
    _microX = 0;
    _microY = 0;
    _microFromX = 0;
    _microFromY = 0;
    _microTargetX = 0;
    _microTargetY = 0;
    _microElapsedMicros = 0;
    _microBurstRemaining = 0;
    _microPhase = _MicroPhase.waiting;
    _microWaitMicros = _betweenMicros(1200000, 3900000);
  }

  void _advanceBlink(int micros) {
    if (!_configuration.blinks) return;
    final active = _activeBlink;
    if (active == null) {
      _blinkWaitMicros -= micros;
      if (_blinkWaitMicros <= 0 &&
          !_gazeTransitioning &&
          _sinceGazeSettledMicros > 320000) {
        _startBlink();
      }
      return;
    }
    _blinkElapsedMicros += micros;
    final sample = _sampleBlink(active, _blinkElapsedMicros, _blinkLeftLeads);
    _leftBlinkFactor = sample.$1;
    _rightBlinkFactor = sample.$2;
    if (_blinkElapsedMicros >= _blinkDurationMicros(active)) {
      _resetBlink();
      _blinkWaitMicros = _betweenMicros(2800000, 7300000);
    }
  }

  void _startBlink() {
    final roll = _random.nextDouble();
    _activeBlink = switch (roll) {
      < 0.82 => EyeLivingBlinkType.natural,
      < 0.94 => EyeLivingBlinkType.doubleBlink,
      _ => EyeLivingBlinkType.slow,
    };
    _blinkLeftLeads = _random.nextBool();
    _blinkElapsedMicros = 0;
    switch (_activeBlink!) {
      case EyeLivingBlinkType.natural:
        _naturalBlinks++;
      case EyeLivingBlinkType.doubleBlink:
        _doubleBlinks++;
      case EyeLivingBlinkType.slow:
        _slowBlinks++;
    }
  }

  void _resetBlink() {
    _activeBlink = null;
    _blinkElapsedMicros = 0;
    _leftBlinkFactor = 1;
    _rightBlinkFactor = 1;
  }

  void _advancePupil(int micros) {
    if (!_configuration.pupilVariation) return;
    _pupilElapsedMicros += micros;
    final t = _smooth(
      (_pupilElapsedMicros / _pupilDurationMicros).clamp(0.0, 1.0),
    );
    _pupilFactor = _lerp(_pupilFrom, _pupilTo, t);
    if (_pupilElapsedMicros >= _pupilDurationMicros) {
      _pupilFrom = _pupilTo;
      _pupilTo = _between(minimumPupilFactor, maximumPupilFactor);
      _pupilElapsedMicros = 0;
      _pupilDurationMicros = _betweenMicros(1700000, 4200000);
    }
  }

  void _advanceAsymmetry(int micros) {
    if (!_configuration.controlledAsymmetry) return;
    _asymmetryElapsedMicros += micros;
    final t = _smooth(
      (_asymmetryElapsedMicros / _asymmetryDurationMicros).clamp(0.0, 1.0),
    );
    _leftAsymmetry = _lerp(_leftAsymmetryFrom, _leftAsymmetryTo, t);
    _rightAsymmetry = _lerp(_rightAsymmetryFrom, _rightAsymmetryTo, t);
    _tiltAsymmetry = _lerp(_tiltFrom, _tiltTo, t);
    if (_asymmetryElapsedMicros >= _asymmetryDurationMicros) {
      _leftAsymmetryFrom = _leftAsymmetryTo;
      _rightAsymmetryFrom = _rightAsymmetryTo;
      _tiltFrom = _tiltTo;
      final bias = _signed(0.002, 0.009);
      _leftAsymmetryTo = bias;
      _rightAsymmetryTo = -bias * _between(0.55, 0.9);
      _tiltTo = _signed(0.001, 0.008);
      _asymmetryElapsedMicros = 0;
      _asymmetryDurationMicros = _betweenMicros(1500000, 3900000);
    }
  }

  void _advanceSignature(int micros) {
    if (!_configuration.signatureMoments || _pendingSignature != null) return;
    _signatureWaitMicros -= micros;
    if (_signatureWaitMicros > 0 ||
        _gazeTransitioning ||
        _sinceGazeSettledMicros < 900000 ||
        _gazeX.abs() > 0.1 ||
        _gazeY.abs() > 0.1 ||
        _activeBlink != null ||
        _microPhase != _MicroPhase.waiting) {
      return;
    }
    var next = EyeNeutralSignature
        .values[_random.nextInt(EyeNeutralSignature.values.length)];
    if (next == _lastSignature) {
      next =
          EyeNeutralSignature.values[(next.index + 1 + _random.nextInt(2)) %
              EyeNeutralSignature.values.length];
    }
    _pendingSignature = next;
    _lastSignature = next;
    _signatureMoments++;
    _signatureWaitMicros = _betweenMicros(21000000, 49000000);
  }

  EyeLivingIdleFrame _frame() {
    final EyeLivingIdlePhase phase;
    final EyeLivingIdleSchedulerState scheduler;
    if (_pendingSignature != null) {
      phase = EyeLivingIdlePhase.signature;
      scheduler = EyeLivingIdleSchedulerState.signatureReady;
    } else if (_activeBlink != null) {
      phase = EyeLivingIdlePhase.blink;
      scheduler = EyeLivingIdleSchedulerState.blinking;
    } else if (_microPhase != _MicroPhase.waiting) {
      phase = EyeLivingIdlePhase.microSaccade;
      scheduler = EyeLivingIdleSchedulerState.microBurst;
    } else if (_gazeTransitioning) {
      phase = EyeLivingIdlePhase.gazeTransition;
      scheduler = EyeLivingIdleSchedulerState.movingToInterest;
    } else {
      phase = EyeLivingIdlePhase.gazeDwell;
      scheduler = EyeLivingIdleSchedulerState.holdingInterest;
    }
    return EyeLivingIdleFrame(
      gazeX: _gazeX,
      gazeY: _gazeY,
      microSaccadeX: _microX,
      microSaccadeY: _microY,
      leftEyelidFactor: _leftBlinkFactor,
      rightEyelidFactor: _rightBlinkFactor,
      pupilFactor: _configuration.pupilVariation ? _pupilFactor : 1,
      leftOpennessOffset: _configuration.controlledAsymmetry
          ? _leftAsymmetry
          : 0,
      rightOpennessOffset: _configuration.controlledAsymmetry
          ? _rightAsymmetry
          : 0,
      expressionTiltOffset: _configuration.controlledAsymmetry
          ? _tiltAsymmetry
          : 0,
      velocityX: _velocityX,
      velocityY: _velocityY,
      diagnostics: EyeLivingIdleDiagnostics(
        phase: phase,
        schedulerState: scheduler,
        gazeTargetX: _targetX,
        gazeTargetY: _targetY,
        activeBlink: _activeBlink,
        pupilFactor: _configuration.pupilVariation ? _pupilFactor : 1,
        statistics: statistics,
      ),
    );
  }

  (double, double) _sampleBlink(
    EyeLivingBlinkType type,
    int elapsed,
    bool leftLeads,
  ) {
    final (left, right) = switch (type) {
      EyeLivingBlinkType.natural => _sampleBlinkPulse(
        elapsed,
        anticipation: 28000,
        lead: 12000,
        close: 74000,
        closed: 36000,
        open: 126000,
        leftLeads: leftLeads,
      ),
      EyeLivingBlinkType.slow => _sampleBlinkPulse(
        elapsed,
        anticipation: 62000,
        lead: 15000,
        close: 230000,
        closed: 95000,
        open: 330000,
        leftLeads: leftLeads,
      ),
      EyeLivingBlinkType.doubleBlink => _sampleDoubleBlink(elapsed, leftLeads),
    };
    return (left, right);
  }

  (double, double) _sampleDoubleBlink(int elapsed, bool leftLeads) {
    const firstDuration = 276000;
    const gap = 108000;
    if (elapsed <= firstDuration) {
      return _sampleBlinkPulse(
        elapsed,
        anticipation: 28000,
        lead: 12000,
        close: 74000,
        closed: 36000,
        open: 126000,
        leftLeads: leftLeads,
      );
    }
    if (elapsed <= firstDuration + gap) return (1, 1);
    return _sampleBlinkPulse(
      elapsed - firstDuration - gap,
      anticipation: 16000,
      lead: 9000,
      close: 56000,
      closed: 25000,
      open: 94000,
      leftLeads: !leftLeads,
    );
  }

  (double, double) _sampleBlinkPulse(
    int elapsed, {
    required int anticipation,
    required int lead,
    required int close,
    required int closed,
    required int open,
    required bool leftLeads,
  }) {
    var cursor = 0;
    if (elapsed <= anticipation) {
      final lift = _lerp(1, 1.018, _smooth(elapsed / anticipation));
      return (lift, lift);
    }
    cursor += anticipation;
    if (elapsed <= cursor + lead) {
      final leading = _lerp(1.018, 0.76, (elapsed - cursor) / lead);
      return leftLeads ? (leading, 1.018) : (1.018, leading);
    }
    cursor += lead;
    if (elapsed <= cursor + close) {
      final t = _smooth((elapsed - cursor) / close);
      return (
        _lerp(leftLeads ? 0.76 : 1.018, 0.035, t),
        _lerp(leftLeads ? 1.018 : 0.76, 0.04, t),
      );
    }
    cursor += close;
    if (elapsed <= cursor + closed) return (0.035, 0.04);
    cursor += closed;
    if (elapsed <= cursor + open) {
      final t = _smooth((elapsed - cursor) / open);
      return (_lerp(0.035, 1, t), _lerp(0.04, 1, t));
    }
    return (1, 1);
  }

  int _blinkDurationMicros(EyeLivingBlinkType type) {
    return switch (type) {
      EyeLivingBlinkType.natural => 276000,
      EyeLivingBlinkType.doubleBlink => 584000,
      EyeLivingBlinkType.slow => 732000,
    };
  }

  double _between(double minimum, double maximum) =>
      minimum + _random.nextDouble() * (maximum - minimum);

  int _betweenMicros(int minimum, int maximum) =>
      minimum + _random.nextInt(maximum - minimum + 1);

  double _signed(double minimum, double maximum) {
    final value = _between(minimum, maximum);
    return _random.nextBool() ? value : -value;
  }
}

enum _MicroPhase { waiting, moving, pause, returning }

double _smooth(double value) {
  final t = value.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;
