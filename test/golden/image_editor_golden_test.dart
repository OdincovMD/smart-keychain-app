@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_screen.dart';
import 'package:smart_keychain_app/features/image_import/photo_import_error_sheet.dart';
import 'package:smart_keychain_app/features/shared/chrome_kiss_material_sheet.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  late Uint8List imageBytes;
  late Uint8List figmaImageBytes;
  setUpAll(() async {
    imageBytes = await File('assets/scenes/sunny_friend_static_v1.png')
        .readAsBytes();
    figmaImageBytes = await File('assets/chrome_kiss/wardrobe_user_photo.jpeg')
        .readAsBytes();
  });

  testWidgets('Create Look crop matches Figma 102:287', (tester) async {
    await _pumpEditor(
      tester,
      figmaImageBytes,
      appearance: ResolvedAppAppearance.pearl,
      size: const Size(393, 852),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_crop_figma_102_287.png'),
    );
  });

  testWidgets('Create Look crop matches Obsidian Figma 226:1493', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      figmaImageBytes,
      appearance: ResolvedAppAppearance.obsidian,
      size: const Size(393, 852),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_crop_obsidian_226_1493.png'),
    );
  });

  testWidgets('Create Look beauty matches Figma 114:290', (tester) async {
    await _pumpEditor(
      tester,
      figmaImageBytes,
      appearance: ResolvedAppAppearance.pearl,
      size: const Size(393, 852),
    );
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_beauty_figma_114_290.png'),
    );
  });

  testWidgets('Create Look beauty matches Obsidian Figma 226:1552', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      figmaImageBytes,
      appearance: ResolvedAppAppearance.obsidian,
      size: const Size(393, 852),
    );
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/create_look_beauty_obsidian_226_1552.png'),
    );
  });

  testWidgets('Image editor existing look Obsidian', (tester) async {
    await _pumpEditor(
      tester,
      imageBytes,
      appearance: ResolvedAppAppearance.obsidian,
      mode: ImageEditorMode.edit,
      initialCropSpec: CropSpec(
        centerX: 0.42,
        centerY: 0.58,
        scale: 1.28,
        rotation: 0.12,
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/image_editor_existing_look_obsidian.png'),
    );
  });

  testWidgets('Image editor processing Obsidian', (tester) async {
    final save = Completer<bool>();
    await _pumpEditor(
      tester,
      imageBytes,
      appearance: ResolvedAppAppearance.obsidian,
      onSave: (_) => save.future,
    );

    await tester.ensureVisible(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('image_editor_save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image_editor_save')));
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/image_editor_processing_obsidian.png'),
    );
  });

  testWidgets('Photo Import Error Obsidian 390x844', (tester) async {
    await _pumpEditor(
      tester,
      figmaImageBytes,
      appearance: ResolvedAppAppearance.obsidian,
    );
    await _openPhotoImportError(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/photo_import_error_obsidian_390x844.png'),
    );
  });

  testWidgets('Photo Import Error Pearl 390x844', (tester) async {
    await _pumpEditor(
      tester,
      figmaImageBytes,
      appearance: ResolvedAppAppearance.pearl,
    );
    await _openPhotoImportError(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/photo_import_error_pearl_390x844.png'),
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
        'Create Look editor ${appearance.name} fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await _pumpEditor(
            tester,
            figmaImageBytes,
            appearance: appearance,
            size: size,
          );
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(
            find.byKey(const Key('image_editor_next')),
          );
          await tester.tap(find.byKey(const Key('image_editor_next')));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('image_editor_save')), findsOneWidget);
        },
      );
    }
  }
}

Future<void> _openPhotoImportError(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('image_editor_next')));
  await tester.pump();
  final context = tester.element(find.byType(ImageEditorScreen));
  unawaited(
    showChromeKissMaterialSheet<PhotoImportErrorAction>(
      context: context,
      builder: (context) => const PhotoImportErrorSheet(
        failureLabel:
            'Файл повреждён или этот формат изображения не поддерживается.',
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpEditor(
  WidgetTester tester,
  Uint8List imageBytes, {
  required ResolvedAppAppearance appearance,
  ImageEditorMode mode = ImageEditorMode.create,
  CropSpec initialCropSpec = CropSpec.centered,
  ImageEditorSaveCallback? onSave,
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: ImageEditorScreen(
          assetId: 'golden-image',
          originalBytes: imageBytes,
          initialCropSpec: initialCropSpec,
          mode: mode,
          onSave: onSave,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(ImageEditorScreen));
    await precacheImage(MemoryImage(imageBytes), context);
  });
  await tester.pump();
}
