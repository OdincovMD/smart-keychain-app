import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/data/database/app_database.dart';
import 'package:smart_keychain_app/data/image/drift_user_image_asset_repository.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';

void main() {
  late AppDatabase database;
  late DriftUserImageAssetRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftUserImageAssetRepository(database, log: _ignoreFailure);
  });

  tearDown(() => database.close());

  test(
    'creates, loads, round-trips crop metadata, and deletes asset',
    () async {
      final asset = UserImageAsset(
        id: 'asset-1',
        originalStorageKey: 'user-content/originals/asset-1.jpg',
        previewStorageKey: 'user-content/previews/asset-1.png',
        cropSpec: CropSpec(
          centerX: 0.25,
          centerY: 0.75,
          scale: 2.25,
          rotation: 0.5,
        ),
        createdAt: DateTime.utc(2026, 9, 2, 12),
      );

      expect(await repository.save(asset), isA<Ok<void, UserImageFailure>>());
      final loaded = await repository.getById(asset.id);
      expect(loaded, isA<Ok<UserImageAsset?, UserImageFailure>>());
      expect((loaded as Ok<UserImageAsset?, UserImageFailure>).value, asset);

      final all = await repository.getAll();
      expect((all as Ok<List<UserImageAsset>, UserImageFailure>).value, [
        asset,
      ]);

      expect(
        await repository.delete(asset.id),
        isA<Ok<void, UserImageFailure>>(),
      );
      final afterDelete = await repository.getById(asset.id);
      expect(
        (afterDelete as Ok<UserImageAsset?, UserImageFailure>).value,
        isNull,
      );
    },
  );
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
