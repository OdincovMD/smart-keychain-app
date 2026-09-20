import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
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

  testWidgets(
    'Home settings trigger opens production Settings and back preserves session',
    (tester) async {
      final rig = await _pumpConnectedApp(tester);
      await _openSettings(tester);

      expect(
        find.byKey(const Key('production_settings_screen')),
        findsOneWidget,
      );
      expect(find.text('Настройки симулятора'), findsNothing);
      expect(find.text('Задержка'), findsNothing);

      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DeviceHomeScreen), findsOneWidget);
      expect(find.byKey(const Key('companion_stage')), findsOneWidget);
      expect(
        rig.engine.snapshot.connectionStatus,
        DeviceConnectionStatus.ready,
      );
    },
  );

  testWidgets('Settings renders confirmed DeviceSnapshot values', (
    tester,
  ) async {
    await _pumpConnectedApp(tester);
    await _openSettings(tester);

    expect(find.text(VirtualDeviceEngine.deviceId), findsOneWidget);
    expect(find.text('На связи · 78%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_device_information_row')));
    await tester.pump();
    expect(find.byKey(const Key('device_information_sheet')), findsOneWidget);
    expect(find.text('Круглый экран 240×240'), findsOneWidget);
  });

  testWidgets('brightness uses DeviceController and settings persistence', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(tester);
    await _openSettings(tester);
    await tester.tap(find.byKey(const Key('settings_brightness_row')));
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-110, 0),
    );
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(rig.engine.snapshot.brightness, lessThan(0.8));
    expect(
      rig.settings.settings.brightness,
      moreOrLessEquals(rig.engine.snapshot.brightness),
    );
  });

  testWidgets('brightness failure restores the confirmed device value', (
    tester,
  ) async {
    final scenes = BuiltInSceneRepository();
    final engine = VirtualDeviceEngine(
      sceneRepository: scenes,
      initialSceneId: BuiltInSceneRepository.livingEyesId,
      latency: Duration.zero,
    );
    final live = VirtualDeviceRepository(engine: engine);
    final failing = _FailingBrightnessRepository(live);
    final rig = await _pumpConnectedApp(
      tester,
      scenes: scenes,
      engine: engine,
      repository: failing,
    );
    await _openSettings(tester);
    await tester.tap(find.byKey(const Key('settings_brightness_row')));
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-120, 0),
    );
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(
      find.byKey(const Key('settings_brightness_failure')),
      findsOneWidget,
    );
    expect(
      tester.widget<Slider>(find.byKey(const Key('brightness_slider'))).value,
      0.8,
    );
    expect(rig.engine.snapshot.brightness, 0.8);
    expect(rig.settings.settings.brightness, 0.8);
  });

  testWidgets('Appearance exposes three options and confirmed semantics', (
    tester,
  ) async {
    await _pumpConnectedApp(tester, appearance: AppAppearance.obsidian);
    await _openAppearance(tester);

    for (final appearance in AppAppearance.values) {
      expect(
        find.byKey(Key('appearance_option_${appearance.name}')),
        findsOneWidget,
      );
    }
    final selected = tester.getSemantics(
      find.byKey(const Key('appearance_option_obsidian')),
    );
    expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(selected.flagsCollection.isButton, isTrue);
  });

  testWidgets(
    'Appearance persists, updates Settings, and keeps the sheet open',
    (tester) async {
      final rig = await _pumpConnectedApp(
        tester,
        appearance: AppAppearance.obsidian,
      );
      await _openAppearance(tester);

      await tester.tap(find.byKey(const Key('appearance_option_pearl')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(rig.settings.settings.appearance, AppAppearance.pearl);
      expect(find.byKey(const Key('appearance_screen')), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const Key('appearance_option_pearl')))
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );

      await tester.tap(find.byKey(const Key('appearance_done_button')));
      await tester.pump();
      expect(find.text('Pearl'), findsOneWidget);
    },
  );

  testWidgets('Appearance failure stays unconfirmed and supports retry', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(
      tester,
      appearance: AppAppearance.obsidian,
    );
    rig.settings.failure = StateError('disk unavailable');
    await _openAppearance(tester);

    await tester.tap(find.byKey(const Key('appearance_option_pearl')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('appearance_save_failure')), findsOneWidget);
    expect(rig.settings.settings.appearance, AppAppearance.system);
    expect(
      tester
          .getSemantics(find.byKey(const Key('appearance_option_obsidian')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );

    rig.settings.failure = null;
    await tester.tap(find.byKey(const Key('appearance_retry_button')));
    await tester.pump();
    await tester.pump();

    expect(rig.settings.settings.appearance, AppAppearance.pearl);
    expect(find.byKey(const Key('appearance_save_failure')), findsNothing);
  });

  testWidgets('disconnect confirmation uses the existing discovery flow', (
    tester,
  ) async {
    await _pumpConnectedApp(tester);
    await _openSettings(tester);
    await tester.tap(find.byKey(const Key('settings_device_information_row')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('disconnect_button')));
    await tester.pump();
    expect(find.byKey(const Key('disconnect_confirmation')), findsOneWidget);

    await tester.tap(find.byKey(const Key('disconnect_confirm_button')));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(find.text('Нашли тебя'), findsOneWidget);
  });

  for (final testCase in <({String name, Size size, double scale})>[
    (name: '360x800', size: const Size(360, 800), scale: 1),
    (name: '390x844', size: const Size(390, 844), scale: 1),
    (name: '412x915', size: const Size(412, 915), scale: 1),
    (name: '360x800 text 1.8', size: const Size(360, 800), scale: 1.8),
  ]) {
    testWidgets('Settings and Appearance fit ${testCase.name}', (tester) async {
      await _pumpConnectedApp(
        tester,
        size: testCase.size,
        textScale: testCase.scale,
        disableAnimations: true,
      );
      await _openSettings(tester);
      final deviceRow = find.byKey(
        const Key('settings_device_information_row'),
      );
      await tester.ensureVisible(deviceRow);
      await tester.pump();
      expect(
        tester.getRect(deviceRow).bottom,
        lessThanOrEqualTo(testCase.size.height),
      );
      expect(tester.getSize(deviceRow).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);

      await _openAppearance(tester);
      await tester.ensureVisible(
        find.byKey(const Key('appearance_done_button')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

Future<_SettingsRig> _pumpConnectedApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = true,
  AppAppearance appearance = AppAppearance.system,
  BuiltInSceneRepository? scenes,
  VirtualDeviceEngine? engine,
  DeviceRepository? repository,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final sceneRepository = scenes ?? BuiltInSceneRepository();
  final deviceEngine =
      engine ??
      VirtualDeviceEngine(
        sceneRepository: sceneRepository,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      );
  final deviceRepository =
      repository ?? VirtualDeviceRepository(engine: deviceEngine);
  final settings = FakeAppSettingsRepository();
  addTearDown(deviceRepository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(sceneRepository),
        deviceRepositoryProvider.overrideWithValue(deviceRepository),
        appSettingsRepositoryProvider.overrideWithValue(settings),
        initialAppAppearanceProvider.overrideWithValue(appearance),
        failureLoggerProvider.overrideWithValue((code, error, stackTrace) {}),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
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
  return _SettingsRig(engine: deviceEngine, settings: settings);
}

Future<void> _openSettings(WidgetTester tester) async {
  final button = find.byKey(const Key('production_settings_button'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openAppearance(WidgetTester tester) async {
  if (find.byKey(const Key('production_settings_screen')).evaluate().isEmpty) {
    await _openSettings(tester);
  }
  final row = find.byKey(const Key('settings_appearance_row'));
  await tester.ensureVisible(row);
  await tester.pump();
  await tester.tap(row);
  await tester.pump();
}

final class _SettingsRig {
  const _SettingsRig({required this.engine, required this.settings});

  final VirtualDeviceEngine engine;
  final FakeAppSettingsRepository settings;
}

final class _FailingBrightnessRepository implements DeviceRepository {
  const _FailingBrightnessRepository(this._delegate);

  final VirtualDeviceRepository _delegate;

  @override
  Future<void> connect(String deviceId) => _delegate.connect(deviceId);

  @override
  Future<void> disconnect() => _delegate.disconnect();

  @override
  Future<List<DeviceInfo>> discoverDevices() => _delegate.discoverDevices();

  @override
  Future<void> dispose() => _delegate.dispose();

  @override
  Future<void> setBrightness(double value) =>
      Future<void>.error(StateError('brightness failed'));

  @override
  Future<void> setScene(String sceneId) => _delegate.setScene(sceneId);

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() =>
      _delegate.watchConnectionState();

  @override
  Stream<DeviceSnapshot> watchDeviceState() => _delegate.watchDeviceState();
}
