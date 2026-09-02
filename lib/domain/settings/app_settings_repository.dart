import 'app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> load();

  Future<void> saveActiveSceneId(String sceneId);

  Future<void> saveBrightness(double brightness);

  Future<void> flush();
}
