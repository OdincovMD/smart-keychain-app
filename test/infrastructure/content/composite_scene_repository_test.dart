import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/composite_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';

import '../../support/fake_user_image_services.dart';

void main() {
  test(
    'combines built-in and user scenes with uniform lookup and delete',
    () async {
      final asset = _asset();
      final assets = FakeUserImageAssetRepository([asset]);
      final repository = CompositeSceneRepository([
        BuiltInSceneRepository(),
        UserImageSceneRepository(assets),
      ]);
      final sceneId = UserImageSceneRepository.sceneIdForAsset(asset.id);

      final all = await repository.getAll();
      expect(all, hasLength(4));
      expect(all.first.id, BuiltInSceneRepository.livingEyesId);
      expect((await repository.getById(sceneId))?.id, sceneId);

      expect(await assets.delete(asset.id), isA<Ok<void, UserImageFailure>>());
      expect(await repository.getById(sceneId), isNull);
      expect(await repository.getAll(), hasLength(3));
    },
  );
}

UserImageAsset _asset() => UserImageAsset(
  id: 'asset-1',
  originalStorageKey: 'user-content/originals/asset-1.jpg',
  previewStorageKey: 'user-content/previews/asset-1.png',
  cropSpec: CropSpec.centered,
  createdAt: DateTime.utc(2026, 9, 2),
);
