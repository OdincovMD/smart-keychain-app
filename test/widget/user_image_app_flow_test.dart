import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/features/device_home/widgets/virtual_screen.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/composite_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/content/user_image_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';

void main() {
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

    expect(find.byKey(const Key('add_user_image_button')), findsOneWidget);
    final myContent = find.byKey(const Key('open_my_content_button'));
    await tester.ensureVisible(myContent);
    await tester.pump();
    await tester.tap(myContent);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const Key('my_content_empty_add_button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('my_content_empty_add_button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ImageEditorScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('image_editor_save')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    // Let the confirmation snackbar leave before interacting with controls
    // behind it. The home screen has an autonomous eye ticker, so use an
    // exact duration instead of pumpAndSettle.
    await tester.pump(const Duration(seconds: 5));
    const sceneKey = Key('scene_user-image:widget-asset');
    final horizontalSceneList = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.right,
    );
    await tester.ensureVisible(horizontalSceneList);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(sceneKey),
      180,
      scrollable: horizontalSceneList,
    );
    await tester.pump();
    expect(find.byKey(sceneKey), findsOneWidget);

    await tester.tap(find.byKey(sceneKey));
    await tester.pump();
    final install = find.byKey(const Key('install_scene_button'));
    await tester.ensureVisible(install);
    await tester.pump();
    await tester.tap(install);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(VirtualScreen),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
