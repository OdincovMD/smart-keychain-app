import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_screen.dart';
import 'package:smart_keychain_app/features/image_import/create_look_screen.dart';
import 'package:smart_keychain_app/features/user_content/look_details_sheet.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/composite_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  testWidgets('pick, crop, save, select, and render a user image scene', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final bytes = (await tester.runAsync(
      () => File('assets/scenes/eyes_mint_static_v1.png').readAsBytes(),
    ))!;
    final assets = FakeUserImageAssetRepository();
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
    addTearDown(device.dispose);
    final processor = FakeImageProcessor()..previewBytes = bytes;
    final storage = FakeLocalFileStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sceneRepositoryProvider.overrideWithValue(scenes),
          deviceRepositoryProvider.overrideWithValue(device),
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          localFileStorageProvider.overrideWithValue(storage),
          userImageAssetRepositoryProvider.overrideWithValue(assets),
          imagePickerGatewayProvider.overrideWithValue(
            FakeImagePickerGateway(
              ImagePicked(PickedImage(bytes: bytes, fileExtension: 'png')),
            ),
          ),
          imageProcessorProvider.overrideWithValue(processor),
          userImageIdGeneratorProvider.overrideWithValue(
            FakeUserImageIdGenerator('widget-asset'),
          ),
          failureLoggerProvider.overrideWithValue(_ignoreFailure),
        ],
        child: const SmartKeychainApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('add_user_image_button')), findsOneWidget);
    final myContent = find.byKey(const Key('open_my_content_button'));
    await tester.ensureVisible(myContent);
    await tester.pump();
    await tester.tap(myContent);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(
        const Key('my_content_scene_${BuiltInSceneRepository.livingEyesId}'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('wardrobe_photos_tab')));
    await tester.pump(const Duration(milliseconds: 200));
    final emptyAdd = find.byKey(const Key('wardrobe_empty_create_button'));
    expect(find.byKey(const Key('wardrobe_empty_state')), findsOneWidget);
    await tester.ensureVisible(emptyAdd);
    await tester.pump();
    await tester.tap(emptyAdd);
    await tester.pump();
    await tester.pump();
    expect(find.byType(CreateLookScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('create_look_pick_photo')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ImageEditorScreen), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('image_editor_save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_save')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    const sceneKey = Key('my_content_scene_user-image:widget-asset');
    expect(find.byKey(const Key('user_content_screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wardrobe_photos_tab')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.byKey(sceneKey));
    await tester.pump();
    expect(find.byKey(sceneKey), findsOneWidget);
    expect(find.byKey(const Key('wardrobe_empty_state')), findsNothing);
    expect(find.byKey(const Key('look_saved_marker')), findsOneWidget);

    await tester.tap(find.byKey(sceneKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    const install = Key('set_current_user-image:widget-asset');
    final detailsScroll = find.descendant(
      of: find.byType(LookDetailsSheet),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(detailsScroll, const Offset(0, -520));
    await tester.pump();
    await tester.tap(find.byKey(install));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      (await device.watchDeviceState().first).activeSceneId,
      'user-image:widget-asset',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('look_details_preview')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
