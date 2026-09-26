@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';
import 'package:smart_keychain_app/features/image_import/create_look_screen.dart';
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
  setUpAll(loadCompanionHomeFonts);

  testWidgets('Wardrobe Pearl matches Figma node 74:83', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(
      tester,
      rig,
      ResolvedAppAppearance.pearl,
      size: const Size(393, 852),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_pearl_figma_74_83.png'),
    );
  });

  testWidgets('Wardrobe Obsidian matches Figma node 226:1120', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(
      tester,
      rig,
      ResolvedAppAppearance.obsidian,
      size: const Size(393, 852),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_obsidian_figma_226_1120.png'),
    );
  });

  testWidgets('Create Look Pearl matches Figma node 94:248', (tester) async {
    await _pumpCreateLook(
      tester,
      ResolvedAppAppearance.pearl,
      size: const Size(393, 852),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_pearl_figma_94_248.png'),
    );
  });

  testWidgets('Create Look Obsidian matches Figma node 226:1316', (
    tester,
  ) async {
    await _pumpCreateLook(
      tester,
      ResolvedAppAppearance.obsidian,
      size: const Size(393, 852),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_obsidian_figma_226_1316.png'),
    );
  });

  testWidgets('Wardrobe Obsidian', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.obsidian);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_obsidian_390x844.png'),
    );
  });

  testWidgets('Wardrobe Pearl', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.pearl);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_pearl_390x844.png'),
    );
  });

  testWidgets('Wardrobe Loading Obsidian 390x844', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 0);
    await _pumpWardrobe(
      tester,
      rig,
      ResolvedAppAppearance.obsidian,
      loading: true,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_loading_obsidian_390x844.png'),
    );
  });

  testWidgets('Wardrobe Loading Pearl 390x844', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 0);
    await _pumpWardrobe(
      tester,
      rig,
      ResolvedAppAppearance.pearl,
      loading: true,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_loading_pearl_390x844.png'),
    );
  });

  testWidgets('Wardrobe Empty Photos Obsidian 390x844', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 0);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.obsidian);
    await _selectPhotosTab(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_empty_photos_obsidian_390x844.png'),
    );
  });

  testWidgets('Wardrobe Empty Photos Pearl 390x844', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 0);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.pearl);
    await _selectPhotosTab(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_empty_photos_pearl_390x844.png'),
    );
  });

  testWidgets('Built-in look details Obsidian', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.obsidian);
    await _openLivingEyes(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/look_details_obsidian.png'),
    );
  });

  testWidgets('Built-in look details Pearl', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.pearl);
    await _openLivingEyes(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/look_details_pearl.png'),
    );
  });

  testWidgets('Wardrobe with user content Obsidian', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 3);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.obsidian);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_user_content_obsidian.png'),
    );
  });

  testWidgets('Wardrobe empty user content Obsidian', (tester) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 0);
    await _pumpWardrobe(tester, rig, ResolvedAppAppearance.obsidian);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/wardrobe_empty_user_content_obsidian.png'),
    );
  });

  testWidgets('Create look success returns to Wardrobe Obsidian', (
    tester,
  ) async {
    final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
    await _pumpWardrobe(
      tester,
      rig,
      ResolvedAppAppearance.obsidian,
      highlightedSceneId: 'user-image:golden-1',
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_success_wardrobe_obsidian.png'),
    );
  });

  const responsiveSizes = <Size>[
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
  ];
  for (final appearance in ResolvedAppAppearance.values) {
    for (final size in responsiveSizes) {
      testWidgets(
        'Wardrobe ${appearance.name} fits ${size.width.toInt()}x${size.height.toInt()} at 180% reduced motion',
        (tester) async {
          final rig = await _WardrobeGoldenRig.create(tester, userLookCount: 1);
          await _pumpWardrobe(
            tester,
            rig,
            appearance,
            size: size,
            textScaler: const TextScaler.linear(1.8),
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('user_content_screen')), findsOneWidget);
        },
      );

      testWidgets(
        'Create Look ${appearance.name} fits ${size.width.toInt()}x${size.height.toInt()} at 180% reduced motion',
        (tester) async {
          await _pumpCreateLook(
            tester,
            appearance,
            size: size,
            textScaler: const TextScaler.linear(1.8),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(CreateLookScreen), findsOneWidget);
        },
      );
    }
  }
}

Future<void> _pumpCreateLook(
  WidgetTester tester,
  ResolvedAppAppearance appearance, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(appearance),
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: textScaler, disableAnimations: true),
        child: child!,
      ),
      home: const CreateLookScreen(),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(CreateLookScreen));
    await Future.wait([
      for (final asset in <String>[
        'assets/chrome_kiss/create_story_blush.png',
        'assets/chrome_kiss/create_progress_jewels.png',
        'assets/chrome_kiss/create_upload_blush.png',
        'assets/chrome_kiss/create_upload_halo.png',
        'assets/chrome_kiss/create_upload_bow.png',
        'assets/chrome_kiss/create_champagne_sparkle.png',
        'assets/chrome_kiss/create_preview_original.png',
        'assets/chrome_kiss/create_preview_mint.png',
        'assets/chrome_kiss/create_preview_lilac.png',
        'assets/chrome_kiss/create_preview_sparkle.png',
      ])
        precacheImage(AssetImage(asset), context),
    ]);
  });
  await tester.pump();
}

