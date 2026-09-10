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
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  late Uint8List imageBytes;
  setUpAll(() async {
    imageBytes = await File('assets/scenes/sunny_friend_static_v1.png')
        .readAsBytes();
  });

  testWidgets('Image editor create Obsidian', (tester) async {
    await _pumpEditor(
      tester,
      imageBytes,
      appearance: ResolvedAppAppearance.obsidian,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/image_editor_obsidian_390x844.png'),
    );
  });

  testWidgets('Image editor create Pearl', (tester) async {
    await _pumpEditor(
      tester,
      imageBytes,
      appearance: ResolvedAppAppearance.pearl,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/image_editor_pearl_390x844.png'),
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

    await tester.tap(find.byKey(const Key('image_editor_save')));
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/image_editor_processing_obsidian.png'),
    );
  });
}

Future<void> _pumpEditor(
  WidgetTester tester,
  Uint8List imageBytes, {
  required ResolvedAppAppearance appearance,
  ImageEditorMode mode = ImageEditorMode.create,
  CropSpec initialCropSpec = CropSpec.centered,
  ImageEditorSaveCallback? onSave,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
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
