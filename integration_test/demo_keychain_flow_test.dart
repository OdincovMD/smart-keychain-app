import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_keychain_app/app/bootstrap.dart';
import 'package:smart_keychain_app/application/delete_user_image_scene.dart';
import 'package:smart_keychain_app/application/user_image_workflow.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/domain/image/user_image_id_generator.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('edit and delete survive full application bootstrap restarts', (
    tester,
  ) async {
    final sourceData = await rootBundle.load(
      'assets/scenes/eyes_mint_static_v1.png',
    );
    final sourceBytes = sourceData.buffer.asUint8List();
    final assetId =
        'integration-restart-${DateTime.now().microsecondsSinceEpoch}';
    final first = await bootstrap(log: _ignoreFailure);
    final workflow = UserImageWorkflow(
      clock: Clock.fixed(DateTime.utc(2026, 9, 3)),
      idGenerator: _FixedImageIdGenerator(assetId),
      picker: _FixedImagePicker(sourceBytes),
      processor: first.imageProcessor,
      storage: first.localFileStorage,
      assets: first.userImageAssetRepository,
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
    final sceneId = UserImageSceneRepository.sceneIdForAsset(asset.id);
    final editedCrop = CropSpec(
      centerX: 0.34,
      centerY: 0.69,
      scale: 2.2,
      rotation: 0.3,
    );
    expect(
      await workflow.updateCrop(
        assetId: asset.id,
        cropSpec: editedCrop,
        targetProfile: VirtualDeviceEngine.displayProfile,
      ),
      isA<Ok<UserImageAsset, UserImageFailure>>(),
    );
    await first.close();

    final second = await bootstrap(log: _ignoreFailure);
    final restored = await second.userImageAssetRepository.getById(asset.id);
    expect(
      (restored as Ok<UserImageAsset?, UserImageFailure>).value?.cropSpec,
      editedCrop,
    );
    expect((await second.sceneRepository.getById(sceneId))?.id, sceneId);
    await second.deviceRepository.connect(VirtualDeviceEngine.deviceId);
    await second.deviceRepository.setScene(sceneId);
    await second.settingsRepository.saveActiveSceneId(sceneId);
    expect(
      await DeleteUserImageScene(
        assets: second.userImageAssetRepository,
        storage: second.localFileStorage,
        device: second.deviceRepository,
        settings: second.settingsRepository,
        fallbackSceneId: BuiltInSceneRepository.livingEyesId,
        log: _ignoreFailure,
      )(sceneId),
      isA<Ok<void, UserImageFailure>>(),
    );
    await second.close();

    final third = await bootstrap(log: _ignoreFailure);
    final afterDelete = await third.userImageAssetRepository.getById(asset.id);
    expect(
      (afterDelete as Ok<UserImageAsset?, UserImageFailure>).value,
      isNull,
    );
    expect(await third.sceneRepository.getById(sceneId), isNull);
    final originalExists = await third.localFileStorage.exists(
      asset.originalStorageKey,
    );
    final previewExists = await third.localFileStorage.exists(
      asset.previewStorageKey,
    );
    expect((originalExists as Ok<bool, StorageFailure>).value, isFalse);
    expect((previewExists as Ok<bool, StorageFailure>).value, isFalse);
    expect(
      (await third.settingsRepository.load()).activeSceneId,
      BuiltInSceneRepository.livingEyesId,
    );
    await third.close();
  });

  testWidgets('connect, customize, and disconnect Demo Keychain', (
    tester,
  ) async {
    await app.main();
    await tester.pump();

    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 650));
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.livingEyesId)),
      findsOneWidget,
    );

    final staticScene = find.byKey(const Key('scene_eyes_mint_static_v1'));
    await tester.scrollUntilVisible(
      staticScene,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    await tester.tap(staticScene);
    await tester.tap(find.byKey(const Key('install_scene_button')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.mintEyesId)),
      findsOneWidget,
    );

    final brightnessButton = find.byKey(
      const Key('brightness_settings_button'),
    );
    await tester.ensureVisible(brightnessButton);
    await tester.pump();
    await tester.tap(brightnessButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-120, 0),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tapAt(const Offset(12, 12));
    await tester.pump(const Duration(milliseconds: 300));

    final disconnectButton = find.byKey(const Key('disconnect_button'));
    await tester.ensureVisible(disconnectButton);
    await tester.pump();
    await tester.tap(disconnectButton);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Нашли тебя'), findsOneWidget);
  });
}

final class _FixedImagePicker implements ImagePickerGateway {
  const _FixedImagePicker(this.bytes);

  final Uint8List bytes;

  @override
  Future<ImagePickOutcome> pickFromGallery() async =>
      ImagePicked(PickedImage(bytes: bytes, fileExtension: 'png'));
}

final class _FixedImageIdGenerator implements UserImageIdGenerator {
  const _FixedImageIdGenerator(this.id);

  final String id;

  @override
  String next(DateTime createdAt) => id;
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
