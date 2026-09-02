import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/application/startup_restoration.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';

import '../support/fake_app_settings_repository.dart';

void main() {
  group('restoreDevicePreferences', () {
    test('restores a valid persisted scene and brightness', () async {
      final settings = FakeAppSettingsRepository(
        initialSettings: const AppSettings(
          activeSceneId: BuiltInSceneRepository.mintEyesId,
          brightness: 0.35,
        ),
      );

      final restored = await restoreDevicePreferences(
        settingsRepository: settings,
        sceneRepository: BuiltInSceneRepository(),
        defaultSceneId: BuiltInSceneRepository.livingEyesId,
      );

      expect(restored.activeSceneId, BuiltInSceneRepository.mintEyesId);
      expect(restored.brightness, closeTo(0.35, 0.0001));
    });

    test('unknown persisted scene safely falls back to default', () async {
      final settings = FakeAppSettingsRepository(
        initialSettings: const AppSettings(
          activeSceneId: 'removed-scene',
          brightness: 0.65,
        ),
      );

      final restored = await restoreDevicePreferences(
        settingsRepository: settings,
        sceneRepository: BuiltInSceneRepository(),
        defaultSceneId: BuiltInSceneRepository.livingEyesId,
      );

      expect(restored.activeSceneId, BuiltInSceneRepository.livingEyesId);
      expect(restored.brightness, closeTo(0.65, 0.0001));
    });

    test('missing persisted scene uses default without crashing', () async {
      final restored = await restoreDevicePreferences(
        settingsRepository: FakeAppSettingsRepository(),
        sceneRepository: BuiltInSceneRepository(),
        defaultSceneId: BuiltInSceneRepository.livingEyesId,
      );

      expect(restored.activeSceneId, BuiltInSceneRepository.livingEyesId);
      expect(restored.brightness, AppSettings.defaultBrightness);
    });
  });
}
