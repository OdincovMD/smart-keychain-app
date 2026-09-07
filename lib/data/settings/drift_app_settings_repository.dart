import '../../domain/settings/app_settings.dart';
import '../../domain/settings/app_settings_repository.dart';
import '../../domain/settings/app_appearance.dart';
import '../database/app_database.dart';

final class DriftAppSettingsRepository implements AppSettingsRepository {
  DriftAppSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppSettings> load() async {
    return await _database.appSettingsDao.load() ?? AppSettings.defaults;
  }

  @override
  Future<void> saveActiveSceneId(String sceneId) {
    if (sceneId.isEmpty) {
      throw ArgumentError.value(sceneId, 'sceneId', 'Must not be empty.');
    }
    return _database.transaction(() async {
      final current = await load();
      await _database.appSettingsDao.save(
        current.copyWith(activeSceneId: sceneId),
      );
    });
  }

  @override
  Future<void> saveBrightness(double brightness) {
    if (!brightness.isFinite || brightness < 0 || brightness > 1) {
      throw ArgumentError.value(
        brightness,
        'brightness',
        'Must be between 0 and 1.',
      );
    }
    return _database.transaction(() async {
      final current = await load();
      await _database.appSettingsDao.save(
        current.copyWith(brightness: brightness),
      );
    });
  }

  @override
  Future<void> saveAppearance(AppAppearance appearance) {
    return _database.transaction(() async {
      final current = await load();
      await _database.appSettingsDao.save(
        current.copyWith(appearance: appearance),
      );
    });
  }

  @override
  Future<void> flush() async {
    await _database.customStatement('PRAGMA wal_checkpoint(PASSIVE)');
  }
}
