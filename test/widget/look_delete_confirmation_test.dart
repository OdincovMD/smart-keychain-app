import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/device/device_capabilities.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/user_content/look_delete_confirmation_sheet.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets('delete failure stays inline and retry removes the look', (
    tester,
  ) async {
    final bytes = (await tester.runAsync(
      () => File('assets/scenes/eyes_mint_static_v1.png').readAsBytes(),
    ))!;
    final storage = FakeLocalFileStorage();
    final original = await storage.write(
      namespace: LocalStorageNamespace.userImageOriginals,
      fileName: 'delete-test.png',
      bytes: bytes,
    );
    final preview = await storage.write(
      namespace: LocalStorageNamespace.userImagePreviews,
      fileName: 'delete-test.png',
      bytes: bytes,
    );
    final asset = UserImageAsset(
      id: 'delete-test',
      originalStorageKey: (original as Ok<String, StorageFailure>).value,
      previewStorageKey: (preview as Ok<String, StorageFailure>).value,
      cropSpec: CropSpec.centered,
      createdAt: DateTime.utc(2026, 9, 19),
    );
    final assets = FakeUserImageAssetRepository([asset])..failDeletes = true;
    final scene = Scene(
      id: 'user-image:${asset.id}',
      name: 'Вечерний блеск',
      source: SceneSource.userGenerated,
      content: UserImageContent(
        assetId: asset.id,
        previewStorageKey: asset.previewStorageKey,
      ),
    );
    final device = _DeleteDeviceRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userImageAssetRepositoryProvider.overrideWithValue(assets),
          localFileStorageProvider.overrideWithValue(storage),
          deviceRepositoryProvider.overrideWithValue(device),
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          failureLoggerProvider.overrideWithValue(_ignoreFailure),
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
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LookDeleteConfirmationSheet(scene: scene),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final eyes = tester.widget<ChromeKissProductionEyes>(
      find.byType(ChromeKissProductionEyes),
    );
    expect(eyes.scale, ChromeKissEyeScale.tiny);
    expect(eyes.mood, KissCutVisualMood.annoyed);
    expect(eyes.animate, isFalse);

    await tester.tap(find.byKey(const Key('confirm_delete_image')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('delete_look_error')), findsOneWidget);
    expect(assets.values, [asset]);
    expect(find.textContaining('не удалось'), findsOneWidget);

    assets.failDeletes = false;
    await tester.tap(find.byKey(const Key('confirm_delete_image')));
    await tester.pump();
    await tester.pump();

    expect(assets.values, isEmpty);
    expect(storage.existingPaths, isEmpty);
    expect(find.byKey(const Key('delete_look_error')), findsNothing);
    expect(tester.takeException(), isNull);

    await device.dispose();
  });
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}

final class _DeleteDeviceRepository implements DeviceRepository {
  static const _snapshot = DeviceSnapshot(
    deviceId: 'delete-device',
    connectionStatus: DeviceConnectionStatus.ready,
    batteryPercent: 90,
    brightness: AppSettings.defaultBrightness,
    activeSceneId: 'eyes_living_v1',
    displayProfile: DisplayProfile(
      width: 240,
      height: 240,
      shape: DisplayShape.circle,
      aspectRatio: 1,
    ),
    capabilities: DeviceCapabilities(
      supportsBrightness: true,
      reportsBattery: true,
      supportsStaticScenes: true,
      supportsAnimatedScenes: true,
    ),
  );

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
  Stream<DeviceSnapshot> watchDeviceState() => Stream.value(_snapshot);

  @override
  Future<void> setScene(String sceneId) async {}

  @override
  Future<void> setBrightness(double value) async {}

  @override
  Future<void> dispose() async {}
}
