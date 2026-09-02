import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/eyes/eye_emotion.dart';

final class EyePreviewState {
  const EyePreviewState({required this.emotion, required this.blinkRevision});

  final EyeEmotion emotion;
  final int blinkRevision;

  EyePreviewState copyWith({EyeEmotion? emotion, int? blinkRevision}) {
    return EyePreviewState(
      emotion: emotion ?? this.emotion,
      blinkRevision: blinkRevision ?? this.blinkRevision,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyePreviewState &&
          emotion == other.emotion &&
          blinkRevision == other.blinkRevision;

  @override
  int get hashCode => Object.hash(emotion, blinkRevision);
}

final class EyePreviewController extends Notifier<EyePreviewState> {
  @override
  EyePreviewState build() {
    return const EyePreviewState(emotion: EyeEmotion.neutral, blinkRevision: 0);
  }

  void setEmotion(EyeEmotion emotion) {
    if (state.emotion == emotion) return;
    state = state.copyWith(emotion: emotion);
  }

  void requestBlink() {
    state = state.copyWith(blinkRevision: state.blinkRevision + 1);
  }
}

final eyePreviewControllerProvider =
    NotifierProvider.autoDispose<EyePreviewController, EyePreviewState>(
      EyePreviewController.new,
    );

final eyeRandomProvider = Provider<Random>((ref) => Random(0x1EAF));
