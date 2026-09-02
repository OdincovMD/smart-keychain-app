import '../../core/result.dart';
import '../../domain/content/scene.dart';
import '../../domain/content/scene_repository.dart';
import '../../domain/image/user_image_asset.dart';
import '../../domain/image/user_image_asset_repository.dart';

final class UserImageSceneRepository implements SceneRepository {
  UserImageSceneRepository(this._assets);

  static const sceneIdPrefix = 'user-image:';

  final UserImageAssetRepository _assets;

  static String sceneIdForAsset(String assetId) => '$sceneIdPrefix$assetId';

  static String? assetIdFromScene(String sceneId) {
    return sceneId.startsWith(sceneIdPrefix)
        ? sceneId.substring(sceneIdPrefix.length)
        : null;
  }

  @override
  Future<List<Scene>> getAll() async {
    return switch (await _assets.getAll()) {
      Ok(:final value) => List.unmodifiable(value.map(_toScene)),
      Err() => const [],
    };
  }

  @override
  Future<Scene?> getById(String id) async {
    final assetId = assetIdFromScene(id);
    if (assetId == null || assetId.isEmpty) return null;
    return switch (await _assets.getById(assetId)) {
      Ok(:final value) => value == null ? null : _toScene(value),
      Err() => null,
    };
  }

  static Scene _toScene(UserImageAsset asset) {
    return Scene(
      id: sceneIdForAsset(asset.id),
      name: 'Моё фото',
      description: 'Личное изображение на экране брелка.',
      content: UserImageContent(
        assetId: asset.id,
        previewStorageKey: asset.previewStorageKey,
      ),
      source: SceneSource.userGenerated,
      tags: const {'photo', 'user'},
    );
  }
}
