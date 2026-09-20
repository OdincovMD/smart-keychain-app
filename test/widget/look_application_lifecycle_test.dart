import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/device/device_capabilities.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/features/user_content/look_details_sheet.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets('applied waits for command and matching device snapshot', (
    tester,
  ) async {
    final device = _ScriptedDeviceRepository();
    await _pumpDetails(tester, device: device);

    final apply = find.byKey(const Key('set_current_builtin-eyes-mint'));
    await tester.tap(apply);
    await tester.tap(apply);
    await tester.pump();

    expect(device.setSceneCalls, 1);
    expect(find.byKey(const Key('look_applying_state')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    device.completeCommand();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('look_applying_state')), findsOneWidget);
    expect(find.byKey(const Key('look_applied_state')), findsNothing);

    device.emitScene(_targetScene.id);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('look_applied_state')), findsOneWidget);
    expect(find.text(_targetScene.name), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure can retry repeatedly and later succeed', (tester) async {
    final device = _ScriptedDeviceRepository();
    await _pumpDetails(tester, device: device);

    await tester.tap(find.byKey(const Key('set_current_builtin-eyes-mint')));
    await tester.pump();
    device.failCommand();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('look_failed_state')), findsOneWidget);
    expect(find.text('Образ не изменён'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry_apply_look')));
    await tester.pump();
    expect(device.setSceneCalls, 2);
    device.failCommand();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('look_failed_state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry_apply_look')));
    await tester.pump();
    device.emitScene(_targetScene.id);
    device.completeCommand();
    await tester.pump();
    await tester.pump();

    expect(device.setSceneCalls, 3);
    expect(find.byKey(const Key('look_applied_state')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('already active look cannot issue another command', (
    tester,
  ) async {
    final device = _ScriptedDeviceRepository(activeSceneId: _targetScene.id);
    await _pumpDetails(tester, device: device);

    expect(find.text('Уже надет'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('set_current_builtin-eyes-mint')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(device.setSceneCalls, 0);
    expect(find.byKey(const Key('look_details_state_ready')), findsOneWidget);
  });

  testWidgets('disposing the sheet during a command is safe', (tester) async {
    final device = _ScriptedDeviceRepository();
    await _pumpDetails(tester, device: device);
    await tester.tap(find.byKey(const Key('set_current_builtin-eyes-mint')));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    device.emitScene(_targetScene.id);
    device.completeCommand();
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
    testWidgets(
      'lifecycle fits ${size.width.toInt()}x${size.height.toInt()} at 180% text',
      (tester) async {
        final device = _ScriptedDeviceRepository();
        await _pumpDetails(
          tester,
          device: device,
          size: size,
          textScaler: const TextScaler.linear(1.8),
          disableAnimations: true,
        );
        await tester.tap(
          find.byKey(const Key('set_current_builtin-eyes-mint')),
        );
        await tester.pump();

        expect(find.byKey(const Key('look_applying_state')), findsOneWidget);
        expect(
          find.bySemanticsLabel('Образ передаётся на брелок'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

const _targetScene = Scene(
  id: 'builtin-eyes-mint',
  name: 'Мятный взгляд',
  source: SceneSource.builtIn,
  tags: {'eyes', 'animated'},
  content: ProceduralEyesContent(defaultEmotion: EyeEmotion.neutral),
);

Future<void> _pumpDetails(
  WidgetTester tester, {
  required _ScriptedDeviceRepository device,
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await device.dispose();
    tester.view.reset();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(device),
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(
            initialSettings: AppSettings(
              activeSceneId: device.snapshot.activeSceneId,
              brightness: AppSettings.defaultBrightness,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LookDetailsSheet(scene: _targetScene),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

final class _ScriptedDeviceRepository implements DeviceRepository {
  _ScriptedDeviceRepository({String activeSceneId = 'builtin-living-eyes'})
    : _snapshot = _snapshotFor(activeSceneId);

  final StreamController<DeviceSnapshot> _snapshots =
      StreamController<DeviceSnapshot>.broadcast();
  DeviceSnapshot _snapshot;
  Completer<void>? _command;
  int setSceneCalls = 0;

  DeviceSnapshot get snapshot => _snapshot;

  void completeCommand() {
    final command = _command;
    if (command != null && !command.isCompleted) command.complete();
  }

  void failCommand() {
    final command = _command;
    if (command != null && !command.isCompleted) {
      command.completeError(StateError('scripted device failure'));
    }
  }

  void emitScene(String sceneId) {
    _snapshot = _snapshot.copyWith(activeSceneId: sceneId);
    _snapshots.add(_snapshot);
  }

  @override
  Future<List<DeviceInfo>> discoverDevices() async => const [];

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() =>
      Stream.value(DeviceConnectionStatus.ready);

  @override
  Stream<DeviceSnapshot> watchDeviceState() async* {
    yield _snapshot;
    yield* _snapshots.stream;
  }

  @override
  Future<void> setScene(String sceneId) {
    setSceneCalls++;
    _command = Completer<void>();
    return _command!.future;
  }

  @override
  Future<void> setBrightness(double value) async {}

  @override
  Future<void> dispose() => _snapshots.close();
}

const _profile = DisplayProfile(
  width: 240,
  height: 240,
  shape: DisplayShape.circle,
  aspectRatio: 1,
);

const _capabilities = DeviceCapabilities(
  supportsBrightness: true,
  reportsBattery: true,
  supportsStaticScenes: true,
  supportsAnimatedScenes: true,
);

DeviceSnapshot _snapshotFor(String sceneId) => DeviceSnapshot(
  deviceId: 'scripted-keychain',
  connectionStatus: DeviceConnectionStatus.ready,
  batteryPercent: 82,
  brightness: AppSettings.defaultBrightness,
  activeSceneId: sceneId,
  displayProfile: _profile,
  capabilities: _capabilities,
);