final class _WardrobeGoldenRig {
  const _WardrobeGoldenRig({
    required this.scenes,
    required this.device,
    required this.settings,
    required this.storage,
    required this.assets,
    required this.processor,
  });

  final CompositeSceneRepository scenes;
  final VirtualDeviceRepository device;
  final FakeAppSettingsRepository settings;
  final FakeLocalFileStorage storage;
  final FakeUserImageAssetRepository assets;
  final FakeImageProcessor processor;

  static Future<_WardrobeGoldenRig> create(
    WidgetTester tester, {
    required int userLookCount,
  }) async {
    final bytes = (await tester.runAsync(
      () => File('assets/chrome_kiss/wardrobe_user_photo.jpeg').readAsBytes(),
    ))!;
    final storage = FakeLocalFileStorage();
    final items = <UserImageAsset>[];
    for (var index = 0; index < userLookCount; index++) {
      final id = 'golden-${index + 1}';
      final original = await storage.write(
        namespace: LocalStorageNamespace.userImageOriginals,
        fileName: '$id.png',
        bytes: bytes,
      );
      final preview = await storage.write(
        namespace: LocalStorageNamespace.userImagePreviews,
        fileName: '$id.png',
        bytes: bytes,
      );
      items.add(
        UserImageAsset(
          id: id,
          originalStorageKey: (original as Ok<String, StorageFailure>).value,
          previewStorageKey: (preview as Ok<String, StorageFailure>).value,
          cropSpec: CropSpec.centered,
          createdAt: DateTime.utc(2026, 9, index + 1),
        ),
      );
    }
    final assets = FakeUserImageAssetRepository(items);
    final scenes = CompositeSceneRepository([
      BuiltInSceneRepository(),
      UserImageSceneRepository(assets),
    ]);
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      ),
    );
    return _WardrobeGoldenRig(
      scenes: scenes,
      device: device,
      settings: FakeAppSettingsRepository(
        initialSettings: const AppSettings(
          activeSceneId: BuiltInSceneRepository.livingEyesId,
          brightness: AppSettings.defaultBrightness,
        ),
      ),
      storage: storage,
      assets: assets,
      processor: FakeImageProcessor()..previewBytes = bytes,
    );
  }
}

Future<void> _pumpWardrobe(
  WidgetTester tester,
  _WardrobeGoldenRig rig,
  ResolvedAppAppearance appearance, {
  String? highlightedSceneId,
  Size size = const Size(390, 844),
  bool loading = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await rig.device.dispose();
    tester.view.reset();
  });

  final connection = rig.device.connect(VirtualDeviceEngine.deviceId);
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await connection;

  final pendingScenes = Completer<List<Scene>>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(rig.scenes),
        if (loading)
          sceneLibraryProvider.overrideWith((ref) => pendingScenes.future),
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
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: textScaler, disableAnimations: true),
          child: child!,
        ),
        home: UserContentScreen(highlightedSceneId: highlightedSceneId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const Key('user_content_screen'))),
  );
  await tester.runAsync(() async {
    await Future.wait([
      for (final asset in rig.assets.values)
        container.read(localImageBytesProvider(asset.previewStorageKey).future),
    ]);
  });
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await Future.wait([
      precacheImage(
        const AssetImage('assets/scenes/eyes_mint_static_v1.png'),
        context,
      ),
      precacheImage(
        const AssetImage('assets/scenes/sunny_friend_static_v1.png'),
        context,
      ),
      precacheImage(
        ResizeImage(MemoryImage(rig.processor.previewBytes), width: 240),
        context,
      ),
      for (final asset in <String>[
        'assets/chrome_kiss/wardrobe_pearl_blush.png',
        'assets/chrome_kiss/wardrobe_lilac_blush.png',
        'assets/chrome_kiss/wardrobe_blush_veil.png',
        'assets/chrome_kiss/wardrobe_current_look.png',
        'assets/chrome_kiss/wardrobe_glossy_bow.png',
        'assets/chrome_kiss/home_look_original.png',
        'assets/chrome_kiss/home_look_mint.png',
      ])
        precacheImage(AssetImage(asset), context),
    ]);
  });
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectPhotosTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('wardrobe_photos_tab')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.byKey(const Key('wardrobe_empty_state')), findsOneWidget);
}

Future<void> _openLivingEyes(WidgetTester tester) async {
  await tester.tap(
    find.byKey(
      const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
    ),
  );
  await tester.pump();
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
