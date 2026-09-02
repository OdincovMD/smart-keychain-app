// ignore_for_file: prefer_initializing_formals

import '../../core/failure_logger.dart';
import '../../core/result.dart';
import '../../domain/image/user_image_asset.dart';
import '../../domain/image/user_image_asset_repository.dart';
import '../../domain/image/user_image_failure.dart';
import '../database/app_database.dart';

final class DriftUserImageAssetRepository implements UserImageAssetRepository {
  DriftUserImageAssetRepository(this._database, {required FailureLogger log})
    : _log = log;

  final AppDatabase _database;
  final FailureLogger _log;

  @override
  Future<Result<void, UserImageFailure>> delete(String id) async {
    try {
      await _database.transaction(
        () => _database.userImageAssetsDao.deleteById(id),
      );
      return const Ok(null);
    } on Exception catch (error, stackTrace) {
      _log('image.persistence.delete', error, stackTrace);
      return const Err(ImagePersistenceFailure('delete'));
    }
  }

  @override
  Future<Result<List<UserImageAsset>, UserImageFailure>> getAll() async {
    try {
      return Ok(await _database.userImageAssetsDao.getAll());
    } on Exception catch (error, stackTrace) {
      _log('image.persistence.list', error, stackTrace);
      return const Err(ImagePersistenceFailure('list'));
    }
  }

  @override
  Future<Result<UserImageAsset?, UserImageFailure>> getById(String id) async {
    try {
      return Ok(await _database.userImageAssetsDao.getById(id));
    } on Exception catch (error, stackTrace) {
      _log('image.persistence.read', error, stackTrace);
      return const Err(ImagePersistenceFailure('read'));
    }
  }

  @override
  Future<Result<void, UserImageFailure>> save(UserImageAsset asset) async {
    try {
      await _database.transaction(
        () => _database.userImageAssetsDao.save(asset),
      );
      return const Ok(null);
    } on Exception catch (error, stackTrace) {
      _log('image.persistence.save', error, stackTrace);
      return const Err(ImagePersistenceFailure('save'));
    }
  }
}
