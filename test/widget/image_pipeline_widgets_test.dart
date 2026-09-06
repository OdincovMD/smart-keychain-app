import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/features/device_home/widgets/scene_renderer.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_screen.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_local_file_storage.dart';

void main() {
  testWidgets('image editor supports gesture, rotate, reset, and save', (
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

    await tester.pumpWidget(
      ProviderScope(child: _localizedEditor('editor-asset', bytes)),
    );
    await tester.pump();

    expect(find.byType(ImageEditorScreen), findsOneWidget);
    expect(find.byKey(const Key('image_crop_gesture')), findsOneWidget);
    await tester.tap(find.byKey(const Key('image_editor_rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_reset')));
    await tester.pump();

    expect(find.byKey(const Key('image_editor_save')), findsOneWidget);
    expect(find.byKey(const Key('image_editor_cancel')), findsOneWidget);
  });

  testWidgets('user image renderer resolves controlled preview bytes', (
    tester,
  ) async {
    final storage = FakeLocalFileStorage();
    final bytes = (await tester.runAsync(
      () => File('assets/scenes/eyes_mint_static_v1.png').readAsBytes(),
    ))!;
    await storage.write(
      namespace: LocalStorageNamespace.userImagePreviews,
      fileName: 'asset-1.png',
      bytes: bytes,
    );
    const scene = Scene(
      id: 'user-image:asset-1',
      name: 'Моё фото',
      content: UserImageContent(
        assetId: 'asset-1',
        previewStorageKey: 'user-content/previews/asset-1.png',
      ),
      source: SceneSource.userGenerated,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localFileStorageProvider.overrideWithValue(storage)],
        child: const MaterialApp(
          home: SizedBox.square(
            dimension: 240,
            child: SceneRenderer(scene: scene, animate: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UserImageSceneRenderer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}

Widget _localizedEditor(String assetId, Uint8List originalBytes) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('ru'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: ImageEditorScreen(assetId: assetId, originalBytes: originalBytes),
);
