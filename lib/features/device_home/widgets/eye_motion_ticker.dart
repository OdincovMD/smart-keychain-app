import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/eyes/eye_motion_player.dart';
import '../../../domain/eyes/eye_runtime_state.dart';

abstract interface class EyeMotionStateSource implements Listenable {
  EyeRuntimeState get state;
}

/// The only frame clock used by the eye runtime.
///
/// It converts Flutter's monotonic ticker time into deltas for the pure
/// [EyeMotionPlayer]. Pausing always forgets the previous timestamp, so resume
/// never catches up time spent in the background.
final class EyeMotionTicker extends ChangeNotifier
    implements EyeMotionStateSource {
  EyeMotionTicker({required TickerProvider vsync, required this.player}) {
    _ticker = vsync.createTicker(_tick);
  }

  final EyeMotionPlayer player;
  late final Ticker _ticker;
  Duration? _lastElapsed;

  @override
  EyeRuntimeState get state => player.state;
  EyeMotionPlayerPhase get phase => player.phase;
  bool get isTicking => _ticker.isTicking;

  void start() {
    player.resume();
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void pause() {
    if (_ticker.isActive) _ticker.stop();
    _lastElapsed = null;
    player.pause();
    notifyListeners();
  }

  void stop({bool snapToMood = false}) {
    if (_ticker.isActive) _ticker.stop();
    _lastElapsed = null;
    player.stop(snapToMood: snapToMood);
    notifyListeners();
  }

  void refresh() => notifyListeners();

  void _tick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    player.advance(elapsed - previous);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
