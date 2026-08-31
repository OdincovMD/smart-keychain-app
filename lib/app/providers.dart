import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content/scene.dart';
import '../domain/device/device_connection_status.dart';
import '../domain/device/device_info.dart';
import '../domain/device/device_repository.dart';
import '../domain/device/device_snapshot.dart';
import '../infrastructure/content/built_in_scene_catalog.dart';
import '../infrastructure/device/simulator_controls.dart';
import '../infrastructure/device/virtual_device_repository.dart';

final virtualDeviceRepositoryProvider = Provider<VirtualDeviceRepository>((
  ref,
) {
  final repository = VirtualDeviceRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => ref.watch(virtualDeviceRepositoryProvider),
);

final simulatorControlsProvider = Provider<SimulatorControls>(
  (ref) => ref.watch(virtualDeviceRepositoryProvider),
);

final discoveredDevicesProvider = FutureProvider<List<DeviceInfo>>(
  (ref) => ref.watch(deviceRepositoryProvider).discoverDevices(),
);

final connectionStateProvider = StreamProvider<DeviceConnectionStatus>(
  (ref) => ref.watch(deviceRepositoryProvider).watchConnectionState(),
);

final deviceSnapshotProvider = StreamProvider<DeviceSnapshot>(
  (ref) => ref.watch(deviceRepositoryProvider).watchDeviceState(),
);

final simulatorLatencyProvider = StreamProvider<Duration>(
  (ref) => ref.watch(simulatorControlsProvider).watchLatency(),
);

final builtInScenesProvider = Provider<List<Scene>>(
  (ref) => BuiltInSceneCatalog.scenes,
);
