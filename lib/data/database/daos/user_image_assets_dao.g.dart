// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_image_assets_dao.dart';

// ignore_for_file: type=lint
mixin _$UserImageAssetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserImageAssetsTable get userImageAssets => attachedDatabase.userImageAssets;
  UserImageAssetsDaoManager get managers => UserImageAssetsDaoManager(this);
}

class UserImageAssetsDaoManager {
  final _$UserImageAssetsDaoMixin _db;
  UserImageAssetsDaoManager(this._db);
  $$UserImageAssetsTableTableManager get userImageAssets =>
      $$UserImageAssetsTableTableManager(
        _db.attachedDatabase,
        _db.userImageAssets,
      );
}
