import '../domain/content/scene_repository.dart';
import '../domain/settings/app_appearance.dart';
import '../domain/settings/app_settings_repository.dart';

final class RestoredDevicePreferences {
  const RestoredDevicePreferences({
    required this.activeSceneId,
    required this.brightness,
    required this.appearance,
  });

  final String activeSceneId;
  final double brightness;
  final AppAppearance appearance;
}

Future<RestoredDevicePreferences> restoreDevicePreferences({
  required AppSettingsRepository settingsRepository,
  required SceneRepository sceneRepository,
  required String defaultSceneId,
}) async {
  final settings = await settingsRepository.load();
  final savedSceneId = settings.activeSceneId;
  final savedScene = savedSceneId == null
      ? null
      : await sceneRepository.getById(savedSceneId);

  return RestoredDevicePreferences(
    activeSceneId: savedScene?.id ?? defaultSceneId,
    brightness: settings.brightness,
    appearance: settings.appearance,
  );
}
