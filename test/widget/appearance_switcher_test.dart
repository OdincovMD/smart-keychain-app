import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/features/device_home/device_home_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  testWidgets('simulator sheet switches and persists Pearl appearance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scenes = BuiltInSceneRepository();
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      ),
    );
    final settings = FakeAppSettingsRepository();
    addTearDown(device.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sceneRepositoryProvider.overrideWithValue(scenes),
          deviceRepositoryProvider.overrideWithValue(device),
          appSettingsRepositoryProvider.overrideWithValue(settings),
          initialAppAppearanceProvider.overrideWithValue(
            AppAppearance.obsidian,
          ),
          failureLoggerProvider.overrideWithValue((code, error, stackTrace) {}),
        ],
        child: const SmartKeychainApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('connect_button')));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();
    await tester.pump();

    final settingsButton = find.byKey(const Key('simulator_settings_button'));
    await tester.ensureVisible(settingsButton);
    await tester.pump();
    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('appearance_pearl')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DeviceHomeScreen)),
    );
    final colors = Theme.of(tester.element(find.byType(DeviceHomeScreen)))
        .extension<ChromeKissColors>();

    expect(container.read(appAppearanceProvider), AppAppearance.pearl);
    expect(settings.settings.appearance, AppAppearance.pearl);
    expect(colors?.canvas, ChromeKissColors.pearl.canvas);
  });
}
