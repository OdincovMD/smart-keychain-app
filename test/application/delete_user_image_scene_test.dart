import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/application/delete_user_image_scene.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/composite_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';

void main() {
  test(
    'deletes files and metadata and falls back active device scene',
    () async {
      final asset = UserImageAsset(
        id: 'asset-1',
        originalStorageKey: 'user-content/originals/asset-1.jpg',
        previewStorageKey: 'user-content/previews/asset-1.png',
        cropSpec: CropSpec.centered,
        createdAt: DateTime.utc(2026, 9, 2),
      );
      final assets = FakeUserImageAssetRepository([asset]);
      final scenes = CompositeSceneRepository([
        BuiltInSceneRepository(),
        UserImageSceneRepository(assets),
      ]);
      final userSceneId = UserImageSceneRepository.sceneIdForAsset(asset.id);
      final device = VirtualDeviceRepository(
        engine: VirtualDeviceEngine(
          sceneRepository: scenes,
          initialSceneId: userSceneId,
          latency: Duration.zero,
        ),
      );
      addTearDown(device.dispose);
      await device.connect(VirtualDeviceEngine.deviceId);

      final storage = FakeLocalFileStorage();
      expect(
        await storage.write(
          namespace: LocalStorageNamespace.userImageOriginals,
          fileName: 'asset-1.jpg',
          bytes: Uint8List.fromList([1, 2]),
        ),
        isA<Ok<String, StorageFailure>>(),
      );
      expect(
        await storage.write(
          namespace: LocalStorageNamespace.userImagePreviews,
          fileName: 'asset-1.png',
          bytes: Uint8List.fromList([3, 4]),
        ),
        isA<Ok<String, StorageFailure>>(),
      );
      final settings = FakeAppSettingsRepository(
        initialSettings: AppSettings(
          activeSceneId: userSceneId,
          brightness: AppSettings.defaultBrightness,
        ),
      );
      final operation = DeleteUserImageScene(
        assets: assets,
        storage: storage,
        device: device,
        settings: settings,
        fallbackSceneId: BuiltInSceneRepository.livingEyesId,
        log: _ignoreFailure,
      );

      final result = await operation(userSceneId);

      expect(result, isA<Ok<void, UserImageFailure>>());
      expect(storage.existingPaths, isEmpty);
      expect(assets.values, isEmpty);
      expect(
        (await device.watchDeviceState().first).activeSceneId,
        BuiltInSceneRepository.livingEyesId,
      );
      expect(
        settings.settings.activeSceneId,
        BuiltInSceneRepository.livingEyesId,
      );
    },
  );
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
