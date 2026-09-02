import 'package:drift/drift.dart';

import 'audit_columns.dart';

@DataClassName('UserImageAssetRow')
class UserImageAssets extends Table with AuditColumns {
  TextColumn get originalStorageKey => text()();

  TextColumn get previewStorageKey => text()();

  RealColumn get cropCenterX => real()();

  RealColumn get cropCenterY => real()();

  RealColumn get cropScale => real()();

  RealColumn get cropRotation => real()();

  @override
  List<String> get customConstraints => [
    "CHECK (original_storage_key LIKE 'user-content/originals/%')",
    "CHECK (preview_storage_key LIKE 'user-content/previews/%')",
    'CHECK (crop_center_x BETWEEN 0.0 AND 1.0)',
    'CHECK (crop_center_y BETWEEN 0.0 AND 1.0)',
    'CHECK (crop_scale BETWEEN 1.0 AND 8.0)',
    'CHECK (crop_rotation BETWEEN -3.141592653589793 AND 3.141592653589793)',
    'CHECK (is_deleted = 0 AND deleted_at_utc_ms IS NULL)',
  ];

  @override
  bool get isStrict => true;
}
