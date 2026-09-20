import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

final deviceControllerProvider = AsyncNotifierProvider<DeviceController, void>(
  DeviceController.new,
);

final class DeviceController extends AsyncNotifier<void> {
  Future<void> _activeCommand = Future<void>.value();
  bool _disconnectQueued = false;

  @override
  FutureOr<void> build() {}

  void connect(String deviceId) =>
      _run(() => ref.read(deviceRepositoryProvider).connect(deviceId));

  void disconnect() {
    if (state.isLoading) {
      if (_disconnectQueued) return;
      _disconnectQueued = true;
      unawaited(_disconnectAfterActiveCommand());
      return;
    }
    _run(ref.read(deviceRepositoryProvider).disconnect);
  }

  void setScene(String sceneId) => _run(() async {
    await ref.read(deviceRepositoryProvider).setScene(sceneId);
    await ref.read(appSettingsRepositoryProvider).saveActiveSceneId(sceneId);
  });

  void setBrightness(double value) => _run(() async {
    await ref.read(deviceRepositoryProvider).setBrightness(value);
    await ref.read(appSettingsRepositoryProvider).saveBrightness(value);
  });

  void _run(Future<void> Function() command) {
    if (state.isLoading) return;
    _activeCommand = _runCommand(command);
    unawaited(_activeCommand);
  }

  Future<void> _disconnectAfterActiveCommand() async {
    await _activeCommand;
    if (!ref.mounted) return;
    _disconnectQueued = false;
    _run(ref.read(deviceRepositoryProvider).disconnect);
  }

  Future<void> _runCommand(Future<void> Function() command) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(command);
    if (ref.mounted) state = nextState;
  }
}
