import '../../core/result.dart';
import 'user_image_asset.dart';
import 'user_image_failure.dart';

abstract interface class UserImageAssetRepository {
  Future<Result<List<UserImageAsset>, UserImageFailure>> getAll();

  Future<Result<UserImageAsset?, UserImageFailure>> getById(String id);

  Future<Result<void, UserImageFailure>> save(UserImageAsset asset);

  Future<Result<void, UserImageFailure>> delete(String id);
}
