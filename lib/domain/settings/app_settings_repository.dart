import 'app_settings.dart';
import 'app_appearance.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> load();

  Future<void> saveActiveSceneId(String sceneId);

  Future<void> saveBrightness(double brightness);

  Future<void> saveAppearance(AppAppearance appearance);

  Future<void> flush();
}
