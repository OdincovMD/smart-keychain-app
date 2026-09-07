import 'package:drift/drift.dart';

import '../../../domain/settings/app_appearance.dart';
import '../../../domain/settings/app_settings.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsEntries])
final class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.attachedDatabase);

  static const _singletonId = 'app';

  Future<AppSettings?> load() async {
    final row = await (select(
      appSettingsEntries,
    )..where((table) => table.id.equals(_singletonId))).getSingleOrNull();
    if (row == null) return null;
    return AppSettings(
      activeSceneId: row.activeSceneId,
      brightness: row.brightnessPermille / 1000,
      appearance: AppAppearance.fromStorageValue(row.appearance),
    );
  }

  Future<void> save(AppSettings settings) async {
    final brightnessPermille = (settings.brightness * 1000).round();
    await customStatement(
      '''
INSERT INTO app_settings (
  id,
  created_at_utc_ms,
  updated_at_utc_ms,
  row_revision,
  is_deleted,
  deleted_at_utc_ms,
  active_scene_id,
  brightness_permille,
  appearance
) VALUES (
  ?,
  CAST(strftime('%s', 'now') AS INTEGER) * 1000,
  CAST(strftime('%s', 'now') AS INTEGER) * 1000,
  0,
  0,
  NULL,
  ?,
  ?,
  ?
)
ON CONFLICT(id) DO UPDATE SET
  updated_at_utc_ms = CAST(strftime('%s', 'now') AS INTEGER) * 1000,
  row_revision = app_settings.row_revision + 1,
  active_scene_id = excluded.active_scene_id,
  brightness_permille = excluded.brightness_permille,
  appearance = excluded.appearance
''',
      [
        _singletonId,
        settings.activeSceneId,
        brightnessPermille,
        settings.appearance.storageValue,
      ],
    );
  }
}
