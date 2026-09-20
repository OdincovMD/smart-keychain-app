import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_lifecycle_host.dart';
import 'app/bootstrap.dart';
import 'app/error_handlers.dart';
import 'app/providers.dart';
import 'features/appearance/appearance_controller.dart';
import 'infrastructure/logging/crash_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final crashLog = await CrashLog.open();
  installErrorHandlers(crashLog);
  void failureLogger(String code, Object error, StackTrace stackTrace) =>
      crashLog.record('$code: $error', stackTrace);
  final dependencies = await bootstrap(log: failureLogger);

  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        sceneRepositoryProvider.overrideWithValue(dependencies.sceneRepository),
        deviceRepositoryProvider.overrideWithValue(
          dependencies.deviceRepository,
        ),
        appSettingsRepositoryProvider.overrideWithValue(
          dependencies.settingsRepository,
        ),
        localFileStorageProvider.overrideWithValue(
          dependencies.localFileStorage,
        ),
        userImageAssetRepositoryProvider.overrideWithValue(
          dependencies.userImageAssetRepository,
        ),
        imagePickerGatewayProvider.overrideWithValue(
          dependencies.imagePickerGateway,
        ),
        imageProcessorProvider.overrideWithValue(dependencies.imageProcessor),
        userImageIdGeneratorProvider.overrideWithValue(
          dependencies.userImageIdGenerator,
        ),
        failureLoggerProvider.overrideWithValue(failureLogger),
        productionEyeMotionDefinitionProvider.overrideWithValue(
          dependencies.productionEyeMotionDefinition,
        ),
        initialAppAppearanceProvider.overrideWithValue(
          dependencies.initialAppearance,
        ),
      ],
      child: AppLifecycleHost(
        onDispose: dependencies.close,
        child: const SmartKeychainApp(),
      ),
    ),
  );
}
