// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$AppSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppSettingsEntriesTable get appSettingsEntries =>
      attachedDatabase.appSettingsEntries;
  AppSettingsDaoManager get managers => AppSettingsDaoManager(this);
}

class AppSettingsDaoManager {
  final _$AppSettingsDaoMixin _db;
  AppSettingsDaoManager(this._db);
  $$AppSettingsEntriesTableTableManager get appSettingsEntries =>
      $$AppSettingsEntriesTableTableManager(
        _db.attachedDatabase,
        _db.appSettingsEntries,
      );
}
