import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/device_discovery/device_discovery_screen.dart';
import '../features/device_home/device_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: DeviceDiscoveryScreen.routePath,
    routes: [
      GoRoute(
        path: DeviceDiscoveryScreen.routePath,
        builder: (context, state) => const DeviceDiscoveryScreen(),
      ),
      GoRoute(
        path: '/device/:deviceId',
        builder: (context, state) =>
            DeviceHomeScreen(deviceId: state.pathParameters['deviceId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
