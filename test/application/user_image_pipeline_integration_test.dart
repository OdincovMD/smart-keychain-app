import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/application/delete_user_image_scene.dart';
import 'package:smart_keychain_app/application/user_image_workflow.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/data/database/app_database.dart';
import 'package:smart_keychain_app/data/image/drift_user_image_asset_repository.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/composite_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';
import 'package:smart_keychain_app/infrastructure/image/isolated_image_processor.dart';

import '../support/fake_local_file_storage.dart';
import '../support/fake_app_settings_repository.dart';
import '../support/fake_user_image_services.dart';

void main() {
  test('fake picker to persisted scene to virtual screen resolution', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final assets = DriftUserImageAssetRepository(database, log: _ignoreFailure);
    final storage = FakeLocalFileStorage();
    final original = await File('assets/scenes/eyes_mint_static_v1.png')
        .readAsBytes();
    final workflow = UserImageWorkflow(
      clock: Clock.fixed(DateTime.utc(2026, 9, 2)),
      idGenerator: FakeUserImageIdGenerator('integration-asset'),
      picker: FakeImagePickerGateway(
        ImagePicked(PickedImage(bytes: original, fileExtension: 'png')),
      ),
      processor: const IsolatedImageProcessor(log: _ignoreFailure),
      storage: storage,
      assets: assets,
    );

    final begin = await workflow.beginImport();
    expect(begin, isA<UserImageImportReady>());
    final created = await workflow.completeImport(
      draft: (begin as UserImageImportReady).draft,
      cropSpec: CropSpec.centered,
      targetProfile: VirtualDeviceEngine.displayProfile,
    );
    expect(created, isA<Ok<UserImageAsset, UserImageFailure>>());
    final asset = (created as Ok<UserImageAsset, UserImageFailure>).value;

    final scenes = CompositeSceneRepository([
      BuiltInSceneRepository(),
      UserImageSceneRepository(assets),
    ]);
    final sceneId = UserImageSceneRepository.sceneIdForAsset(asset.id);
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      ),
    );
    addTearDown(device.dispose);
    await device.connect(VirtualDeviceEngine.deviceId);
    await device.setScene(sceneId);

    final activeId = (await device.watchDeviceState().first).activeSceneId;
    final resolved = await scenes.getById(activeId);
    expect(resolved?.content, isA<UserImageContent>());
    expect(
      storage.existingPaths,
      containsAll([asset.originalStorageKey, asset.previewStorageKey]),
    );

    final editedCrop = CropSpec(
      centerX: 0.32,
      centerY: 0.73,
      scale: 2.1,
      rotation: 0.35,
    );
    final edited = await workflow.updateCrop(
      assetId: asset.id,
      cropSpec: editedCrop,
      targetProfile: VirtualDeviceEngine.displayProfile,
    );
    expect(edited, isA<Ok<UserImageAsset, UserImageFailure>>());

    // Rebuild the repository graph as a full app restart would. The database
    // and controlled filesystem remain the durable sources of truth.
    final assetsAfterEditRestart = DriftUserImageAssetRepository(
      database,
      log: _ignoreFailure,
    );
    final scenesAfterEditRestart = CompositeSceneRepository([
      BuiltInSceneRepository(),
      UserImageSceneRepository(assetsAfterEditRestart),
    ]);
    final restoredAsset = await assetsAfterEditRestart.getById(asset.id);
    expect(
      (restoredAsset as Ok<UserImageAsset?, UserImageFailure>).value?.cropSpec,
      editedCrop,
    );
    expect((await scenesAfterEditRestart.getById(sceneId))?.id, sceneId);

    final settings = FakeAppSettingsRepository(
      initialSettings: AppSettings(
        activeSceneId: sceneId,
        brightness: AppSettings.defaultBrightness,
      ),
    );
    final deleted = await DeleteUserImageScene(
      assets: assetsAfterEditRestart,
      storage: storage,
      device: device,
      settings: settings,
      fallbackSceneId: BuiltInSceneRepository.livingEyesId,
      log: _ignoreFailure,
    )(sceneId);
    expect(deleted, isA<Ok<void, UserImageFailure>>());

    final assetsAfterDeleteRestart = DriftUserImageAssetRepository(
      database,
      log: _ignoreFailure,
    );
    final scenesAfterDeleteRestart = UserImageSceneRepository(
      assetsAfterDeleteRestart,
    );
    expect(await scenesAfterDeleteRestart.getAll(), isEmpty);
    expect(storage.existingPaths, isEmpty);
    expect(
      (await device.watchDeviceState().first).activeSceneId,
      BuiltInSceneRepository.livingEyesId,
    );
  });
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
