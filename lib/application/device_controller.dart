import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

final deviceControllerProvider = AsyncNotifierProvider<DeviceController, void>(
  DeviceController.new,
);

final class DeviceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> connect(String deviceId) async {
    await _run(() => ref.read(deviceRepositoryProvider).connect(deviceId));
  }

  Future<void> disconnect() async {
    await _run(ref.read(deviceRepositoryProvider).disconnect);
  }

  Future<void> setScene(String sceneId) async {
    await _run(() => ref.read(deviceRepositoryProvider).setScene(sceneId));
  }

  Future<void> setBrightness(double value) async {
    await _run(() => ref.read(deviceRepositoryProvider).setBrightness(value));
  }

  Future<void> _run(Future<void> Function() command) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(command);
  }
}
