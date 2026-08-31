import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('Device Discovery 390x844', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: Duration.zero),
    );
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/device_discovery_390x844.png'),
    );
  });

  testWidgets('Device Home 390x844', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: Duration.zero),
    );
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository);
    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('baselines/device_home_390x844.png'),
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  VirtualDeviceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        virtualDeviceRepositoryProvider.overrideWithValue(repository),
      ],
      child: const SmartKeychainApp(),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await Future.wait([
      precacheImage(
        const AssetImage('assets/scenes/eyes_mint_static_v1.png'),
        context,
      ),
      precacheImage(
        const AssetImage('assets/scenes/sunny_friend_static_v1.png'),
        context,
      ),
    ]);
  });
  await tester.pump();
}
