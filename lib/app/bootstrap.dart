import 'package:flutter/services.dart';

import '../application/startup_restoration.dart';
import '../core/failure_logger.dart';
import '../data/database/app_database.dart';
import '../data/database/open_database.dart';
import '../data/image/drift_user_image_asset_repository.dart';
import '../data/settings/drift_app_settings_repository.dart';
import '../domain/content/scene_repository.dart';
import '../domain/device/device_repository.dart';
import '../domain/eyes/eye_motion_definition.dart';
import '../domain/eyes/eye_motion_library.dart';
import '../domain/image/image_picker_gateway.dart';
import '../domain/image/image_processor.dart';
import '../domain/image/user_image_asset_repository.dart';
import '../domain/image/user_image_id_generator.dart';
import '../domain/settings/app_settings_repository.dart';
import '../domain/settings/app_appearance.dart';
import '../domain/storage/local_file_storage.dart';
import '../infrastructure/content/built_in_scene_repository.dart';
import '../infrastructure/content/composite_scene_repository.dart';
import '../infrastructure/content/user_image_scene_repository.dart';
import '../infrastructure/device/virtual_device_engine.dart';
import '../infrastructure/device/virtual_device_repository.dart';
import '../infrastructure/filesystem/application_documents_file_storage.dart';
import '../infrastructure/eyes/bundled_eye_motion_definition_loader.dart';
import '../infrastructure/image/isolated_image_processor.dart';
import '../infrastructure/image/platform_image_picker_gateway.dart';
import '../infrastructure/image/timestamp_user_image_id_generator.dart';

final class AppDependencies {
  AppDependencies({
    required this.sceneRepository,
    required this.deviceRepository,
    required this.settingsRepository,
    required this.localFileStorage,
    required this.userImageAssetRepository,
    required this.imagePickerGateway,
    required this.imageProcessor,
    required this.userImageIdGenerator,
    required this.database,
    required this.disposeDevice,
    required this.initialAppearance,
    required this.productionEyeMotionDefinition,
  });

  final SceneRepository sceneRepository;
  final DeviceRepository deviceRepository;
  final AppSettingsRepository settingsRepository;
  final LocalFileStorage localFileStorage;
  final UserImageAssetRepository userImageAssetRepository;
  final ImagePickerGateway imagePickerGateway;
  final ImageProcessor imageProcessor;
  final UserImageIdGenerator userImageIdGenerator;
  final AppDatabase database;
  final Future<void> Function() disposeDevice;
  final AppAppearance initialAppearance;
  final EyeMotionDefinition productionEyeMotionDefinition;

  Future<void> close() async {
    await disposeDevice();
    await database.close();
  }
}

Future<AppDependencies> bootstrap({
  required FailureLogger log,
  AssetBundle? assetBundle,
}) async {
  final database = AppDatabase(openAppDatabaseConnection());
  VirtualDeviceRepository? deviceRepository;
  try {
    final settingsRepository = DriftAppSettingsRepository(database);
    final userImageAssetRepository = DriftUserImageAssetRepository(
      database,
      log: log,
    );
    final sceneRepository = CompositeSceneRepository([
      BuiltInSceneRepository(),
      UserImageSceneRepository(userImageAssetRepository),
    ]);
    final restored = await restoreDevicePreferences(
      settingsRepository: settingsRepository,
      sceneRepository: sceneRepository,
      defaultSceneId: BuiltInSceneRepository.livingEyesId,
    );
    deviceRepository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: sceneRepository,
        initialSceneId: restored.activeSceneId,
        initialBrightness: restored.brightness,
      ),
    );
    final localFileStorage = await ApplicationDocumentsFileStorage.open(
      log: log,
    );
    final imagePickerGateway = PlatformImagePickerGateway(log: log);
    final imageProcessor = IsolatedImageProcessor(log: log);
    final userImageIdGenerator = TimestampUserImageIdGenerator();
    final productionEyeMotionDefinition =
        await BundledEyeMotionDefinitionLoader(
          bundle: assetBundle ?? rootBundle,
          log: log,
        ).loadOrFallback(chromeKissEyeMotionDefinition);

    return AppDependencies(
      sceneRepository: sceneRepository,
      deviceRepository: deviceRepository,
      settingsRepository: settingsRepository,
      localFileStorage: localFileStorage,
      userImageAssetRepository: userImageAssetRepository,
      imagePickerGateway: imagePickerGateway,
      imageProcessor: imageProcessor,
      userImageIdGenerator: userImageIdGenerator,
      database: database,
      disposeDevice: deviceRepository.dispose,
      initialAppearance: restored.appearance,
      productionEyeMotionDefinition: productionEyeMotionDefinition,
    );
  } catch (error, stackTrace) {
    log('app.bootstrap', error, stackTrace);
    if (deviceRepository != null) await deviceRepository.dispose();
    await database.close();
    rethrow;
  }
}
