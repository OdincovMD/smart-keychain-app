@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/features/device_home/connection_recovery_controller.dart';
import 'package:smart_keychain_app/features/device_home/connection_recovery_view.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  for (final appearance in ResolvedAppAppearance.values) {
    final appearanceName = appearance.name;

    for (final status in const [
      ConnectionRecoveryStatus.disconnected,
      ConnectionRecoveryStatus.reconnecting,
    ]) {
      final statusName = status.name;
      testWidgets('$statusName $appearanceName 390x844', (tester) async {
        await _pumpRecovery(tester, appearance: appearance, status: status);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'baselines/${statusName}_${appearanceName}_390x844.png',
          ),
        );
      });
    }
  }
}

Future<void> _pumpRecovery(
  WidgetTester tester, {
  required ResolvedAppAppearance appearance,
  required ConnectionRecoveryStatus status,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final scene = await BuiltInSceneRepository().getById(
    BuiltInSceneRepository.livingEyesId,
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: ConnectionRecoveryView(
            status: status,
            snapshot: _snapshot,
            scene: scene!,
            onRetry: _noop,
            onReturnToDiscovery: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await Future.wait(
      const <String>[
        'assets/chrome_kiss/key_ring.png',
        'assets/chrome_kiss/key_ring_opening.png',
        'assets/chrome_kiss/pendant_chrome_shell.png',
        'assets/chrome_kiss/pendant_lens.png',
        'assets/chrome_kiss/lens_inner_rim.png',
        'assets/chrome_kiss/lens_glint_lilac.png',
        'assets/chrome_kiss/lens_glint_white.png',
        'assets/chrome_kiss/lens_glint_orchid.png',
        'assets/chrome_kiss/bow_left.png',
        'assets/chrome_kiss/bow_right.png',
        'assets/chrome_kiss/bow_knot.png',
        'assets/chrome_kiss/charm_ring.png',
        'assets/chrome_kiss/eye_left_figma.png',
        'assets/chrome_kiss/eye_right_figma.png',
      ].map((path) => precacheImage(AssetImage(path), context)),
    );
  });
  await tester.pump();
}

void _noop() {}

const _snapshot = DeviceSnapshot(
  deviceId: VirtualDeviceEngine.deviceId,
  connectionStatus: DeviceConnectionStatus.disconnected,
  batteryPercent: 78,
  brightness: 0.8,
  activeSceneId: BuiltInSceneRepository.livingEyesId,
  displayProfile: VirtualDeviceEngine.displayProfile,
  capabilities: VirtualDeviceEngine.capabilities,
);
