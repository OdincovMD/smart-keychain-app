import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/features/device_home/widgets/virtual_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_catalog.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('/devices displays Russian localization', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: Duration.zero),
    );
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository);

    expect(find.text('Выберите брелок'), findsOneWidget);
    expect(find.text('Подключить'), findsOneWidget);
  });

  testWidgets('connecting disables a repeated tap', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: const Duration(milliseconds: 100)),
    );
    addTearDown(repository.dispose);
    await _pumpApp(tester, repository);

    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('connect_button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Подключаем…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
  });

  testWidgets('ready opens Device Home', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: Duration.zero),
    );
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    expect(find.text('Настроение экрана'), findsOneWidget);
    expect(find.byType(VirtualScreen), findsOneWidget);
  });

  testWidgets('second scene appears only after command latency', (
    tester,
  ) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: const Duration(milliseconds: 100)),
    );
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    final sunnyScene = find.byKey(const Key('scene_sunny_friend_static_v1'));
    await tester.ensureVisible(sunnyScene);
    await tester.pumpAndSettle();
    await tester.tap(sunnyScene);
    await tester.pump();

    final installButton = find.byKey(const Key('install_scene_button'));
    await tester.ensureVisible(installButton);
    await tester.pumpAndSettle();
    await tester.tap(installButton);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.byKey(const ValueKey(BuiltInSceneCatalog.mintEyesId)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(BuiltInSceneCatalog.sunnyFriendId)),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey(BuiltInSceneCatalog.sunnyFriendId)),
      findsOneWidget,
    );
  });

  testWidgets('brightness slider darkens the virtual screen', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: Duration.zero),
    );
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();

    final overlay = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(VirtualScreen),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = overlay.decoration! as BoxDecoration;
    expect(decoration.color!.a, greaterThan(0.2));
  });

  testWidgets('disconnect returns to device discovery', (tester) async {
    final repository = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(latency: Duration.zero),
    );
    addTearDown(repository.dispose);
    await _pumpConnectedApp(tester, repository);

    await tester.tap(find.byKey(const Key('disconnect_button')));
    await tester.pumpAndSettle();

    expect(find.text('Выберите брелок'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  VirtualDeviceRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        virtualDeviceRepositoryProvider.overrideWithValue(repository),
      ],
      child: const SmartKeychainApp(),
    ),
  );
  await tester.pump();
}

Future<void> _pumpConnectedApp(
  WidgetTester tester,
  VirtualDeviceRepository repository,
) async {
  await _pumpApp(tester, repository);
  await tester.tap(find.byKey(const Key('connect_button')));
  await tester.pumpAndSettle();
}
