import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/application/device_controller.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_screen.dart';
import 'package:smart_keychain_app/features/user_content/user_content_controller.dart';
import 'package:smart_keychain_app/features/user_content/user_content_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/composite_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';

void main() {
  testWidgets('empty My Content shows Add Image action', (tester) async {
    final rig = await _UserContentRig.create(tester, withAsset: false);
    await _pumpScreen(tester, rig);

    expect(find.byKey(const Key('my_content_list')), findsNothing);
    expect(
      find.byKey(const Key('my_content_empty_add_button')),
      findsOneWidget,
    );
    expect(find.text('Здесь появятся ваши фото'), findsOneWidget);
  });

  testWidgets('lists only user scenes and restores existing crop in editor', (
    tester,
  ) async {
    final rig = await _UserContentRig.create(tester);
    await _pumpScreen(tester, rig);
    final sceneId = UserImageSceneRepository.sceneIdForAsset(rig.asset!.id);

    expect(find.byKey(Key('my_content_scene_$sceneId')), findsOneWidget);
    expect(
      find.byKey(
        const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(Key('edit_$sceneId')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final editor = tester.widget<ImageEditorScreen>(
      find.byKey(const Key('user_content_editor_asset-1')),
    );
    expect(editor.assetId, rig.asset!.id);
    expect(editor.initialCropSpec, rig.asset!.cropSpec);
  });

  testWidgets('Set as current routes through the device controller', (
    tester,
  ) async {
    final rig = await _UserContentRig.create(tester);
    await _pumpScreen(tester, rig);
    final sceneId = UserImageSceneRepository.sceneIdForAsset(rig.asset!.id);

    expect(
      tester
          .widget<TextButton>(find.byKey(Key('set_current_$sceneId')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(Key('set_current_$sceneId')));
    await _pumpCommandFrames(tester, 12);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('user_content_screen'))),
    );
    final deviceCommand = container.read(deviceControllerProvider);
    expect(deviceCommand.hasError, isFalse, reason: '${deviceCommand.error}');
    expect(deviceCommand.isLoading, isFalse, reason: '$deviceCommand');

    expect((await rig.device.watchDeviceState().first).activeSceneId, sceneId);
    expect(rig.settings.settings.activeSceneId, sceneId);
  });

  testWidgets(
    'delete requires confirmation, cancel preserves, confirm removes',
    (tester) async {
      final rig = await _UserContentRig.create(tester, assetIsActive: true);
      await _pumpScreen(tester, rig);
      final sceneId = UserImageSceneRepository.sceneIdForAsset(rig.asset!.id);

      await tester.tap(find.byKey(Key('delete_$sceneId')));
      await tester.pump();
      expect(
        find.byKey(const Key('delete_image_confirmation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('cancel_delete_image')));
      await tester.pump();
      expect(rig.assets.values, [rig.asset]);
      expect(rig.storage.existingPaths, hasLength(2));

      expect(
        tester.widget<IconButton>(find.byKey(Key('delete_$sceneId'))).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(Key('delete_$sceneId')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm_delete_image')));
      await _pumpCommandFrames(tester, 24);
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('user_content_screen'))),
      );
      expect(
        container.read(userContentControllerProvider),
        const UserContentIdle(),
      );

      expect(rig.assets.values, isEmpty);
      expect(rig.storage.existingPaths, isEmpty);
      expect(find.byKey(Key('my_content_scene_$sceneId')), findsNothing);
      expect(
        (await rig.device.watchDeviceState().first).activeSceneId,
        BuiltInSceneRepository.livingEyesId,
      );
      expect(
        rig.settings.settings.activeSceneId,
        BuiltInSceneRepository.livingEyesId,
      );
    },
  );

  testWidgets(
    'failed edit keeps the previous valid asset and reports failure',
    (tester) async {
      final rig = await _UserContentRig.create(tester);
      await _pumpScreen(tester, rig);
      final sceneId = UserImageSceneRepository.sceneIdForAsset(rig.asset!.id);
      final oldPreview = await rig.storage.read(rig.asset!.previewStorageKey);

      await tester.tap(find.byKey(Key('edit_$sceneId')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      rig.assets.failSaves = true;
      await tester.tap(find.byKey(const Key('image_editor_rotate')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('image_editor_save')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(rig.assets.values, [rig.asset]);
      final restoredPreview = await rig.storage.read(
        rig.asset!.previewStorageKey,
      );
      expect(
        (restoredPreview as Ok<Uint8List, StorageFailure>).value,
        (oldPreview as Ok<Uint8List, StorageFailure>).value,
      );
      expect(
        find.text('Не удалось сохранить данные изображения.'),
        findsOneWidget,
      );
    },
  );
}

final class _UserContentRig {
  const _UserContentRig({
    required this.asset,
    required this.assets,
    required this.storage,
    required this.scenes,
    required this.device,
    required this.settings,
    required this.processor,
  });

  final UserImageAsset? asset;
  final FakeUserImageAssetRepository assets;
  final FakeLocalFileStorage storage;
  final CompositeSceneRepository scenes;
  final VirtualDeviceRepository device;
  final FakeAppSettingsRepository settings;
  final FakeImageProcessor processor;

  static Future<_UserContentRig> create(
    WidgetTester tester, {
    bool withAsset = true,
    bool assetIsActive = false,
  }) async {
    final bytes = (await tester.runAsync(
      () => File('assets/scenes/eyes_mint_static_v1.png').readAsBytes(),
    ))!;
    final storage = FakeLocalFileStorage();
    UserImageAsset? asset;
    if (withAsset) {
      final original = await storage.write(
        namespace: LocalStorageNamespace.userImageOriginals,
        fileName: 'asset-1.png',
        bytes: bytes,
      );
      final preview = await storage.write(
        namespace: LocalStorageNamespace.userImagePreviews,
        fileName: 'asset-1.png',
        bytes: bytes,
      );
      asset = UserImageAsset(
        id: 'asset-1',
        originalStorageKey: (original as Ok<String, StorageFailure>).value,
        previewStorageKey: (preview as Ok<String, StorageFailure>).value,
        cropSpec: CropSpec(
          centerX: 0.31,
          centerY: 0.67,
          scale: 2.2,
          rotation: 0.25,
        ),
        createdAt: DateTime.utc(2026, 9, 3),
      );
    }
    final assets = FakeUserImageAssetRepository([?asset]);
    final scenes = CompositeSceneRepository([
      BuiltInSceneRepository(),
      UserImageSceneRepository(assets),
    ]);
    final activeSceneId = assetIsActive && asset != null
        ? UserImageSceneRepository.sceneIdForAsset(asset.id)
        : BuiltInSceneRepository.livingEyesId;
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: activeSceneId,
        latency: Duration.zero,
      ),
    );
    final settings = FakeAppSettingsRepository(
      initialSettings: AppSettings(
        activeSceneId: activeSceneId,
        brightness: AppSettings.defaultBrightness,
      ),
    );
    return _UserContentRig(
      asset: asset,
      assets: assets,
      storage: storage,
      scenes: scenes,
      device: device,
      settings: settings,
      processor: FakeImageProcessor()..previewBytes = bytes,
    );
  }
}

Future<void> _pumpScreen(WidgetTester tester, _UserContentRig rig) async {
  final connection = rig.device.connect(VirtualDeviceEngine.deviceId);
  await _pumpCommandFrames(tester, 6);
  await connection;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.view.reset();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(rig.scenes),
        deviceRepositoryProvider.overrideWithValue(rig.device),
        appSettingsRepositoryProvider.overrideWithValue(rig.settings),
        localFileStorageProvider.overrideWithValue(rig.storage),
        userImageAssetRepositoryProvider.overrideWithValue(rig.assets),
        imagePickerGatewayProvider.overrideWithValue(
          FakeImagePickerGateway(const ImagePickCancelled()),
        ),
        imageProcessorProvider.overrideWithValue(rig.processor),
        userImageIdGeneratorProvider.overrideWithValue(
          FakeUserImageIdGenerator(),
        ),
        failureLoggerProvider.overrideWithValue(_ignoreFailure),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const UserContentScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}

Future<void> _pumpCommandFrames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}
