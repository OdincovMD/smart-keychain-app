import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/eyes/eye_emotion.dart';
import '../../domain/eyes/neutral_living_idle.dart';

enum EyeDebugCommand {
  blink,
  doubleBlink,
  slowBlink,
  wink,
  lookLeft,
  lookRight,
  specialAction,
  signatureCuriousGlance,
  signatureSoftCenterBlink,
  signatureSideHoldReturn,
}

enum EyePlaybackCommand { play, pause, restart }

const _noSeedChange = Object();

final class EyePreviewState {
  const EyePreviewState({
    required this.emotion,
    required this.blinkRevision,
    required this.commandRevision,
    required this.command,
    required this.randomSeed,
    required this.seedRevision,
    required this.livingIdleConfiguration,
    required this.clipName,
    required this.playbackRevision,
    required this.playbackCommand,
    required this.playbackSpeed,
  });

  final EyeEmotion emotion;
  final int blinkRevision;
  final int commandRevision;
  final EyeDebugCommand? command;
  final int? randomSeed;
  final int seedRevision;
  final EyeLivingIdleConfiguration livingIdleConfiguration;
  final String clipName;
  final int playbackRevision;
  final EyePlaybackCommand? playbackCommand;
  final double playbackSpeed;

  EyePreviewState copyWith({
    EyeEmotion? emotion,
    int? blinkRevision,
    int? commandRevision,
    EyeDebugCommand? command,
    Object? randomSeed = _noSeedChange,
    int? seedRevision,
    EyeLivingIdleConfiguration? livingIdleConfiguration,
    String? clipName,
    int? playbackRevision,
    EyePlaybackCommand? playbackCommand,
    double? playbackSpeed,
  }) {
    return EyePreviewState(
      emotion: emotion ?? this.emotion,
      blinkRevision: blinkRevision ?? this.blinkRevision,
      commandRevision: commandRevision ?? this.commandRevision,
      command: command ?? this.command,
      randomSeed: identical(randomSeed, _noSeedChange)
          ? this.randomSeed
          : randomSeed as int?,
      seedRevision: seedRevision ?? this.seedRevision,
      livingIdleConfiguration:
          livingIdleConfiguration ?? this.livingIdleConfiguration,
      clipName: clipName ?? this.clipName,
      playbackRevision: playbackRevision ?? this.playbackRevision,
      playbackCommand: playbackCommand ?? this.playbackCommand,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyePreviewState &&
          emotion == other.emotion &&
          blinkRevision == other.blinkRevision &&
          commandRevision == other.commandRevision &&
          command == other.command &&
          randomSeed == other.randomSeed &&
          seedRevision == other.seedRevision &&
          livingIdleConfiguration == other.livingIdleConfiguration &&
          clipName == other.clipName &&
          playbackRevision == other.playbackRevision &&
          playbackCommand == other.playbackCommand &&
          playbackSpeed == other.playbackSpeed;

  @override
  int get hashCode => Object.hash(
    emotion,
    blinkRevision,
    commandRevision,
    command,
    randomSeed,
    seedRevision,
    livingIdleConfiguration,
    clipName,
    playbackRevision,
    playbackCommand,
    playbackSpeed,
  );
}

final class EyePreviewController extends Notifier<EyePreviewState> {
  @override
  EyePreviewState build() {
    return const EyePreviewState(
      emotion: EyeEmotion.neutral,
      blinkRevision: 0,
      commandRevision: 0,
      command: null,
      randomSeed: null,
      seedRevision: 0,
      livingIdleConfiguration: EyeLivingIdleConfiguration(),
      clipName: 'neutral_idle',
      playbackRevision: 0,
      playbackCommand: null,
      playbackSpeed: 1,
    );
  }

  void setEmotion(EyeEmotion emotion) {
    if (state.emotion == emotion) return;
    state = state.copyWith(emotion: emotion);
  }

  void requestBlink() {
    _request(EyeDebugCommand.blink, isBlink: true);
  }

  void requestDoubleBlink() {
    _request(EyeDebugCommand.doubleBlink);
  }

  void requestSlowBlink() {
    _request(EyeDebugCommand.slowBlink);
  }

  void requestWink() {
    _request(EyeDebugCommand.wink);
  }

  void requestLookLeft() {
    _request(EyeDebugCommand.lookLeft);
  }

  void requestLookRight() {
    _request(EyeDebugCommand.lookRight);
  }

  void requestSpecialAction() {
    _request(EyeDebugCommand.specialAction);
  }

  void requestSignatureCuriousGlance() {
    _request(EyeDebugCommand.signatureCuriousGlance);
  }

  void requestSignatureSoftCenterBlink() {
    _request(EyeDebugCommand.signatureSoftCenterBlink);
  }

  void requestSignatureSideHoldReturn() {
    _request(EyeDebugCommand.signatureSideHoldReturn);
  }

  void setRandomSeed(int? seed) {
    if (state.randomSeed == seed) return;
    state = EyePreviewState(
      emotion: state.emotion,
      blinkRevision: state.blinkRevision,
      commandRevision: state.commandRevision,
      command: state.command,
      randomSeed: seed,
      seedRevision: state.seedRevision + 1,
      livingIdleConfiguration: state.livingIdleConfiguration,
      clipName: state.clipName,
      playbackRevision: state.playbackRevision,
      playbackCommand: state.playbackCommand,
      playbackSpeed: state.playbackSpeed,
    );
  }

  void restartWithSameSeed() {
    state = state.copyWith(seedRevision: state.seedRevision + 1);
  }

  void setLivingIdleConfiguration(EyeLivingIdleConfiguration configuration) {
    if (state.livingIdleConfiguration == configuration) return;
    state = state.copyWith(livingIdleConfiguration: configuration);
  }

  void setClip(String clipName) {
    if (state.clipName == clipName) return;
    state = state.copyWith(clipName: clipName);
  }

  void setPlaybackSpeed(double speed) {
    if (state.playbackSpeed == speed) return;
    state = state.copyWith(playbackSpeed: speed);
  }

  void play() => _requestPlayback(EyePlaybackCommand.play);

  void pause() => _requestPlayback(EyePlaybackCommand.pause);

  void restart() => _requestPlayback(EyePlaybackCommand.restart);

  void _requestPlayback(EyePlaybackCommand command) {
    state = state.copyWith(
      playbackRevision: state.playbackRevision + 1,
      playbackCommand: command,
    );
  }

  void _request(EyeDebugCommand command, {bool isBlink = false}) {
    state = state.copyWith(
      blinkRevision: isBlink ? state.blinkRevision + 1 : state.blinkRevision,
      commandRevision: state.commandRevision + 1,
      command: command,
    );
  }
}

final eyePreviewControllerProvider =
    NotifierProvider.autoDispose<EyePreviewController, EyePreviewState>(
      EyePreviewController.new,
    );

final eyeRandomProvider = Provider<Random>((ref) => Random());
