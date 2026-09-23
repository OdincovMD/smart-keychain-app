@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  for (final appearance in const [
    AppAppearance.obsidian,
    AppAppearance.pearl,
  ]) {
    final name = appearance.name;

    testWidgets('Settings $name 390x844', (tester) async {
      await _pumpSettings(tester, appearance: appearance);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/settings_${name}_390x844.png'),
      );
    });

    testWidgets('Device status sheet $name 390x844', (tester) async {
      await _pumpSettings(tester, appearance: appearance);
      await tester.tap(
        find.byKey(const Key('settings_device_information_row')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/system_device_status_${name}_390x844.png'),
      );
    });

    testWidgets('Brightness sheet $name 390x844', (tester) async {
      await _pumpSettings(tester, appearance: appearance);
      await tester.tap(find.byKey(const Key('settings_brightness_row')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/system_brightness_${name}_390x844.png'),
      );
    });

    testWidgets('Appearance $name 390x844', (tester) async {
      await _pumpSettings(tester, appearance: appearance);
      await tester.tap(find.byKey(const Key('settings_appearance_row')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/appearance_${name}_390x844.png'),
      );
    });
  }
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required AppAppearance appearance,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final scenes = BuiltInSceneRepository();
  final repository = VirtualDeviceRepository(
    engine: VirtualDeviceEngine(
      sceneRepository: scenes,
      initialSceneId: BuiltInSceneRepository.livingEyesId,
      latency: Duration.zero,
    ),
  );
  addTearDown(repository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(scenes),
        deviceRepositoryProvider.overrideWithValue(repository),
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
        initialAppAppearanceProvider.overrideWithValue(appearance),
        failureLoggerProvider.overrideWithValue((code, error, stackTrace) {}),
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
  await _precacheSettingsAssets(tester);

  final connect = find.byKey(const Key('connect_button'));
  await tester.ensureVisible(connect);
  await tester.tap(connect);
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 181));
  await tester.pump();
  await tester.pump();

  final settings = find.byKey(const Key('production_settings_button'));
  await tester.ensureVisible(settings);
  await tester.tap(settings);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _precacheSettingsAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await Future.wait(
      const [
        'assets/chrome_kiss/home_look_original.png',
        'assets/chrome_kiss/appearance_preview_obsidian.png',
        'assets/chrome_kiss/appearance_preview_pearl.png',
        'assets/chrome_kiss/appearance_preview_system.png',
      ].map((path) => precacheImage(AssetImage(path), context)),
    );
  });
  await tester.pump();
}
