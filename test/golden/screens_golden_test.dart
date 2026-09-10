@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadCompanionHomeFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('Companion Home Obsidian 390x844', (tester) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository, appearance: AppAppearance.obsidian);
    await tester.tap(find.byKey(const Key('connect_button')));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/companion_home_obsidian_390x844.png'),
    );
  });

  testWidgets('Companion Home Pearl 390x844', (tester) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository, appearance: AppAppearance.pearl);
    await tester.tap(find.byKey(const Key('connect_button')));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/companion_home_pearl_390x844.png'),
    );
  });

  testWidgets('Living Eyes neutral 240x240', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: Key('living_eyes_golden'),
            child: SizedBox.square(
              dimension: 240,
              child: ProceduralEyesView(
                initialEmotion: EyeEmotion.neutral,
                animate: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('living_eyes_golden')),
      matchesGoldenFile('baselines/living_eyes_neutral_240x240.png'),
    );
  });
}

Future<void> _pumpApp(
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
    await Future.wait(
      const <String>[
        'assets/scenes/eyes_mint_static_v1.png',
        'assets/scenes/sunny_friend_static_v1.png',
        'assets/chrome_kiss/key_ring.png',
        'assets/chrome_kiss/key_ring_opening.png',
        'assets/chrome_kiss/pendant_chrome_shell.png',
        'assets/chrome_kiss/pendant_lens.png',
        'assets/chrome_kiss/lens_inner_rim.png',
        'assets/chrome_kiss/lens_glint_lilac.png',
        'assets/chrome_kiss/lens_glint_white.png',
        'assets/chrome_kiss/lens_glint_orchid.png',
        'assets/chrome_kiss/bow_left.png',
        'assets/chrome_kiss/bow_right.png',
        'assets/chrome_kiss/bow_knot.png',
        'assets/chrome_kiss/charm_ring.png',
      ].map((path) => precacheImage(AssetImage(path), context)),
    );
  });
  await tester.pump();
}

final _sceneRepository = BuiltInSceneRepository();

VirtualDeviceEngine _createEngine() {
  return VirtualDeviceEngine(
    sceneRepository: _sceneRepository,
    initialSceneId: BuiltInSceneRepository.livingEyesId,
    latency: Duration.zero,
  );
}
