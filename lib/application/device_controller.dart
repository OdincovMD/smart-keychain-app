import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

final deviceControllerProvider = AsyncNotifierProvider<DeviceController, void>(
  DeviceController.new,
);

final class DeviceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  void connect(String deviceId) =>
      _run(() => ref.read(deviceRepositoryProvider).connect(deviceId));

  void disconnect() => _run(ref.read(deviceRepositoryProvider).disconnect);

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
    unawaited(_runCommand(command));
  }

  Future<void> _runCommand(Future<void> Function() command) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(command);
    if (ref.mounted) state = nextState;
  }
}
