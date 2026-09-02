import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/data/database/app_database.dart';
import 'package:smart_keychain_app/data/settings/drift_app_settings_repository.dart';

void main() {
  test('migrates v1 to v2 without losing app settings', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database
          ..execute('''
CREATE TABLE app_settings (
  id TEXT NOT NULL PRIMARY KEY,
  created_at_utc_ms INTEGER NOT NULL,
  updated_at_utc_ms INTEGER NOT NULL,
  row_revision INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  deleted_at_utc_ms INTEGER,
  active_scene_id TEXT,
  brightness_permille INTEGER NOT NULL DEFAULT 800,
  CHECK (brightness_permille BETWEEN 0 AND 1000),
  CHECK (is_deleted = 0 AND deleted_at_utc_ms IS NULL)
) STRICT
''')
          ..execute('''
INSERT INTO app_settings (
  id, created_at_utc_ms, updated_at_utc_ms, row_revision,
  is_deleted, deleted_at_utc_ms, active_scene_id, brightness_permille
) VALUES ('app', 1, 1, 0, 0, NULL, 'living_eyes_v1', 420)
''')
          ..execute('PRAGMA user_version = 1');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final settings = await DriftAppSettingsRepository(database).load();
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    final imageTable = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'user_image_assets'",
        )
        .getSingle();

    expect(version.read<int>('user_version'), 2);
    expect(settings.activeSceneId, 'living_eyes_v1');
    expect(settings.brightness, closeTo(0.42, 0.0001));
    expect(imageTable.read<String>('name'), 'user_image_assets');
  });
}
