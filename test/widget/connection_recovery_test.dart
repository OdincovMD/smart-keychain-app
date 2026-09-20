import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/features/device_home/device_home_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  testWidgets('intentional Settings disconnect returns to Discovery', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(tester);

    await _openSettings(tester);
    await tester.tap(find.byKey(const Key('settings_device_information_row')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('disconnect_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('disconnect_confirm_button')));
    await _pumpFrames(tester);

    expect(rig.device.disconnectCount, 1);
    expect(rig.device.connectCount, 1);
    expect(find.byType(DeviceHomeScreen), findsNothing);
    expect(find.byKey(const Key('connect_button')), findsOneWidget);
  });

  testWidgets('unexpected loss stays on Home and blocks device actions', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(tester);
    rig.device.preparePendingReconnect();

    rig.device.loseConnection();
    await _pumpFrames(tester);

    expect(find.byType(DeviceHomeScreen), findsOneWidget);
    expect(
      find.byKey(const Key('connection_reconnecting_state')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('install_scene_button')), findsNothing);
    expect(find.byKey(const Key('production_settings_button')), findsNothing);
    expect(rig.device.connectCount, 2);
  });

  testWidgets('ready restores the same Home route without success snackbar', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(tester);
    final homeState = tester.state(find.byType(DeviceHomeScreen));
    rig.device.preparePendingReconnect();
    rig.device.loseConnection();
    await _pumpFrames(tester);

    rig.device.completeReconnect();
    await _pumpFrames(tester);

    expect(find.byKey(const Key('companion_stage')), findsOneWidget);
    expect(
      find.byKey(const Key('connection_reconnecting_state')),
      findsNothing,
    );
    expect(tester.state(find.byType(DeviceHomeScreen)), same(homeState));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failed reconnect offers retry and return to Discovery', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(tester);
    rig.device.nextReconnectError = StateError('radio unavailable');

    rig.device.loseConnection();
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('connection_disconnected_state')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('connection_retry_button')), findsOneWidget);
    expect(
      find.byKey(const Key('connection_return_to_discovery')),
      findsOneWidget,
    );

    rig.device.preparePendingReconnect();
    await tester.tap(find.byKey(const Key('connection_retry_button')));
    await _pumpFrames(tester);
    expect(rig.device.connectCount, 3);
    expect(
      find.byKey(const Key('connection_reconnecting_state')),
      findsOneWidget,
    );

    rig.device.failPendingReconnect();
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('connection_return_to_discovery')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('connect_button')), findsOneWidget);
  });

  for (final testCase
      in <({String name, Size size, double scale, bool reduced})>[
        (name: '360x800', size: const Size(360, 800), scale: 1, reduced: false),
        (name: '390x844', size: const Size(390, 844), scale: 1, reduced: false),
        (name: '412x915', size: const Size(412, 915), scale: 1, reduced: false),
        (
          name: '360x800 text 1.8',
          size: const Size(360, 800),
          scale: 1.8,
          reduced: false,
        ),
        (
          name: '390x844 reduced motion',
          size: const Size(390, 844),
          scale: 1,
          reduced: true,
        ),
      ]) {
    testWidgets('recovery fits ${testCase.name}', (tester) async {
      final rig = await _pumpConnectedApp(
        tester,
        size: testCase.size,
        textScale: testCase.scale,
        disableAnimations: testCase.reduced,
      );
      rig.device.preparePendingReconnect();
      rig.device.loseConnection();
      await _pumpFrames(tester);

      expect(
        find.byKey(const Key('connection_reconnecting_state')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      final hint = find.byKey(const Key('connection_reconnecting_hint'));
      await tester.ensureVisible(hint);
      await tester.pump();
      expect(tester.getSize(hint).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed recovery actions fit 360x800 at text scale 1.8', (
    tester,
  ) async {
    final rig = await _pumpConnectedApp(
      tester,
      size: const Size(360, 800),
      textScale: 1.8,
    );
    rig.device.nextReconnectError = StateError('radio unavailable');
    rig.device.loseConnection();
    await _pumpFrames(tester);

    final retry = find.byKey(const Key('connection_retry_button'));
    final discovery = find.byKey(const Key('connection_return_to_discovery'));
    await tester.ensureVisible(discovery);
    await tester.pump();

    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(discovery).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}

Future<_RecoveryWidgetRig> _pumpConnectedApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final scenes = BuiltInSceneRepository();
  final device = _RecoveryWidgetDeviceRepository();
  addTearDown(device.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(scenes),
        deviceRepositoryProvider.overrideWithValue(device),
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
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
  await tester.tap(find.byKey(const Key('connect_button')));
  await _pumpFrames(tester);
  await tester.pump(const Duration(milliseconds: 650));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  expect(find.byType(DeviceHomeScreen), findsOneWidget);
  return _RecoveryWidgetRig(device);
}

Future<void> _openSettings(WidgetTester tester) async {
  final button = find.byKey(const Key('production_settings_button'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

final class _RecoveryWidgetRig {
  const _RecoveryWidgetRig(this.device);

  final _RecoveryWidgetDeviceRepository device;
}

final class _RecoveryWidgetDeviceRepository implements DeviceRepository {
  static const _profile = VirtualDeviceEngine.displayProfile;
  static const _capabilities = VirtualDeviceEngine.capabilities;

  final _connectionController =
      StreamController<DeviceConnectionStatus>.broadcast(sync: true);
  final _snapshotController = StreamController<DeviceSnapshot>.broadcast(
    sync: true,
  );
  var _snapshot = const DeviceSnapshot(
    deviceId: VirtualDeviceEngine.deviceId,
    connectionStatus: DeviceConnectionStatus.disconnected,
    batteryPercent: 78,
    brightness: 0.8,
    activeSceneId: BuiltInSceneRepository.livingEyesId,
    displayProfile: _profile,
    capabilities: _capabilities,
  );
  var _initialConnectionComplete = false;
  Completer<void>? _reconnectCompleter;

  int connectCount = 0;
  int disconnectCount = 0;
  Object? nextReconnectError;

  void preparePendingReconnect() {
    nextReconnectError = null;
    _reconnectCompleter = Completer<void>();
  }

  void loseConnection() => _emit(DeviceConnectionStatus.disconnected);

  void completeReconnect() {
    _emit(DeviceConnectionStatus.ready);
    _reconnectCompleter?.complete();
    _reconnectCompleter = null;
  }

  void failPendingReconnect() {
    _reconnectCompleter?.completeError(StateError('reconnect failed'));
    _reconnectCompleter = null;
  }

  void _emit(DeviceConnectionStatus status) {
    _snapshot = _snapshot.copyWith(connectionStatus: status);
    _connectionController.add(status);
    _snapshotController.add(_snapshot);
  }

  @override
  Future<List<DeviceInfo>> discoverDevices() async => const [
    VirtualDeviceEngine.deviceInfo,
  ];

  @override
  Future<void> connect(String deviceId) async {
    connectCount++;
    if (!_initialConnectionComplete) {
      _initialConnectionComplete = true;
      _emit(DeviceConnectionStatus.connecting);
      _emit(DeviceConnectionStatus.discovering);
      _emit(DeviceConnectionStatus.ready);
      return;
    }
    final error = nextReconnectError;
    nextReconnectError = null;
    if (error != null) throw error;
    await (_reconnectCompleter?.future ?? Future<void>.value());
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
    _emit(DeviceConnectionStatus.disconnecting);
    _emit(DeviceConnectionStatus.disconnected);
  }

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() async* {
    yield _snapshot.connectionStatus;
    yield* _connectionController.stream;
  }

  @override
  Stream<DeviceSnapshot> watchDeviceState() async* {
    yield _snapshot;
    yield* _snapshotController.stream;
  }

  @override
  Future<void> setBrightness(double value) async {
    _snapshot = _snapshot.copyWith(brightness: value);
    _snapshotController.add(_snapshot);
  }

  @override
  Future<void> setScene(String sceneId) async {
    _snapshot = _snapshot.copyWith(activeSceneId: sceneId);
    _snapshotController.add(_snapshot);
  }

  @override
  Future<void> dispose() async {
    await _connectionController.close();
    await _snapshotController.close();
  }
}
