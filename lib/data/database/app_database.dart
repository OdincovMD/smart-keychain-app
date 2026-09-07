import 'package:drift/drift.dart';

import 'daos/app_settings_dao.dart';
import 'daos/user_image_assets_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/user_image_assets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [AppSettingsEntries, UserImageAssets],
  daos: [AppSettingsDao, UserImageAssetsDao],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: _migrateForward,
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA synchronous = FULL');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );

  Future<void> _migrateForward(
    Migrator migrator,
    int fromVersion,
    int toVersion,
  ) async {
    if (fromVersion > toVersion) {
      throw StateError('Database downgrades are not supported.');
    }

    var currentVersion = fromVersion;
    if (currentVersion == 1 && toVersion >= 2) {
      await migrator.createTable(userImageAssets);
      currentVersion = 2;
    }

    if (currentVersion == 2 && toVersion >= 3) {
      await migrator.addColumn(
        appSettingsEntries,
        appSettingsEntries.appearance,
      );
      currentVersion = 3;
    }

    if (currentVersion < toVersion) {
      throw StateError(
        'Missing forward migration from schema version $currentVersion.',
      );
    }
  }
}
