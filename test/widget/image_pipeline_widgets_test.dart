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
  setUpAll(loadCompanionHomeFonts);

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
    expect(find.text('Круглая обрезка'), findsOneWidget);
    expect(find.text('Дальше'), findsOneWidget);
    expect(find.byKey(const Key('image_crop_gesture')), findsOneWidget);
    await tester.tap(find.byKey(const Key('image_editor_rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_reset')));
    await tester.pump();

    expect(find.byKey(const Key('image_editor_next')), findsOneWidget);
    expect(find.byKey(const Key('image_editor_cancel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    expect(find.text('Свет и цвет'), findsOneWidget);
    expect(find.byKey(const Key('image_editor_save')), findsOneWidget);
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

  testWidgets('beauty stage presets, tuning, reset, and back stay functional', (
    tester,
  ) async {
    final bytes = await _readFixture(tester);
    await _pumpEditor(
      tester,
      bytes,
      size: const Size(393, 852),
      appearance: ResolvedAppAppearance.pearl,
    );

    await tester.tap(find.byKey(const Key('image_editor_rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();

    expect(find.text('Свет и цвет'), findsOneWidget);
    await tester.tap(find.byKey(const Key('beauty_preset_pearlDoll')));
    await tester.pump();
    expect(find.text('PEARL DOLL · 48%'), findsOneWidget);

    final glowTrack = tester.getRect(
      find.byKey(const Key('beauty_glow_slider')),
    );
    await tester.tapAt(Offset(glowTrack.left + 20, glowTrack.bottom - 5));
    await tester.pump();
    expect(find.text('48%'), findsNothing);

    await tester.tap(find.byKey(const Key('beauty_reset')));
    await tester.pump();
    expect(find.text('CANDY GLOSS · 72%'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const Key('image_editor_cancel'))),
      const Size(44, 44),
    );
    expect(
      tester.getSize(find.byKey(const Key('image_editor_save'))).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(const Key('image_editor_cancel')));
    await tester.pump();
    expect(find.text('Круглая обрезка'), findsOneWidget);
    expect(find.byType(ImageEditorScreen), findsOneWidget);
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
      await _dragUntilBuilt(
        tester,
        target: find.byKey(const Key('image_editor_rotate')),
        scrollable: find.byKey(const Key('image_editor_crop_scroll')),
      );
      await tester.tap(find.byKey(const Key('image_editor_rotate')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('image_editor_next')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('image_editor_next')));
      await tester.pump();
      await _dragUntilBuilt(
        tester,
        target: find.byKey(const Key('image_editor_save')),
        scrollable: find.byKey(const Key('image_editor_beauty_scroll')),
      );
      await tester.tap(find.byKey(const Key('image_editor_save')));
      await tester.pump();

      expect(submittedCrop, isNotNull);
      expect(submittedCrop!.rotation, isNot(0));
      expect(find.text('Подготавливаем…'), findsOneWidget);
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
    (
      name: 'compact 320x640',
      size: Size(320, 640),
      scale: 1.0,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: 'standard 390x844',
      size: Size(390, 844),
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
    testWidgets('image editor remains usable at ${testCase.name}', (
      tester,
    ) async {
      final bytes = await _readFixture(tester);
      await _pumpEditor(
        tester,
        bytes,
        size: testCase.size,
        textScaler: testCase.scale,
        viewPadding: EdgeInsets.only(
          top: testCase.top,
          bottom: testCase.bottom,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('image_crop_gesture')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('image_editor_next')),
        220,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('image_editor_next')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('image_editor_save')),
        220,
      );
      await tester.pump();
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
    await tester.ensureVisible(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();
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

Future<void> _dragUntilBuilt(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollable,
}) async {
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -360));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
}

Future<void> _pumpEditor(
  WidgetTester tester,
  Uint8List bytes, {
  Size size = const Size(390, 844),
  double textScaler = 1,
  EdgeInsets viewPadding = EdgeInsets.zero,
  ResolvedAppAppearance appearance = ResolvedAppAppearance.obsidian,
  ImageEditorMode mode = ImageEditorMode.create,
  CropSpec initialCropSpec = CropSpec.centered,
}) async {
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
