@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/companion_stage.dart';
import 'package:smart_keychain_app/features/device_home/widgets/jewel_button.dart';
import 'package:smart_keychain_app/features/device_home/widgets/status_glyph.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets('Companion Home Obsidian material pass', (tester) async {
    _setSurface(tester, const Size(390, 844));
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpConnectedHome(
      tester,
      repository,
      appearance: AppAppearance.obsidian,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/companion_home_obsidian_kiss_cut_v21.png'),
    );
  });

  testWidgets('Companion Home Pearl material pass', (tester) async {
    _setSurface(tester, const Size(390, 844));
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpConnectedHome(
      tester,
      repository,
      appearance: AppAppearance.pearl,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/companion_home_pearl_kiss_cut_v21.png'),
    );
  });

  testWidgets('Companion Home Obsidian material close-up', (tester) async {
    _setSurface(tester, const Size(390, 640));
    final scenes = BuiltInSceneRepository();
    final activeScene = (await scenes.getById(
      BuiltInSceneRepository.livingEyesId,
    ))!;
    final engine = VirtualDeviceEngine(
      sceneRepository: scenes,
      initialSceneId: activeScene.id,
      latency: Duration.zero,
    );
    addTearDown(engine.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: _MaterialCloseup(activeScene: activeScene, engine: engine),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'baselines/companion_home_obsidian_material_closeup.png',
      ),
    );
  });
}

final class _MaterialCloseup extends StatelessWidget {
  const _MaterialCloseup({required this.activeScene, required this.engine});

  final Scene activeScene;
  final VirtualDeviceEngine engine;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final text = context.chromeKissText;
    return Scaffold(
      body: ColoredBox(
        color: colors.canvas,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ТВОЙ КОМПАНЬОН',
                            style: text.status.copyWith(letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Живой взгляд',
                            style: text.title.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const StatusGlyph(
                      value: 'На связи',
                      semanticLabel: 'На связи',
                      tone: StatusGlyphTone.connected,
                    ),
                    const SizedBox(width: 7),
                    const StatusGlyph(
                      value: '78%',
                      semanticLabel: 'Заряд 78%',
                      tone: StatusGlyphTone.battery,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: CompanionStage(
                    scene: activeScene,
                    displayProfile: engine.snapshot.displayProfile,
                    snapshot: engine.snapshot,
                    diameter: 300,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'СПОКОЙНАЯ',
                  textAlign: TextAlign.center,
                  style: text.title.copyWith(
                    color: colors.textSecondary,
                    fontSize: 10.5,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Сегодня просто рядом.',
                  textAlign: TextAlign.center,
                  style: text.body.copyWith(
                    color: colors.textSecondary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 18),
                JewelButton(label: 'Сменить образ', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pumpConnectedHome(
  WidgetTester tester,
  VirtualDeviceRepository repository, {
  required AppAppearance appearance,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(_sceneRepository),
        deviceRepositoryProvider.overrideWithValue(repository),
        initialAppAppearanceProvider.overrideWithValue(appearance),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const SmartKeychainApp(),
        ),
      ),
    ),
  );
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
    ]);
  });
  await tester.pump();
  await tester.tap(find.byKey(const Key('connect_button')));
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

final _sceneRepository = BuiltInSceneRepository();

VirtualDeviceEngine _createEngine() {
  return VirtualDeviceEngine(
    sceneRepository: _sceneRepository,
    initialSceneId: BuiltInSceneRepository.livingEyesId,
    latency: Duration.zero,
  );
}
