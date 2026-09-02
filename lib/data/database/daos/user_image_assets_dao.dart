import 'package:drift/drift.dart';

import '../../../domain/image/crop_spec.dart';
import '../../../domain/image/user_image_asset.dart';
import '../app_database.dart';
import '../tables/user_image_assets_table.dart';

part 'user_image_assets_dao.g.dart';

@DriftAccessor(tables: [UserImageAssets])
final class UserImageAssetsDao extends DatabaseAccessor<AppDatabase>
    with _$UserImageAssetsDaoMixin {
  UserImageAssetsDao(super.attachedDatabase);

  Future<List<UserImageAsset>> getAll() async {
    final rows = await (select(
      userImageAssets,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAtUtcMs)])).get();
    return List.unmodifiable(rows.map(_toDomain));
  }

  Future<UserImageAsset?> getById(String id) async {
    final row = await (select(
      userImageAssets,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> save(UserImageAsset asset) async {
    await into(userImageAssets).insertOnConflictUpdate(
      UserImageAssetsCompanion.insert(
        id: asset.id,
        createdAtUtcMs: asset.createdAt.millisecondsSinceEpoch,
        updatedAtUtcMs: asset.createdAt.millisecondsSinceEpoch,
        originalStorageKey: asset.originalStorageKey,
        previewStorageKey: asset.previewStorageKey,
        cropCenterX: asset.cropSpec.centerX,
        cropCenterY: asset.cropSpec.centerY,
        cropScale: asset.cropSpec.scale,
        cropRotation: asset.cropSpec.rotation,
      ),
    );
  }

  Future<void> deleteById(String id) async {
    await (delete(userImageAssets)..where((table) => table.id.equals(id))).go();
  }

  static UserImageAsset _toDomain(UserImageAssetRow row) {
    return UserImageAsset(
      id: row.id,
      originalStorageKey: row.originalStorageKey,
      previewStorageKey: row.previewStorageKey,
      cropSpec: CropSpec(
        centerX: row.cropCenterX,
        centerY: row.cropCenterY,
        scale: row.cropScale,
        rotation: row.cropRotation,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtcMs,
        isUtc: true,
      ),
    );
  }
}
