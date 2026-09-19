import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/features/device_home/device_home_screen.dart';
import 'package:smart_keychain_app/features/image_import/user_image_controller.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/fake_app_settings_repository.dart';
import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';
import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets(
    'initial import failure opens one sheet and retry starts a new picker',
    (tester) async {
      final rig = _PhotoErrorRig.create();
      await _pumpHome(tester, rig);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DeviceHomeScreen)),
      );

      container.read(userImageControllerProvider.notifier).startImport();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const Key('photo_import_error_sheet')), findsOneWidget);
      expect(find.text('Фото не открылось'), findsOneWidget);
      expect(
        find.text(
          'Файл повреждён или этот формат изображения не поддерживается.',
        ),
        findsOneWidget,
      );
      expect(rig.picker.callCount, 1);

      tester.element(find.byType(DeviceHomeScreen)).markNeedsBuild();
      await tester.pump();
      expect(find.byKey(const Key('photo_import_error_sheet')), findsOneWidget);

      rig.picker.outcome = const ImagePickCancelled();
      await tester.tap(find.byKey(const Key('photo_import_retry_button')));
      await _finishSheetDismissal(tester);

      expect(rig.picker.callCount, 2);
      expect(find.byKey(const Key('photo_import_error_sheet')), findsNothing);
      expect(container.read(userImageControllerProvider), isA<UserImageIdle>());
      await tester.pump();
      expect(find.byKey(const Key('photo_import_error_sheet')), findsNothing);
    },
  );

  testWidgets('closing import failure does not restart the picker', (
    tester,
  ) async {
    final rig = _PhotoErrorRig.create();
    await _pumpHome(tester, rig);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DeviceHomeScreen)),
    );

    container.read(userImageControllerProvider.notifier).startImport();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('photo_import_close_button')));
    await _finishSheetDismissal(tester);

    expect(rig.picker.callCount, 1);
    expect(container.read(userImageControllerProvider), isA<UserImageIdle>());
    expect(find.byKey(const Key('photo_import_error_sheet')), findsNothing);
  });

  for (final testCase in const [
    (name: 'compact', size: Size(360, 800), scale: 1.0),
    (name: 'large', size: Size(412, 915), scale: 1.0),
    (name: 'enlarged text', size: Size(390, 844), scale: 1.8),
  ]) {
    testWidgets('import error sheet fits ${testCase.name}', (tester) async {
      final rig = _PhotoErrorRig.create();
      await _pumpHome(
        tester,
        rig,
        size: testCase.size,
        textScaler: TextScaler.linear(testCase.scale),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DeviceHomeScreen)),
      );

      container.read(userImageControllerProvider.notifier).startImport();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final retry = find.byKey(const Key('photo_import_retry_button'));
      await tester.ensureVisible(retry);
      await tester.pump();

      expect(find.byKey(const Key('photo_import_error_sheet')), findsOneWidget);
      expect(
        tester.getRect(retry).bottom,
        lessThanOrEqualTo(testCase.size.height),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

final class _PhotoErrorRig {
  const _PhotoErrorRig({
    required this.scenes,
    required this.device,
    required this.picker,
  });

  final BuiltInSceneRepository scenes;
  final VirtualDeviceRepository device;
  final FakeImagePickerGateway picker;

  static _PhotoErrorRig create() {
    final scenes = BuiltInSceneRepository();
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      ),
    );
    return _PhotoErrorRig(
      scenes: scenes,
      device: device,
      picker: FakeImagePickerGateway(
        const ImagePickFailed(UnsupportedImageFailure()),
      ),
    );
  }
}

Future<void> _pumpHome(
  WidgetTester tester,
  _PhotoErrorRig rig, {
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final connection = rig.device.connect(VirtualDeviceEngine.deviceId);
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await connection;
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await rig.device.dispose();
    tester.view.reset();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(rig.scenes),
        deviceRepositoryProvider.overrideWithValue(rig.device),
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
        localFileStorageProvider.overrideWithValue(FakeLocalFileStorage()),
        userImageAssetRepositoryProvider.overrideWithValue(
          FakeUserImageAssetRepository(),
        ),
        imagePickerGatewayProvider.overrideWithValue(rig.picker),
        imageProcessorProvider.overrideWithValue(FakeImageProcessor()),
        userImageIdGeneratorProvider.overrideWithValue(
          FakeUserImageIdGenerator('photo-error'),
        ),
        failureLoggerProvider.overrideWithValue(_ignoreFailure),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const DeviceHomeScreen(deviceId: VirtualDeviceEngine.deviceId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}

Future<void> _finishSheetDismissal(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}
