import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/delete_user_image_scene.dart';
import '../application/user_image_workflow.dart';
import '../core/failure_logger.dart';
import '../core/result.dart';
import '../domain/content/scene.dart';
import '../domain/content/scene_repository.dart';
import '../domain/device/device_connection_status.dart';
import '../domain/device/device_info.dart';
import '../domain/device/device_repository.dart';
import '../domain/device/device_snapshot.dart';
import '../domain/image/image_picker_gateway.dart';
import '../domain/image/image_processor.dart';
import '../domain/image/user_image_asset_repository.dart';
import '../domain/image/user_image_id_generator.dart';
import '../domain/settings/app_settings_repository.dart';
import '../domain/storage/local_file_storage.dart';
import '../infrastructure/content/built_in_scene_repository.dart';
import '../infrastructure/device/simulator_controls.dart';

final clockProvider = Provider<Clock>((ref) => const Clock());

final failureLoggerProvider = Provider<FailureLogger>(
  (ref) => throw UnimplementedError(
    'Override failureLoggerProvider in the composition root.',
  ),
);

final sceneRepositoryProvider = Provider<SceneRepository>(
  (ref) => throw UnimplementedError(
    'Override sceneRepositoryProvider in the composition root.',
  ),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => throw UnimplementedError(
    'Override deviceRepositoryProvider in the composition root.',
  ),
);

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => throw UnimplementedError(
    'Override appSettingsRepositoryProvider in the composition root.',
  ),
);

final localFileStorageProvider = Provider<LocalFileStorage>(
  (ref) => throw UnimplementedError(
    'Override localFileStorageProvider in the composition root.',
  ),
);

final userImageAssetRepositoryProvider = Provider<UserImageAssetRepository>(
  (ref) => throw UnimplementedError(
    'Override userImageAssetRepositoryProvider in the composition root.',
  ),
);

final imagePickerGatewayProvider = Provider<ImagePickerGateway>(
  (ref) => throw UnimplementedError(
    'Override imagePickerGatewayProvider in the composition root.',
  ),
);

final imageProcessorProvider = Provider<ImageProcessor>(
  (ref) => throw UnimplementedError(
    'Override imageProcessorProvider in the composition root.',
  ),
);

final userImageIdGeneratorProvider = Provider<UserImageIdGenerator>(
  (ref) => throw UnimplementedError(
    'Override userImageIdGeneratorProvider in the composition root.',
  ),
);

final userImageWorkflowProvider = Provider<UserImageWorkflow>((ref) {
  return UserImageWorkflow(
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(userImageIdGeneratorProvider),
    picker: ref.watch(imagePickerGatewayProvider),
    processor: ref.watch(imageProcessorProvider),
    storage: ref.watch(localFileStorageProvider),
    assets: ref.watch(userImageAssetRepositoryProvider),
  );
});

final deleteUserImageSceneProvider = Provider<DeleteUserImageScene>((ref) {
  return DeleteUserImageScene(
    assets: ref.watch(userImageAssetRepositoryProvider),
    storage: ref.watch(localFileStorageProvider),
    device: ref.watch(deviceRepositoryProvider),
    settings: ref.watch(appSettingsRepositoryProvider),
    fallbackSceneId: BuiltInSceneRepository.livingEyesId,
    log: ref.watch(failureLoggerProvider),
  );
});

final simulatorControlsProvider = Provider<SimulatorControls>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  if (repository case final SimulatorControls controls) return controls;
  throw UnsupportedError('The active device has no simulator controls.');
});

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

final sceneLibraryProvider = FutureProvider<List<Scene>>(
  (ref) => ref.watch(sceneRepositoryProvider).getAll(),
);

final sceneByIdProvider = FutureProvider.family<Scene?, String>(
  (ref, id) => ref.watch(sceneRepositoryProvider).getById(id),
);

final localImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, storageKey) async {
      return switch (await ref
          .watch(localFileStorageProvider)
          .read(storageKey)) {
        Ok(:final value) => value,
        Err() => null,
      };
    });
