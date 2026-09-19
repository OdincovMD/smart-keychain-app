import 'dart:async';
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
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/content/scene_repository.dart';
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
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets(
    'empty user collection keeps built-in looks and Add Look action',
    (tester) async {
      final rig = await _UserContentRig.create(tester, withAsset: false);
      await _pumpScreen(tester, rig);

      expect(find.byKey(const Key('my_content_list')), findsOneWidget);
      expect(
        find.byKey(
          const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('my_content_empty_add_button')),
        findsOneWidget,
      );
      expect(find.text('Добавить'), findsOneWidget);
    },
  );

  testWidgets(
    'loading keeps Wardrobe chrome and reserves collection geometry',
    (tester) async {
      final rig = await _UserContentRig.create(tester, withAsset: false);
      final repository = _ScriptedSceneRepository(rig.scenes, pending: true);
      await _pumpScreen(tester, rig, sceneRepository: repository);

      expect(find.text('Гардероб'), findsOneWidget);
      expect(find.byKey(const Key('wardrobe_looks_tab')), findsOneWidget);
      expect(find.byKey(const Key('wardrobe_loading_state')), findsOneWidget);
      expect(
        find.byKey(const Key('chrome_kiss_bottom_navigation')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Гардероб загружается'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('scene library retry restores the built-in collection', (
    tester,
  ) async {
    final rig = await _UserContentRig.create(tester, withAsset: false);
    final repository = _ScriptedSceneRepository(rig.scenes, failFirst: true);
    await _pumpScreen(tester, rig, sceneRepository: repository);

    expect(find.byKey(const Key('wardrobe_error_state')), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    await tester.tap(find.byKey(const Key('wardrobe_retry_button')));
    await tester.pump();
    await tester.pump();

    expect(repository.getAllCalls, 2);
    expect(find.byKey(const Key('wardrobe_error_state')), findsNothing);
    expect(
      find.byKey(
        const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty state is limited to the user photo tab', (tester) async {
    final rig = await _UserContentRig.create(tester, withAsset: false);
    await _pumpScreen(tester, rig);

    final builtIn = find.byKey(
      const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
    );
    expect(builtIn, findsOneWidget);
    expect(find.byKey(const Key('wardrobe_empty_state')), findsNothing);

    await tester.tap(find.byKey(const Key('wardrobe_photos_tab')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('wardrobe_empty_state')), findsOneWidget);
    expect(
      find.byKey(const Key('wardrobe_empty_create_button')),
      findsOneWidget,
    );
    expect(builtIn, findsNothing);
    expect(
      find.byKey(const Key('chrome_kiss_bottom_navigation')),
      findsOneWidget,
    );
  });

  testWidgets('unifies all looks and restores existing crop in editor', (
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
      findsOneWidget,
    );

    await _openLookDetails(tester, sceneId);
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

    await _openLookDetails(tester, sceneId);
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

      await _openLookDetails(tester, sceneId);
      await tester.tap(find.byKey(Key('delete_$sceneId')));
      await _pumpSheetSwap(tester);
      expect(
        find.byKey(const Key('delete_image_confirmation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('cancel_delete_image')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(rig.assets.values, [rig.asset]);
      expect(rig.storage.existingPaths, hasLength(2));

      await _openLookDetails(tester, sceneId);
      await tester.tap(find.byKey(Key('delete_$sceneId')));
      await _pumpSheetSwap(tester);
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

      await _openLookDetails(tester, sceneId);
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

  for (final testCase in const [
    (
      name: 'compact 320x640',
      size: Size(320, 640),
      scale: 1.0,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: 'Android insets',
      size: Size(390, 844),
      scale: 1.0,
      top: 24.0,
      bottom: 24.0,
    ),
    (
      name: 'large 430x932',
      size: Size(430, 932),
      scale: 1.0,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: 'text scale 180%',
      size: Size(390, 844),
      scale: 1.8,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: 'text scale 300%',
      size: Size(390, 844),
      scale: 3.0,
      top: 0.0,
      bottom: 0.0,
    ),
  ]) {
    testWidgets('Wardrobe remains usable at ${testCase.name}', (tester) async {
      final rig = await _UserContentRig.create(tester);
      await _pumpScreen(
        tester,
        rig,
        size: testCase.size,
        textScaler: TextScaler.linear(testCase.scale),
        viewPadding: EdgeInsets.only(
          top: testCase.top,
          bottom: testCase.bottom,
        ),
      );

      expect(find.text('Гардероб'), findsOneWidget);
      final scrollable = find.byKey(const Key('wardrobe_scroll'));
      final contentList = find.byKey(const Key('my_content_list'));
      await _dragUntilBuilt(
        tester,
        target: contentList,
        scrollable: scrollable,
      );
      expect(find.byKey(const Key('my_content_add_button')), findsOneWidget);

      final firstTile = find.byKey(
        const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
      );
      final secondTile = find.byKey(
        const Key('my_content_scene_${BuiltInSceneRepository.mintEyesId}'),
      );
      expect(firstTile, findsOneWidget);
      expect(secondTile, findsOneWidget);
      expect(
        (tester.getTopLeft(firstTile).dy - tester.getTopLeft(secondTile).dy)
            .abs(),
        lessThan(1),
      );
      expect(
        tester.getTopLeft(secondTile).dx,
        greaterThan(tester.getTopLeft(firstTile).dx),
      );
      final navigation = find.byKey(const Key('chrome_kiss_bottom_navigation'));
      await _dragUntilBuilt(tester, target: navigation, scrollable: scrollable);
      expect(
        tester.getRect(navigation).width,
        lessThanOrEqualTo(testCase.size.width),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
    testWidgets(
      'Wardrobe empty photos fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final rig = await _UserContentRig.create(tester, withAsset: false);
        await _pumpScreen(tester, rig, size: size);
        await tester.tap(find.byKey(const Key('wardrobe_photos_tab')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byKey(const Key('wardrobe_empty_state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Wardrobe loading fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final rig = await _UserContentRig.create(tester, withAsset: false);
        final repository = _ScriptedSceneRepository(rig.scenes, pending: true);
        await _pumpScreen(tester, rig, size: size, sceneRepository: repository);

        expect(find.byKey(const Key('wardrobe_loading_state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Wardrobe media states remain readable at 180% text', (
    tester,
  ) async {
    final rig = await _UserContentRig.create(tester, withAsset: false);
    await _pumpScreen(tester, rig, textScaler: const TextScaler.linear(1.8));
    await tester.tap(find.byKey(const Key('wardrobe_photos_tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('wardrobe_empty_state')), findsOneWidget);
    final create = find.byKey(const Key('wardrobe_empty_create_button'));
    await tester.ensureVisible(create);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('look details remains usable on compact accessibility view', (
    tester,
  ) async {
    final rig = await _UserContentRig.create(tester);
    await _pumpScreen(
      tester,
      rig,
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(3),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
    );
    final sceneId = UserImageSceneRepository.sceneIdForAsset(rig.asset!.id);
    final tile = find.byKey(Key('my_content_scene_$sceneId'));
    await _dragUntilBuilt(
      tester,
      target: tile,
      scrollable: find.byKey(const Key('wardrobe_scroll')),
    );
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('look_details_scroll')), findsOneWidget);
    final edit = find.byKey(Key('edit_$sceneId'));
    await tester.ensureVisible(edit);
    await tester.pump();
    expect(tester.getRect(edit).bottom, lessThanOrEqualTo(616));
    expect(tester.takeException(), isNull);
  });

  testWidgets('built-in look details do not expose edit or delete', (
    tester,
  ) async {
    final rig = await _UserContentRig.create(tester, withAsset: false);
    await _pumpScreen(tester, rig);

    await _openLookDetails(tester, BuiltInSceneRepository.livingEyesId);

    expect(
      find.byKey(const Key('edit_${BuiltInSceneRepository.livingEyesId}')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('delete_${BuiltInSceneRepository.livingEyesId}')),
      findsNothing,
    );
  });
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

Future<void> _dragUntilBuilt(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollable,
}) async {
  for (var attempt = 0; attempt < 10 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -420));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _UserContentRig rig, {
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets viewPadding = EdgeInsets.zero,
  SceneRepository? sceneRepository,
}) async {
  final connection = rig.device.connect(VirtualDeviceEngine.deviceId);
  await _pumpCommandFrames(tester, 6);
  await connection;
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..padding = FakeViewPadding(
      top: viewPadding.top,
      bottom: viewPadding.bottom,
    )
    ..viewPadding = FakeViewPadding(
      top: viewPadding.top,
      bottom: viewPadding.bottom,
    );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.view.reset();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(
          sceneRepository ?? rig.scenes,
        ),
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const UserContentScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

final class _ScriptedSceneRepository implements SceneRepository {
  _ScriptedSceneRepository(
    this.delegate, {
    this.pending = false,
    this.failFirst = false,
  });

  final SceneRepository delegate;
  final bool pending;
  final bool failFirst;
  final Completer<List<Scene>> _pendingScenes = Completer<List<Scene>>();
  int getAllCalls = 0;

  @override
  Future<List<Scene>> getAll() {
    getAllCalls++;
    if (pending) return _pendingScenes.future;
    if (failFirst && getAllCalls == 1) {
      return Future<List<Scene>>.error(StateError('scene library failed'));
    }
    return delegate.getAll();
  }

  @override
  Future<Scene?> getById(String id) => delegate.getById(id);
}

Future<void> _openLookDetails(WidgetTester tester, String sceneId) async {
  final tile = find.byKey(Key('my_content_scene_$sceneId'));
  await tester.ensureVisible(tile);
  await tester.pump();
  await tester.tap(tile);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(const Key('look_details_preview')), findsOneWidget);
}

Future<void> _pumpSheetSwap(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}

Future<void> _pumpCommandFrames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}
