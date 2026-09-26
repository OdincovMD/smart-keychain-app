import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/features/device_home/device_home_screen.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/jewel_button.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  testWidgets('/devices displays Russian localization', (tester) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository);

    expect(find.text('Нашли тебя'), findsOneWidget);
    expect(find.text('Подключить'), findsOneWidget);
  });

  testWidgets('connecting disables a repeated tap', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: _createEngine(latency: const Duration(milliseconds: 100)),
    );
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository);

    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pump();

    final button = tester.widget<JewelButton>(
      find.byKey(const Key('connect_button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Подключаем…'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 110));
  });

  testWidgets('ready opens Device Home', (tester) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    expect(find.text('Мои образы'), findsOneWidget);
    expect(find.byKey(const Key('companion_stage')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('companion_stage')),
        matching: find.byKey(const Key('kiss_cut_eye_painter')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.livingEyesId)),
      findsOneWidget,
    );
  });

  testWidgets('second scene appears only after command latency', (
    tester,
  ) async {
    final repository = VirtualDeviceRepository(
      engine: _createEngine(latency: const Duration(milliseconds: 100)),
    );
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    final staticScene = find.byKey(const Key('scene_eyes_mint_static_v1'));
    await tester.scrollUntilVisible(
      staticScene,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    await tester.tap(staticScene);
    await tester.pump();

    final installButton = find.byKey(const Key('install_scene_button'));
    await tester.ensureVisible(installButton);
    await tester.pump();
    await tester.tap(installButton);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.livingEyesId)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.mintEyesId)),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 85));
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.mintEyesId)),
      findsOneWidget,
    );
  });

  testWidgets('brightness slider darkens the virtual screen', (tester) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    final settingsButton = find.byKey(const Key('production_settings_button'));
    await tester.ensureVisible(settingsButton);
    await tester.pump();
    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('settings_brightness_row')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('brightness_slider')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-180, 0),
    );
    await tester.pump(const Duration(milliseconds: 250));

    Navigator.of(tester.element(find.byKey(const Key('brightness_slider'))))
        .pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    Navigator.of(
      tester.element(find.byKey(const Key('production_settings_screen'))),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final overlay = tester.widget<AnimatedContainer>(
      find.byKey(const Key('figma_jewelry_brightness_overlay')),
    );
    final decoration = overlay.decoration! as BoxDecoration;
    expect(decoration.color!.a, greaterThan(0.2));
  });

  testWidgets('debug controls change emotion and request a blink', (
    tester,
  ) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    final settingsButton = find.byKey(const Key('simulator_settings_button'));
    await tester.ensureVisible(settingsButton);
    await tester.pump();
    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('eye_double_blink_button')), findsOneWidget);
    expect(find.byKey(const Key('eye_look_left_button')), findsOneWidget);
    expect(find.byKey(const Key('eye_look_right_button')), findsOneWidget);
    expect(find.byKey(const Key('eye_special_action_button')), findsOneWidget);
    final seed42 = find.byKey(const Key('eye_seed_42'));
    await tester.ensureVisible(seed42);
    await tester.pump();
    await tester.tap(seed42);
    await tester.pump();
    final providerContainer = ProviderScope.containerOf(
      tester.element(find.byType(DeviceHomeScreen)),
    );
    expect(providerContainer.read(eyePreviewControllerProvider).randomSeed, 42);
    final happyEmotion = find.byKey(const Key('eye_emotion_happy'));
    await tester.ensureVisible(happyEmotion);
    await tester.pump();
    await tester.tap(happyEmotion);
    await tester.pump();

    expect(
      providerContainer.read(eyePreviewControllerProvider).emotion,
      EyeEmotion.happy,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('companion_stage')),
        matching: find.byKey(const Key('kiss_cut_eye_painter')),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 180));
    final blinkButton = find.byKey(const Key('eye_blink_button'));
    await tester.ensureVisible(blinkButton);
    await tester.pump();
    await tester.tap(blinkButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final blinkState = providerContainer.read(eyePreviewControllerProvider);
    expect(blinkState.command, EyeDebugCommand.blink);
    expect(blinkState.blinkRevision, 1);

    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disconnect returns to device discovery', (tester) async {
    final repository = VirtualDeviceRepository(engine: _createEngine());
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    final settingsButton = find.byKey(const Key('production_settings_button'));
    await tester.ensureVisible(settingsButton);
    await tester.pump();
    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('settings_device_information_row')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final disconnectButton = find.byKey(const Key('disconnect_button'));
    await tester.ensureVisible(disconnectButton);
    await tester.pump();
    await tester.tap(disconnectButton);
    await tester.pump();
    final confirmButton = find.byKey(const Key('disconnect_confirm_button'));
    await tester.ensureVisible(confirmButton);
    await tester.pump();
    await tester.tap(confirmButton);
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(find.text('Нашли тебя'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  VirtualDeviceRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(_sceneRepository),
        deviceRepositoryProvider.overrideWithValue(repository),
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
      ],
      child: const SmartKeychainApp(),
    ),
  );
  await tester.pump();
}

final _sceneRepository = BuiltInSceneRepository();

VirtualDeviceEngine _createEngine({Duration latency = Duration.zero}) {
  return VirtualDeviceEngine(
    sceneRepository: _sceneRepository,
    initialSceneId: BuiltInSceneRepository.livingEyesId,
    latency: latency,
  );
}

Future<void> _pumpConnectedApp(
  WidgetTester tester,
  VirtualDeviceRepository repository,
) async {
  await _pumpApp(tester, repository);
  await tester.tap(find.byKey(const Key('connect_button')));
  final transitionStep = repository.latency + const Duration(milliseconds: 1);
  await tester.pump(transitionStep);
  await tester.pump(transitionStep);
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 601));
  await tester.pump();
  await tester.pump();
}
