import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/application/device_controller.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/features/device_home/connection_recovery_controller.dart';

void main() {
  group('ConnectionRecoveryController', () {
    test(
      'unexpected disconnect starts exactly one automatic reconnect',
      () async {
        final rig = await _createRig();
        rig.device.connectCompleter = Completer<void>();

        rig.device.emit(DeviceConnectionStatus.disconnected);
        await rig.pump();
        rig.device.emit(DeviceConnectionStatus.disconnected);
        await rig.pump();

        expect(rig.device.connectCount, 1);
        expect(rig.state.status, ConnectionRecoveryStatus.reconnecting);
        rig.device.connectCompleter!.complete();
      },
    );

    test('connect completion alone does not confirm recovery', () async {
      final rig = await _createRig();

      rig.device.emit(DeviceConnectionStatus.disconnected);
      await rig.pump();

      expect(rig.device.connectCount, 1);
      expect(rig.state.status, ConnectionRecoveryStatus.reconnecting);
    });

    test('ready confirms recovery and resets the loss episode', () async {
      final rig = await _createRig();
      rig.device.connectCompleter = Completer<void>();

      rig.device.emit(DeviceConnectionStatus.disconnected);
      await rig.pump();
      rig.device.emit(DeviceConnectionStatus.ready);
      await rig.pump();

      expect(rig.state.status, ConnectionRecoveryStatus.connected);
      rig.device.connectCompleter!.complete();
    });

    test(
      'failure exposes retry and manual retry starts a new command',
      () async {
        final rig = await _createRig();
        rig.device.connectError = StateError('radio unavailable');

        rig.device.emit(DeviceConnectionStatus.disconnected);
        await rig.pump();

        expect(rig.state.status, ConnectionRecoveryStatus.failed);
        expect(rig.device.connectCount, 1);

        rig.device.connectError = null;
        rig.device.connectCompleter = Completer<void>();
        rig.notifier.retry();
        rig.notifier.retry();
        await rig.pump();

        expect(rig.state.status, ConnectionRecoveryStatus.reconnecting);
        expect(rig.device.connectCount, 2);
        rig.device.connectCompleter!.complete();
      },
    );

    test('intentional disconnect never starts reconnect', () async {
      final rig = await _createRig();

      rig.notifier.disconnectIntentionally();
      await rig.pump();
      rig.device.emit(DeviceConnectionStatus.disconnected);
      await rig.pump();

      expect(rig.device.disconnectCount, 1);
      expect(rig.device.connectCount, 0);
      expect(rig.state.returnToDiscovery, isTrue);
    });

    test(
      'late ready and command completion after disposal are ignored',
      () async {
        final device = _RecoveryFakeDeviceRepository();
        final container = ProviderContainer(
          overrides: [deviceRepositoryProvider.overrideWithValue(device)],
        );
        final states = <ConnectionRecoveryState>[];
        final subscription = container.listen(
          connectionRecoveryControllerProvider(
            _RecoveryFakeDeviceRepository.id,
          ),
          (previous, next) => states.add(next),
          fireImmediately: true,
        );
        await _pumpContainer(container);
        device.connectCompleter = Completer<void>();
        device.emit(DeviceConnectionStatus.disconnected);
        await _pumpContainer(container);
        final beforeDispose = states.length;

        subscription.close();
        await _pumpContainer(container);
        device.emit(DeviceConnectionStatus.ready);
        device.connectCompleter!.complete();
        await _pumpContainer(container);

        expect(states, hasLength(beforeDispose));
        container.dispose();
        await device.dispose();
      },
    );
  });

  test('DeviceController queues an intentional disconnect behind an active command', () async {
    final device = _RecoveryFakeDeviceRepository()
      ..connectCompleter = Completer<void>();
    final container = ProviderContainer(
      overrides: [deviceRepositoryProvider.overrideWithValue(device)],
    );
    addTearDown(device.dispose);
    addTearDown(container.dispose);
    container.listen(deviceControllerProvider, (previous, next) {});
    await _pumpContainer(container);

    final controller = container.read(deviceControllerProvider.notifier);
    controller.connect(_RecoveryFakeDeviceRepository.id);
    controller.disconnect();
    await _pumpContainer(container);
    expect(device.disconnectCount, 0);

    device.connectCompleter!.complete();
    await _pumpContainer(container);
    expect(device.disconnectCount, 1);
  });
}

Future<_RecoveryRig> _createRig() async {
  final device = _RecoveryFakeDeviceRepository();
  final container = ProviderContainer(
    overrides: [deviceRepositoryProvider.overrideWithValue(device)],
  );
  addTearDown(device.dispose);
  addTearDown(container.dispose);
  final provider = connectionRecoveryControllerProvider(
    _RecoveryFakeDeviceRepository.id,
  );
  final subscription = container.listen(
    provider,
    (previous, next) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  await _pumpContainer(container);
  return _RecoveryRig(container: container, device: device);
}

Future<void> _pumpContainer(ProviderContainer container) async {
  await container.pump();
  await Future<void>.delayed(Duration.zero);
  await container.pump();
}

final class _RecoveryRig {
  const _RecoveryRig({required this.container, required this.device});

  final ProviderContainer container;
  final _RecoveryFakeDeviceRepository device;

  ConnectionRecoveryState get state => container.read(
    connectionRecoveryControllerProvider(_RecoveryFakeDeviceRepository.id),
  );

  ConnectionRecoveryController get notifier => container.read(
    connectionRecoveryControllerProvider(_RecoveryFakeDeviceRepository.id)
        .notifier,
  );

  Future<void> pump() => _pumpContainer(container);
}

final class _RecoveryFakeDeviceRepository implements DeviceRepository {
  static const id = 'recovery-device';

  final _connectionController =
      StreamController<DeviceConnectionStatus>.broadcast(sync: true);
  var _status = DeviceConnectionStatus.ready;

  int connectCount = 0;
  int disconnectCount = 0;
  Object? connectError;
  Completer<void>? connectCompleter;

  void emit(DeviceConnectionStatus status) {
    _status = status;
    _connectionController.add(status);
  }

  @override
  Future<void> connect(String deviceId) {
    connectCount++;
    final error = connectError;
    if (error != null) return Future<void>.error(error);
    return connectCompleter?.future ?? Future<void>.value();
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
  }

  @override
  Future<List<DeviceInfo>> discoverDevices() async => const <DeviceInfo>[];

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() async* {
    yield _status;
    yield* _connectionController.stream;
  }

  @override
  Stream<DeviceSnapshot> watchDeviceState() => const Stream.empty();

  @override
  Future<void> setBrightness(double value) async {}

  @override
  Future<void> setScene(String sceneId) async {}

  @override
  Future<void> dispose() => _connectionController.close();
}
