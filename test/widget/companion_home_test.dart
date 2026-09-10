import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/features/device_home/widgets/keychain_preview.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  for (final testCase in <({String name, Size size, double textScale})>[
    (name: 'narrow', size: const Size(320, 640), textScale: 1),
    (name: 'reference', size: const Size(390, 844), textScale: 1),
    (name: 'tall', size: const Size(430, 932), textScale: 1),
    (name: 'large text', size: const Size(320, 640), textScale: 1.8),
  ]) {
    testWidgets('Companion Home fits ${testCase.name}', (tester) async {
      await _pumpConnectedHome(
        tester,
        size: testCase.size,
        textScale: testCase.textScale,
      );

      expect(find.byKey(const Key('companion_stage')), findsOneWidget);
      expect(find.byKey(const Key('companion_presence')), findsOneWidget);
      expect(find.byKey(const Key('install_scene_button')), findsOneWidget);
      expect(find.byKey(const Key('wardrobe_rail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('primary hierarchy precedes wardrobe and utility controls', (
    tester,
  ) async {
    await _pumpConnectedHome(tester);

    final stage = tester.getRect(find.byKey(const Key('companion_stage')));
    final presence = tester.getRect(
      find.byKey(const Key('companion_presence')),
    );
    final action = tester.getRect(
      find.byKey(const Key('install_scene_button')),
    );
    final wardrobe = tester.getRect(find.byKey(const Key('wardrobe_rail')));

    expect(stage.bottom, lessThan(presence.top));
    expect(presence.bottom, lessThan(action.top));
    expect(action.bottom, lessThan(wardrobe.top));
    expect(
      tester.getSize(find.byKey(const Key('install_scene_button'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.byType(KeychainPreview), findsNothing);
  });

  testWidgets('wardrobe reveals a partial next look at reference width', (
    tester,
  ) async {
    await _pumpConnectedHome(tester);

    final viewport = tester.getRect(find.byKey(const Key('wardrobe_list')));
    final first = tester.getRect(find.byKey(const Key('scene_living_eyes_v1')));
    final second = tester.getRect(
      find.byKey(const Key('scene_eyes_mint_static_v1')),
    );
    final third = tester.getRect(
      find.byKey(const Key('scene_sunny_friend_static_v1')),
    );

    expect(first.right, lessThan(viewport.right));
    expect(second.right, lessThan(viewport.right));
    expect(third.left, lessThan(viewport.right));
    expect(third.right, greaterThan(viewport.right));
  });

  testWidgets('stage and jewel expose semantics with stable press layout', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpConnectedHome(tester);

    expect(find.bySemanticsLabel('Виртуальный экран брелока'), findsOneWidget);
    expect(find.bySemanticsLabel('Сменить образ'), findsOneWidget);

    final button = find.byKey(const Key('install_scene_button'));
    final before = tester.getRect(button);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(button), before);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    semantics.dispose();
  });

  testWidgets('brightness is a compact utility sheet and stays functional', (
    tester,
  ) async {
    await _pumpConnectedHome(tester);

    expect(find.byKey(const Key('brightness_slider')), findsNothing);
    final button = find.byKey(const Key('brightness_settings_button'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('brightness_slider')), findsOneWidget);
  });

  testWidgets('full wardrobe opens look details and installs a look', (
    tester,
  ) async {
    await _pumpConnectedHome(tester);

    final allButton = find.byKey(const Key('open_all_looks_button'));
    await tester.ensureVisible(allButton);
    await tester.pump();
    await tester.tap(allButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('wardrobe_scroll')), findsOneWidget);

    const mintSceneId = BuiltInSceneRepository.mintEyesId;
    final mintTile = find.byKey(const Key('my_content_scene_$mintSceneId'));
    await tester.ensureVisible(mintTile);
    await tester.pump();
    await tester.tap(mintTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('look_details_preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('set_current_$mintSceneId')));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(find.text('Надето'), findsOneWidget);
  });
}

Future<void> _pumpConnectedHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
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
  addTearDown(device.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(scenes),
        deviceRepositoryProvider.overrideWithValue(device),
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: const SmartKeychainApp(),
        ),
      ),
    ),
  );
  await tester.pump();
  final connectButton = find.byKey(const Key('connect_button'));
  await tester.ensureVisible(connectButton);
  await tester.pump();
  await tester.tap(connectButton);
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 181));
  await tester.pump();
  await tester.pump();
}
