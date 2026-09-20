import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../application/device_controller.dart';

enum LookApplicationStatus { ready, applying, applied, failed }

final class LookApplicationState {
  const LookApplicationState._(this.status);

  const LookApplicationState.ready() : this._(LookApplicationStatus.ready);

  const LookApplicationState.applying()
    : this._(LookApplicationStatus.applying);

  const LookApplicationState.applied() : this._(LookApplicationStatus.applied);

  const LookApplicationState.failed() : this._(LookApplicationStatus.failed);

  final LookApplicationStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookApplicationState && status == other.status;

  @override
  int get hashCode => status.hashCode;
}

final lookApplicationControllerProvider = NotifierProvider.autoDispose
    .family<LookApplicationController, LookApplicationState, String>(
      LookApplicationController.new,
    );

final class LookApplicationController extends Notifier<LookApplicationState> {
  LookApplicationController(this.sceneId);

  final String sceneId;

  @override
  LookApplicationState build() {
    ref
      ..listen(deviceControllerProvider, _onDeviceCommandChanged)
      ..listen(deviceSnapshotProvider, (_, _) => _confirmIfComplete());
    return const LookApplicationState.ready();
  }

  void apply() {
    if (state.status
        case LookApplicationStatus.applying || LookApplicationStatus.applied) {
      return;
    }
    if (ref.read(deviceControllerProvider).isLoading) return;
    if (ref.read(deviceSnapshotProvider).value?.activeSceneId == sceneId) {
      return;
    }
    state = const LookApplicationState.applying();
    ref.read(deviceControllerProvider.notifier).setScene(sceneId);
  }

  void retry() {
    if (state.status != LookApplicationStatus.failed) return;
    apply();
  }

  void _onDeviceCommandChanged(
    AsyncValue<void>? previous,
    AsyncValue<void> next,
  ) {
    if (state.status != LookApplicationStatus.applying ||
        previous?.isLoading != true) {
      return;
    }
    if (next.hasError) {
      state = const LookApplicationState.failed();
      return;
    }
    _confirmIfComplete();
  }

  void _confirmIfComplete() {
    if (!ref.mounted || state.status != LookApplicationStatus.applying) return;
    final command = ref.read(deviceControllerProvider);
    final snapshot = ref.read(deviceSnapshotProvider).value;
    if (command.hasValue &&
        !command.isLoading &&
        snapshot?.activeSceneId == sceneId) {
      state = const LookApplicationState.applied();
    }
  }
}
