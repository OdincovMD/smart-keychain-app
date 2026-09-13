import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/device/device_capabilities.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/features/device_home/widgets/companion_stage.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

void main() {
  testWidgets('user photo is not covered by companion makeup', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _StageHarness(_photo)));
    await tester.pump();

    expect(find.byKey(const Key('companion_stage_makeup')), findsNothing);
    expect(find.byKey(const Key('user_photo_surface')), findsOneWidget);
  });

  testWidgets('built-in static look keeps companion makeup', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _StageHarness(_static)));
    await tester.pump();

    expect(find.byKey(const Key('companion_stage_makeup')), findsOneWidget);
  });
}

final class _StageHarness extends StatelessWidget {
  const _StageHarness(this.scene);

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Center(
          child: CompanionStage(
            scene: scene,
            displayProfile: _profile,
            snapshot: _snapshot,
            diameter: 274,
            jewelryMode: true,
            visualStudyOverride: const ColoredBox(
              key: Key('user_photo_surface'),
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

const _profile = DisplayProfile(
  width: 240,
  height: 240,
  shape: DisplayShape.circle,
  aspectRatio: 1,
);

const _snapshot = DeviceSnapshot(
  deviceId: 'test-device',
  connectionStatus: DeviceConnectionStatus.ready,
  batteryPercent: 82,
  brightness: 0.8,
  activeSceneId: 'test-scene',
  displayProfile: _profile,
  capabilities: DeviceCapabilities(
    supportsBrightness: true,
    reportsBattery: true,
    supportsStaticScenes: true,
    supportsAnimatedScenes: true,
  ),
);

const _photo = Scene(
  id: 'user-photo-test',
  name: 'Моё фото',
  content: UserImageContent(
    assetId: 'photo-test',
    previewStorageKey: 'user-content/previews/photo-test.png',
  ),
  source: SceneSource.userGenerated,
);

const _static = Scene(
  id: 'static-test',
  name: 'Статичный образ',
  content: StaticImageContent(previewAssetPath: 'unused-in-test.png'),
  source: SceneSource.builtIn,
);
