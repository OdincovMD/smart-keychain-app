import 'package:drift/drift.dart';

import 'audit_columns.dart';

@DataClassName('AppSettingsRow')
class AppSettingsEntries extends Table with AuditColumns {
  TextColumn get activeSceneId => text().nullable()();

  IntColumn get brightnessPermille =>
      integer().withDefault(const Constant(800))();

  @override
  String get tableName => 'app_settings';

  @override
  List<String> get customConstraints => const [
    'CHECK (brightness_permille BETWEEN 0 AND 1000)',
    'CHECK (is_deleted = 0 AND deleted_at_utc_ms IS NULL)',
  ];

  @override
  bool get isStrict => true;
}
