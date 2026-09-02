import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/application/device_controller.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';

void main() {
  test('committed device scene and brightness are persisted', () async {
    final scenes = BuiltInSceneRepository();
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      ),
    );
    final settings = FakeAppSettingsRepository();
    final container = ProviderContainer(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(device),
        appSettingsRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(device.dispose);
    await container.read(deviceControllerProvider.future);

    container
        .read(deviceControllerProvider.notifier)
        .connect(VirtualDeviceEngine.deviceId);
    await _waitForCommand(container);
    container
        .read(deviceControllerProvider.notifier)
        .setScene(BuiltInSceneRepository.mintEyesId);
    await _waitForCommand(container);
    container.read(deviceControllerProvider.notifier).setBrightness(0.37);
    await _waitForCommand(container);

    expect(settings.settings.activeSceneId, BuiltInSceneRepository.mintEyesId);
    expect(settings.settings.brightness, closeTo(0.37, 0.0001));
  });
}

Future<void> _waitForCommand(ProviderContainer container) async {
  await Future<void>.delayed(Duration.zero);
  await container.read(deviceControllerProvider.future);
}
