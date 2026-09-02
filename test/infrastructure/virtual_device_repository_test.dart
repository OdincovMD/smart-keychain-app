import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_failure.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

void main() {
  group('VirtualDeviceRepository', () {
    late BuiltInSceneRepository sceneRepository;
    late VirtualDeviceEngine engine;
    late VirtualDeviceRepository repository;

    setUp(() {
      sceneRepository = BuiltInSceneRepository();
      engine = VirtualDeviceEngine(
        sceneRepository: sceneRepository,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      );
      repository = VirtualDeviceRepository(engine: engine);
    });

    tearDown(() => repository.dispose());

    test('discovery returns the single Demo Keychain', () async {
      final devices = await repository.discoverDevices();

      expect(devices, hasLength(1));
      expect(devices.single, VirtualDeviceEngine.deviceInfo);
    });

    test('connect publishes a ready snapshot with device metadata', () async {
      final readySnapshot = repository.watchDeviceState().firstWhere(
        (snapshot) => snapshot.connectionStatus == DeviceConnectionStatus.ready,
      );

      await repository.connect(VirtualDeviceEngine.deviceId);

      final snapshot = await readySnapshot;
      expect(snapshot.deviceId, VirtualDeviceEngine.deviceId);
      expect(snapshot.connectionStatus, DeviceConnectionStatus.ready);
      expect(snapshot.batteryPercent, 78);
      expect(snapshot.displayProfile, VirtualDeviceEngine.displayProfile);
      expect(snapshot.capabilities, VirtualDeviceEngine.capabilities);
    });

    test('disconnect publishes a disconnected snapshot', () async {
      await repository.connect(VirtualDeviceEngine.deviceId);
      final disconnectedSnapshot = repository.watchDeviceState().firstWhere(
        (snapshot) =>
            snapshot.connectionStatus == DeviceConnectionStatus.disconnected,
      );

      await repository.disconnect();

      expect(
        (await disconnectedSnapshot).connectionStatus,
        DeviceConnectionStatus.disconnected,
      );
    });

    test('setBrightness publishes the committed brightness', () async {
      await repository.connect(VirtualDeviceEngine.deviceId);
      final updatedSnapshot = repository.watchDeviceState().firstWhere(
        (snapshot) => snapshot.brightness == 0.25,
      );

      await repository.setBrightness(0.25);

      expect((await updatedSnapshot).brightness, 0.25);
    });

    test('setScene publishes the committed active scene', () async {
      await repository.connect(VirtualDeviceEngine.deviceId);
      final updatedSnapshot = repository.watchDeviceState().firstWhere(
        (snapshot) =>
            snapshot.activeSceneId == BuiltInSceneRepository.sunnyFriendId,
      );

      await repository.setScene(BuiltInSceneRepository.sunnyFriendId);

      expect(
        (await updatedSnapshot).activeSceneId,
        BuiltInSceneRepository.sunnyFriendId,
      );
    });

    test('connect and disconnect publish the exact status sequence', () async {
      final statuses = <DeviceConnectionStatus>[];
      final subscription = repository.watchConnectionState().listen(
        statuses.add,
      );
      await Future<void>.delayed(Duration.zero);

      await repository.connect(VirtualDeviceEngine.deviceId);
      await repository.disconnect();

      expect(statuses, [
        DeviceConnectionStatus.disconnected,
        DeviceConnectionStatus.connecting,
        DeviceConnectionStatus.discovering,
        DeviceConnectionStatus.ready,
        DeviceConnectionStatus.disconnecting,
        DeviceConnectionStatus.disconnected,
      ]);
      await subscription.cancel();
    });

    test('device state propagates every committed command in order', () async {
      final snapshots =
          <
            ({DeviceConnectionStatus status, double brightness, String sceneId})
          >[];
      final subscription = repository.watchDeviceState().listen((snapshot) {
        snapshots.add((
          status: snapshot.connectionStatus,
          brightness: snapshot.brightness,
          sceneId: snapshot.activeSceneId,
        ));
      });
      await Future<void>.delayed(Duration.zero);

      await repository.connect(VirtualDeviceEngine.deviceId);
      await repository.setBrightness(0.4);
      await repository.setScene(BuiltInSceneRepository.sunnyFriendId);

      expect(snapshots.first.status, DeviceConnectionStatus.disconnected);
      expect(
        snapshots.map((snapshot) => snapshot.status),
        containsAllInOrder([
          DeviceConnectionStatus.connecting,
          DeviceConnectionStatus.discovering,
          DeviceConnectionStatus.ready,
        ]),
      );
      expect(snapshots.last, (
        status: DeviceConnectionStatus.ready,
        brightness: 0.4,
        sceneId: BuiltInSceneRepository.sunnyFriendId,
      ));
      await subscription.cancel();
    });

    test('scene and brightness update only after configured latency', () async {
      await repository.dispose();
      engine = VirtualDeviceEngine(
        sceneRepository: sceneRepository,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: const Duration(milliseconds: 40),
      );
      repository = VirtualDeviceRepository(engine: engine);
      await repository.connect(VirtualDeviceEngine.deviceId);

      final sceneCommand = repository.setScene(
        BuiltInSceneRepository.sunnyFriendId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        engine.snapshot.activeSceneId,
        BuiltInSceneRepository.livingEyesId,
      );
      await sceneCommand;
      expect(
        engine.snapshot.activeSceneId,
        BuiltInSceneRepository.sunnyFriendId,
      );

      final brightnessCommand = repository.setBrightness(0.25);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(engine.snapshot.brightness, 0.8);
      await brightnessCommand;
      expect(engine.snapshot.brightness, 0.25);
    });

    test('commands before ready return DeviceUnavailableFailure', () async {
      await expectLater(
        repository.setScene(BuiltInSceneRepository.sunnyFriendId),
        throwsA(isA<DeviceUnavailableFailure>()),
      );
      await expectLater(
        repository.setBrightness(0.5),
        throwsA(isA<DeviceUnavailableFailure>()),
      );
    });

    test(
      'unknown ids, scenes, and invalid brightness use domain failures',
      () async {
        await expectLater(
          repository.connect('missing-device'),
          throwsA(isA<DeviceUnavailableFailure>()),
        );
        await repository.connect(VirtualDeviceEngine.deviceId);
        await expectLater(
          repository.setScene('missing-scene'),
          throwsA(isA<UnsupportedFeatureFailure>()),
        );
        await expectLater(
          repository.setBrightness(1.1),
          throwsA(isA<InvalidDeviceCommandFailure>()),
        );
      },
    );

    test(
      'repeated and concurrent commands keep a consistent final state',
      () async {
        await repository.connect(VirtualDeviceEngine.deviceId);
        await repository.connect(VirtualDeviceEngine.deviceId);

        await Future.wait([
          repository.setScene(BuiltInSceneRepository.sunnyFriendId),
          repository.setScene(BuiltInSceneRepository.sunnyFriendId),
          repository.setBrightness(0.3),
          repository.setBrightness(0.9),
        ]);

        expect(
          engine.snapshot.activeSceneId,
          BuiltInSceneRepository.sunnyFriendId,
        );
        expect(engine.snapshot.brightness, 0.9);
        expect(engine.snapshot.connectionStatus, DeviceConnectionStatus.ready);
      },
    );

    test('latency accepts only documented presets', () {
      repository.setLatency(const Duration(milliseconds: 1000));
      expect(repository.latency, const Duration(milliseconds: 1000));
      expect(
        () => repository.setLatency(const Duration(milliseconds: 42)),
        throwsA(isA<InvalidDeviceCommandFailure>()),
      );
    });
  });
}
