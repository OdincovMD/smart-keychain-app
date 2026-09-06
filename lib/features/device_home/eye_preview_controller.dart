import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/eyes/eye_emotion.dart';

enum EyeDebugCommand { blink, doubleBlink, lookLeft, lookRight, specialAction }

final class EyePreviewState {
  const EyePreviewState({
    required this.emotion,
    required this.blinkRevision,
    required this.commandRevision,
    required this.command,
    required this.randomSeed,
  });

  final EyeEmotion emotion;
  final int blinkRevision;
  final int commandRevision;
  final EyeDebugCommand? command;
  final int? randomSeed;

  EyePreviewState copyWith({
    EyeEmotion? emotion,
    int? blinkRevision,
    int? commandRevision,
    EyeDebugCommand? command,
  }) {
    return EyePreviewState(
      emotion: emotion ?? this.emotion,
      blinkRevision: blinkRevision ?? this.blinkRevision,
      commandRevision: commandRevision ?? this.commandRevision,
      command: command ?? this.command,
      randomSeed: randomSeed,
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
          randomSeed == other.randomSeed;

  @override
  int get hashCode =>
      Object.hash(emotion, blinkRevision, commandRevision, command, randomSeed);
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

  void requestLookLeft() {
    _request(EyeDebugCommand.lookLeft);
  }

  void requestLookRight() {
    _request(EyeDebugCommand.lookRight);
  }

  void requestSpecialAction() {
    _request(EyeDebugCommand.specialAction);
  }

  void setRandomSeed(int? seed) {
    if (state.randomSeed == seed) return;
    state = EyePreviewState(
      emotion: state.emotion,
      blinkRevision: state.blinkRevision,
      commandRevision: state.commandRevision,
      command: state.command,
      randomSeed: seed,
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
