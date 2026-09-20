import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/app/router.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/features/device_discovery/device_discovery_screen.dart';
import 'package:smart_keychain_app/features/device_home/device_home_screen.dart';
import 'package:smart_keychain_app/features/device_home/home_async_state_view.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadCompanionHomeFonts();
    final repository = BuiltInSceneRepository();
    _scenes = await repository.getAll();
    _activeScene = (await repository.getById(
      BuiltInSceneRepository.livingEyesId,
    ))!;
  });

  testWidgets('initial snapshot loading uses the branded waking state', (
    tester,
  ) async {
    final pendingSnapshot = Completer<DeviceSnapshot>();
    await _pumpHome(
      tester,
      snapshot: (ref) => Stream.fromFuture(pendingSnapshot.future),
    );

    expect(find.byKey(const Key('home_async_initialLoading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Главный экран загружается')),
      findsWidgets,
    );
  });

  testWidgets('snapshot retry refreshes only the snapshot provider', (
    tester,
  ) async {
    var snapshotLoads = 0;
    var sceneLoads = 0;
    await _pumpHome(
      tester,
      snapshot: (ref) {
        snapshotLoads++;
        if (snapshotLoads == 1) {
          return Stream<DeviceSnapshot>.error(StateError('snapshot failed'));
        }
        return Stream.value(_snapshot);
      },
      scenes: (ref) {
        sceneLoads++;
        return Future.value(_scenes);
      },
    );

    expect(
      find.byKey(const Key('home_async_snapshotUnavailable')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('home_async_retry_button')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('companion_stage')), findsOneWidget);
    expect(snapshotLoads, 2);
    expect(sceneLoads, 1);
  });

  testWidgets('snapshot unavailable can return to device discovery', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      snapshot: (ref) =>
          Stream<DeviceSnapshot>.error(StateError('snapshot failed')),
    );

    await tester.tap(find.byKey(const Key('home_async_return_to_discovery')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('async_test_discovery')), findsOneWidget);
  });

  testWidgets('scene library loading uses the content loading state', (
    tester,
  ) async {
    final pendingScenes = Completer<List<Scene>>();
    await _pumpHome(tester, scenes: (ref) => pendingScenes.future);

    expect(find.byKey(const Key('home_async_contentLoading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('scene library failure retries only the library provider', (
    tester,
  ) async {
    var sceneLoads = 0;
    var activeSceneLoads = 0;
    await _pumpHome(
      tester,
      scenes: (ref) {
        sceneLoads++;
        if (sceneLoads == 1) throw StateError('library failed');
        return Future.value(_scenes);
      },
      activeScene: (ref) {
        activeSceneLoads++;
        return Future.value(_activeScene);
      },
    );

    expect(
      find.byKey(const Key('home_async_sceneLibraryFailure')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('home_async_retry_button')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('companion_stage')), findsOneWidget);
    expect(sceneLoads, 2);
    expect(activeSceneLoads, 1);
  });

  testWidgets('active scene loading uses the content loading state', (
    tester,
  ) async {
    final pendingScene = Completer<Scene?>();
    await _pumpHome(tester, activeScene: (ref) => pendingScene.future);

    expect(find.byKey(const Key('home_async_contentLoading')), findsOneWidget);
  });

  testWidgets('missing active scene is a recoverable Home error', (
    tester,
  ) async {
    await _pumpHome(tester, activeScene: (ref) => Future<Scene?>.value());

    expect(
      find.byKey(const Key('home_async_activeSceneFailure')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home_async_retry_button')), findsOneWidget);
  });

  testWidgets('active scene failure retries only that scene provider', (
    tester,
  ) async {
    var sceneLoads = 0;
    var activeSceneLoads = 0;
    await _pumpHome(
      tester,
      scenes: (ref) {
        sceneLoads++;
        return Future.value(_scenes);
      },
      activeScene: (ref) {
        activeSceneLoads++;
        if (activeSceneLoads == 1) throw StateError('scene failed');
        return Future.value(_activeScene);
      },
    );

    await tester.tap(find.byKey(const Key('home_async_retry_button')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('companion_stage')), findsOneWidget);
    expect(activeSceneLoads, 2);
    expect(sceneLoads, 1);
  });

  testWidgets('last-known-good Home remains visible during content refresh', (
    tester,
  ) async {
    var sceneLoads = 0;
    final refresh = Completer<List<Scene>>();
    await _pumpHome(
      tester,
      scenes: (ref) {
        sceneLoads++;
        if (sceneLoads == 1) return Future.value(_scenes);
        return refresh.future;
      },
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DeviceHomeScreen)),
    );

    container.invalidate(sceneLibraryProvider);
    await tester.pump();

    expect(find.byKey(const Key('companion_stage')), findsOneWidget);
    expect(find.byType(HomeContentLoadingIndicator), findsOneWidget);
    expect(find.byKey(const Key('home_async_contentLoading')), findsNothing);
  });

  testWidgets('Connection Recovery has priority over content failure', (
    tester,
  ) async {
    final reconnect = Completer<void>();
    await _pumpHome(
      tester,
      device: _StaticDeviceRepository(
        status: DeviceConnectionStatus.disconnected,
        connectResult: reconnect.future,
      ),
      scenes: (ref) => Future<List<Scene>>.error(
        StateError('library failed behind recovery'),
      ),
    );
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('connection_reconnecting_state')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_async_sceneLibraryFailure')),
      findsNothing,
    );
  });

  testWidgets('repeated Retry does not duplicate the refresh operation', (
    tester,
  ) async {
    var sceneLoads = 0;
    final refresh = Completer<List<Scene>>();
    await _pumpHome(
      tester,
      scenes: (ref) {
        sceneLoads++;
        if (sceneLoads == 1) throw StateError('library failed');
        return refresh.future;
      },
    );

    final retry = find.byKey(const Key('home_async_retry_button'));
    await tester.tap(retry);
    await tester.tap(retry);
    await _pumpFrames(tester);

    expect(sceneLoads, 2);
    expect(
      find.byKey(const Key('home_async_sceneLibraryFailure')),
      findsOneWidget,
    );
    await tester.tap(retry);
    await tester.pump();
    expect(sceneLoads, 2);
  });

  testWidgets('reduced motion keeps a static meaningful optical rim', (
    tester,
  ) async {
    final pendingSnapshot = Completer<DeviceSnapshot>();
    await _pumpHome(
      tester,
      disableAnimations: true,
      snapshot: (ref) => Stream.fromFuture(pendingSnapshot.future),
    );

    expect(
      find.byKey(const Key('home_loading_optical_static')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_loading_optical_animated')),
      findsNothing,
    );
  });

  for (final appearance in AppAppearance.values.where(
    (value) => value != AppAppearance.system,
  )) {
    for (final size in const <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
    ]) {
      testWidgets(
        'loading fits ${size.width}x${size.height} in ${appearance.name}',
        (tester) async {
          final pendingSnapshot = Completer<DeviceSnapshot>();
          await _pumpHome(
            tester,
            size: size,
            appearance: appearance,
            snapshot: (ref) => Stream.fromFuture(pendingSnapshot.future),
          );

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('home_async_initialLoading')),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('error actions fit text scale 1.8 in ${appearance.name}', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(360, 800),
        textScale: 1.8,
        appearance: appearance,
        snapshot: (ref) =>
            Stream<DeviceSnapshot>.error(StateError('snapshot failed')),
      );
      final retry = find.byKey(const Key('home_async_retry_button'));
      final discovery = find.byKey(const Key('home_async_return_to_discovery'));

      await tester.ensureVisible(discovery);
      await tester.pump();
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(discovery).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
}

typedef _SnapshotBuilder = Stream<DeviceSnapshot> Function(Ref ref);
typedef _ScenesBuilder = Future<List<Scene>> Function(Ref ref);
typedef _SceneBuilder = Future<Scene?> Function(Ref ref);

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = true,
  AppAppearance appearance = AppAppearance.obsidian,
  DeviceRepository? device,
  _SnapshotBuilder? snapshot,
  _ScenesBuilder? scenes,
  _SceneBuilder? activeScene,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/device/${_snapshot.deviceId}',
    routes: [
      GoRoute(
        path: DeviceDiscoveryScreen.routePath,
        builder: (context, state) =>
            const Scaffold(body: SizedBox(key: Key('async_test_discovery'))),
      ),
      GoRoute(
        path: '/device/:deviceId',
        builder: (context, state) =>
            DeviceHomeScreen(deviceId: state.pathParameters['deviceId']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        routerProvider.overrideWithValue(router),
        initialAppAppearanceProvider.overrideWithValue(appearance),
        deviceRepositoryProvider.overrideWithValue(
          device ??
              const _StaticDeviceRepository(
                status: DeviceConnectionStatus.ready,
              ),
        ),
        deviceSnapshotProvider.overrideWith(
          snapshot ?? (ref) => Stream.value(_snapshot),
        ),
        sceneLibraryProvider.overrideWith(
          scenes ?? (ref) => Future.value(_scenes),
        ),
        sceneByIdProvider(_snapshot.activeSceneId)
            .overrideWith(activeScene ?? (ref) => Future.value(_activeScene)),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: const SmartKeychainApp(),
        ),
      ),
    ),
  );
  await _pumpFrames(tester);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

final class _StaticDeviceRepository implements DeviceRepository {
  const _StaticDeviceRepository({required this.status, this.connectResult});

  final DeviceConnectionStatus status;
  final Future<void>? connectResult;

  @override
  Future<void> connect(String deviceId) =>
      connectResult ?? Future<void>.value();

  @override
  Future<List<DeviceInfo>> discoverDevices() async => const [
    VirtualDeviceEngine.deviceInfo,
  ];

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> setBrightness(double value) async {}

  @override
  Future<void> setScene(String sceneId) async {}

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() => Stream.value(status);

  @override
  Stream<DeviceSnapshot> watchDeviceState() => Stream.value(_snapshot);
}

late final List<Scene> _scenes;
late final Scene _activeScene;

const _snapshot = DeviceSnapshot(
  deviceId: VirtualDeviceEngine.deviceId,
  connectionStatus: DeviceConnectionStatus.ready,
  batteryPercent: 78,
  brightness: 0.8,
  activeSceneId: BuiltInSceneRepository.livingEyesId,
  displayProfile: VirtualDeviceEngine.displayProfile,
  capabilities: VirtualDeviceEngine.capabilities,
);
