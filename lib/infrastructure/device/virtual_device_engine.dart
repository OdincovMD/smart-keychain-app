import 'dart:async';

import '../../domain/device/device_capabilities.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_failure.dart';
import '../../domain/device/device_info.dart';
import '../../domain/device/device_snapshot.dart';
import '../../domain/device/display_profile.dart';
import '../content/built_in_scene_catalog.dart';
import 'virtual_device_state.dart';

final class VirtualDeviceEngine {
  // The public parameter intentionally differs from the private mutable field.
  VirtualDeviceEngine({Duration latency = const Duration(milliseconds: 300)})
    // ignore: prefer_initializing_formals
    : _latency = latency;

  static const deviceId = 'demo-keychain-v1';
  static const displayProfile = DisplayProfile(
    width: 240,
    height: 240,
    shape: DisplayShape.circle,
    aspectRatio: 1,
  );
  static const capabilities = DeviceCapabilities(
    supportsBrightness: true,
    reportsBattery: true,
    supportsStaticScenes: true,
    supportsAnimatedScenes: false,
  );
  static const deviceInfo = DeviceInfo(
    id: deviceId,
    name: 'Demo Keychain',
    displayProfile: displayProfile,
    capabilities: capabilities,
  );
  static const allowedLatencies = <Duration>[
    Duration.zero,
    Duration(milliseconds: 100),
    Duration(milliseconds: 300),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 3000),
  ];

  final _stateController = StreamController<VirtualDeviceState>.broadcast(
    sync: true,
  );
  final _latencyController = StreamController<Duration>.broadcast(sync: true);

  VirtualDeviceState _state = const VirtualDeviceState(
    deviceId: deviceId,
    connectionStatus: DeviceConnectionStatus.disconnected,
    batteryPercent: 78,
    brightness: 0.8,
    activeSceneId: BuiltInSceneCatalog.mintEyesId,
  );
  Duration _latency;
  Future<void> _commandQueue = Future<void>.value();

  VirtualDeviceState get state => _state;
  Duration get latency => _latency;

  DeviceSnapshot get snapshot => DeviceSnapshot(
    deviceId: _state.deviceId,
    connectionStatus: _state.connectionStatus,
    batteryPercent: _state.batteryPercent,
    brightness: _state.brightness,
    activeSceneId: _state.activeSceneId,
    capabilities: capabilities,
  );

  Stream<VirtualDeviceState> watchState() async* {
    yield _state;
    yield* _stateController.stream;
  }

  Stream<Duration> watchLatency() async* {
    yield _latency;
    yield* _latencyController.stream;
  }

  Future<void> connect(String requestedDeviceId) {
    return _serialize(() async {
      if (requestedDeviceId != deviceId) {
        throw const DeviceUnavailableFailure('Unknown virtual device.');
      }
      if (_state.connectionStatus == DeviceConnectionStatus.ready) return;

      _emit(
        _state.copyWith(connectionStatus: DeviceConnectionStatus.connecting),
      );
      await _wait();
      _emit(
        _state.copyWith(connectionStatus: DeviceConnectionStatus.discovering),
      );
      await _wait();
      _emit(_state.copyWith(connectionStatus: DeviceConnectionStatus.ready));
    });
  }

  Future<void> disconnect() {
    return _serialize(() async {
      if (_state.connectionStatus == DeviceConnectionStatus.disconnected) {
        return;
      }
      _emit(
        _state.copyWith(connectionStatus: DeviceConnectionStatus.disconnecting),
      );
      await _wait();
      _emit(
        _state.copyWith(connectionStatus: DeviceConnectionStatus.disconnected),
      );
    });
  }

  Future<void> setScene(String sceneId) async {
    _requireReady();
    if (BuiltInSceneCatalog.byId(sceneId) == null) {
      throw const UnsupportedFeatureFailure('Unknown scene.');
    }
    await _serialize(() async {
      if (_state.activeSceneId == sceneId) return;
      await _wait();
      _emit(_state.copyWith(activeSceneId: sceneId));
    });
  }

  Future<void> setBrightness(double value) async {
    if (!value.isFinite || value < 0 || value > 1) {
      throw const InvalidDeviceCommandFailure(
        'Brightness must be between 0.0 and 1.0.',
      );
    }
    _requireReady();
    await _serialize(() async {
      if (_state.brightness == value) return;
      await _wait();
      _emit(_state.copyWith(brightness: value));
    });
  }

  void setLatency(Duration value) {
    if (!allowedLatencies.contains(value)) {
      throw const InvalidDeviceCommandFailure('Unsupported latency preset.');
    }
    if (_latency == value) return;
    _latency = value;
    _latencyController.add(value);
  }

  Future<void> dispose() async {
    await _stateController.close();
    await _latencyController.close();
  }

  Future<void> _serialize(Future<void> Function() command) {
    final result = _commandQueue.then((_) => command());
    _commandQueue = result.catchError((Object _) {});
    return result;
  }

  Future<void> _wait() => Future<void>.delayed(_latency);

  void _requireReady() {
    if (_state.connectionStatus != DeviceConnectionStatus.ready) {
      throw const DeviceUnavailableFailure('Device is not ready.');
    }
  }

  void _emit(VirtualDeviceState nextState) {
    _state = nextState;
    _stateController.add(nextState);
  }
}
