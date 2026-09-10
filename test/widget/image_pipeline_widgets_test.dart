import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/features/device_home/widgets/scene_renderer.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_screen.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_local_file_storage.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

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
    expect(find.text('Создать образ'), findsOneWidget);
    expect(find.text('Сохранить образ'), findsOneWidget);
    expect(find.byKey(const Key('image_crop_gesture')), findsOneWidget);
    await tester.tap(find.byKey(const Key('image_editor_rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_reset')));
    await tester.pump();

    expect(find.byKey(const Key('image_editor_save')), findsOneWidget);
    expect(find.byKey(const Key('image_editor_cancel')), findsOneWidget);
  });

  testWidgets('existing look uses edit copy and keeps the restored crop', (
    tester,
  ) async {
    final bytes = await _readFixture(tester);
    final crop = CropSpec(
      centerX: 0.34,
      centerY: 0.62,
      scale: 1.7,
      rotation: 0.2,
    );

    await _pumpEditor(
      tester,
      bytes,
      mode: ImageEditorMode.edit,
      initialCropSpec: crop,
    );

    final editor = tester.widget<ImageEditorScreen>(
      find.byType(ImageEditorScreen),
    );
    expect(editor.initialCropSpec, crop);
    expect(find.text('Настроить кадр'), findsOneWidget);
    expect(find.text('Сохранить изменения'), findsOneWidget);
  });

  testWidgets(
    'processing is stable and save returns only after work completes',
    (tester) async {
      final bytes = await _readFixture(tester);
      final save = Completer<bool>();
      CropSpec? submittedCrop;

      await tester.pumpWidget(
        ProviderScope(
          child: _localizedApp(
            _EditorRouteHarness(
              originalBytes: bytes,
              onSave: (crop) {
                submittedCrop = crop;
                return save.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open_editor')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('image_editor_rotate')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('image_editor_save')));
      await tester.pump();

      expect(submittedCrop, isNotNull);
      expect(submittedCrop!.rotation, isNot(0));
      expect(find.text('Подготавливаем…'), findsNWidgets(2));
      expect(find.byType(ImageEditorScreen), findsOneWidget);

      save.complete(true);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ImageEditorScreen), findsNothing);
      expect(find.text('saved'), findsOneWidget);
    },
  );

  testWidgets('cancel closes the editor without saving', (tester) async {
    final bytes = await _readFixture(tester);
    var saveCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: _localizedApp(
          _EditorRouteHarness(
            originalBytes: bytes,
            onSave: (_) async {
              saveCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_editor')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('image_editor_cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(saveCalls, 0);
    expect(find.byType(ImageEditorScreen), findsNothing);
    expect(find.text('cancelled'), findsOneWidget);
  });

  for (final testCase in const [
    (name: 'compact 320x640', size: Size(320, 640), scale: 1.0),
    (name: 'standard 390x844', size: Size(390, 844), scale: 1.0),
    (name: 'large 430x932', size: Size(430, 932), scale: 1.0),
    (name: 'text scale 180%', size: Size(390, 844), scale: 1.8),
  ]) {
    testWidgets('image editor remains usable at ${testCase.name}', (
      tester,
    ) async {
      final bytes = await _readFixture(tester);
      await _pumpEditor(
        tester,
        bytes,
        size: testCase.size,
        textScaler: testCase.scale,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('image_crop_gesture')), findsOneWidget);
      expect(find.byKey(const Key('image_editor_save')), findsOneWidget);
      final saveSize = tester.getSize(
        find.byKey(const Key('image_editor_save')),
      );
      expect(saveSize.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('Pearl uses the same editor composition', (tester) async {
    final bytes = await _readFixture(tester);
    await _pumpEditor(tester, bytes, appearance: ResolvedAppAppearance.pearl);

    expect(find.byKey(const Key('image_editor_screen')), findsOneWidget);
    expect(find.byKey(const Key('image_crop_gesture')), findsOneWidget);
    expect(find.text('Сохранить образ'), findsOneWidget);
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

Future<Uint8List> _readFixture(WidgetTester tester) async {
  return (await tester.runAsync(
    () => File('assets/scenes/sunny_friend_static_v1.png').readAsBytes(),
  ))!;
}

Future<void> _pumpEditor(
  WidgetTester tester,
  Uint8List bytes, {
  Size size = const Size(390, 844),
  double textScaler = 1,
  ResolvedAppAppearance appearance = ResolvedAppAppearance.obsidian,
  ImageEditorMode mode = ImageEditorMode.create,
  CropSpec initialCropSpec = CropSpec.centered,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: _localizedApp(
        ImageEditorScreen(
          assetId: 'editor-asset',
          originalBytes: bytes,
          mode: mode,
          initialCropSpec: initialCropSpec,
        ),
        appearance: appearance,
        textScaler: TextScaler.linear(textScaler),
      ),
    ),
  );
  await tester.pump();
}

Widget _localizedApp(
  Widget home, {
  ResolvedAppAppearance appearance = ResolvedAppAppearance.obsidian,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: buildAppTheme(appearance),
    locale: const Locale('ru'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: textScaler, disableAnimations: true),
      child: child!,
    ),
    home: home,
  );
}

final class _EditorRouteHarness extends StatefulWidget {
  const _EditorRouteHarness({
    required this.originalBytes,
    required this.onSave,
  });

  final Uint8List originalBytes;
  final ImageEditorSaveCallback onSave;

  @override
  State<_EditorRouteHarness> createState() => _EditorRouteHarnessState();
}

final class _EditorRouteHarnessState extends State<_EditorRouteHarness> {
  String _result = 'idle';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_result),
          FilledButton(
            key: const Key('open_editor'),
            onPressed: _openEditor,
            child: const Text('open'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          assetId: 'route-editor',
          originalBytes: widget.originalBytes,
          onSave: widget.onSave,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _result = result == true ? 'saved' : 'cancelled');
  }
}
