import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/wardrobe_rail.dart';
import 'package:smart_keychain_app/features/settings/appearance_screen.dart';
import 'package:smart_keychain_app/features/shared/chrome_kiss_material_sheet.dart';
import 'package:smart_keychain_app/features/user_content/look_application_controller.dart';
import 'package:smart_keychain_app/features/user_content/look_application_view.dart';
import 'package:smart_keychain_app/features/user_content/look_delete_confirmation_sheet.dart';
import 'package:smart_keychain_app/features/user_content/look_details_ready.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  const sizes = [Size(360, 800), Size(390, 844), Size(412, 915)];
  const lifecycleStates = [
    LookApplicationStatus.applying,
    LookApplicationStatus.applied,
    LookApplicationStatus.failed,
  ];

  for (final appearance in ResolvedAppAppearance.values) {
    for (final size in sizes) {
      final caseName =
          '${appearance.name} ${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('details fits $caseName at 180% reduced motion', (
        tester,
      ) async {
        await _pumpSurface(
          tester,
          appearance: appearance,
          size: size,
          child: ChromeKissMaterialSheet(
            child: LookDetailsReady(
              scene: _staticScene,
              isActive: false,
              onClose: _noop,
              onApply: _noop,
              onEdit: _noop,
              onDelete: _noop,
            ),
          ),
        );

        expect(find.byKey(const Key('look_details_preview')), findsOneWidget);
        expect(
          find.byKey(const Key('look_details_character_reaction_lens')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      for (final status in lifecycleStates) {
        testWidgets('${status.name} fits $caseName at 180% reduced motion', (
          tester,
        ) async {
          await _pumpSurface(
            tester,
            appearance: appearance,
            size: size,
            child: ChromeKissMaterialSheet(
              child: LookApplicationView(
                scene: _staticScene,
                status: status,
                onRetry: _noop,
                onReturn: _noop,
              ),
            ),
          );

          expect(find.byKey(const Key('look_details_preview')), findsOneWidget);
          expect(
            find.byKey(const Key('look_application_character_reaction_lens')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('delete fits $caseName at 180% reduced motion', (
        tester,
      ) async {
        await _pumpSurface(
          tester,
          appearance: appearance,
          size: size,
          child: const LookDeleteConfirmationSheet(scene: _userScene),
        );

        expect(find.byKey(const Key('delete_look_preview')), findsOneWidget);
        expect(
          find.byKey(const Key('delete_character_reaction_lens')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('compact wardrobe fits $caseName with real previews', (
        tester,
      ) async {
        final scenes = await BuiltInSceneRepository().getAll();
        await _pumpSurface(
          tester,
          appearance: appearance,
          size: size,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: WardrobeRail(
              scenes: scenes,
              selectedSceneId: BuiltInSceneRepository.livingEyesId,
              activeSceneId: BuiltInSceneRepository.livingEyesId,
              enabled: true,
              isAddingImage: false,
              onSceneSelected: _ignoreScene,
              onOpenAll: _noop,
              onAddImage: _noop,
              compact: true,
            ),
          ),
        );

        expect(find.text('Солнечный друг'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('appearance fits $caseName at 180% reduced motion', (
        tester,
      ) async {
        await _pumpSurface(
          tester,
          appearance: appearance,
          size: size,
          child: const ChromeKissMaterialSheet(child: AppearanceScreen()),
        );

        for (final option in AppAppearance.values) {
          expect(
            find.byKey(Key('appearance_preview_${option.name}')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

const _staticScene = Scene(
  id: 'responsive-static',
  name: 'Мятный взгляд',
  source: SceneSource.builtIn,
  content: StaticImageContent(
    previewAssetPath: 'assets/scenes/eyes_mint_static_v1.png',
  ),
);

const _userScene = Scene(
  id: 'user-image:responsive',
  name: 'Вечерний блеск',
  source: SceneSource.userGenerated,
  content: UserImageContent(
    assetId: 'responsive',
    previewStorageKey: 'responsive-preview',
  ),
);

void _noop() {}
void _ignoreScene(String sceneId) {}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required ResolvedAppAppearance appearance,
  required Size size,
  required Widget child,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  final appAppearance = switch (appearance) {
    ResolvedAppAppearance.obsidian => AppAppearance.obsidian,
    ResolvedAppAppearance.pearl => AppAppearance.pearl,
  };
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
        initialAppAppearanceProvider.overrideWithValue(appAppearance),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, builtChild) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
            disableAnimations: true,
          ),
          child: builtChild!,
        ),
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
