import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/domain/settings/app_settings_repository.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';

final class FakeAppSettingsRepository implements AppSettingsRepository {
  FakeAppSettingsRepository({
    AppSettings initialSettings = AppSettings.defaults,
    this.failure,
  }) : _settings = initialSettings;

  AppSettings _settings;
  Object? failure;
  int flushCount = 0;

  AppSettings get settings => _settings;

  @override
  Future<void> flush() async {
    _throwIfConfigured();
    flushCount++;
  }

  @override
  Future<AppSettings> load() async {
    _throwIfConfigured();
    return _settings;
  }

  @override
  Future<void> saveActiveSceneId(String sceneId) async {
    _throwIfConfigured();
    _settings = _settings.copyWith(activeSceneId: sceneId);
  }

  @override
  Future<void> saveBrightness(double brightness) async {
    _throwIfConfigured();
    _settings = _settings.copyWith(brightness: brightness);
  }

  @override
  Future<void> saveAppearance(AppAppearance appearance) async {
    _throwIfConfigured();
    _settings = _settings.copyWith(appearance: appearance);
  }

  void _throwIfConfigured() {
    if (failure case final failure?) throw failure;
  }
}
