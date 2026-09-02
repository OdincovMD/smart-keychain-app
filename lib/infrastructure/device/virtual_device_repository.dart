import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_info.dart';
import '../../domain/device/device_repository.dart';
import '../../domain/device/device_snapshot.dart';
import 'simulator_controls.dart';
import 'virtual_device_engine.dart';

final class VirtualDeviceRepository
    implements DeviceRepository, SimulatorControls {
  VirtualDeviceRepository({required VirtualDeviceEngine engine})
    // ignore: prefer_initializing_formals
    : _engine = engine;

  final VirtualDeviceEngine _engine;

  @override
  Duration get latency => _engine.latency;

  @override
  List<Duration> get latencyPresets => VirtualDeviceEngine.allowedLatencies;

  @override
  Future<List<DeviceInfo>> discoverDevices() async {
    return const [VirtualDeviceEngine.deviceInfo];
  }

  @override
  Future<void> connect(String deviceId) => _engine.connect(deviceId);

  @override
  Future<void> disconnect() => _engine.disconnect();

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() {
    return _engine.watchState().map((state) => state.connectionStatus);
  }

  @override
  Stream<DeviceSnapshot> watchDeviceState() {
    return _engine.watchState().map((state) => state.toSnapshot());
  }

  @override
  Future<void> setScene(String sceneId) => _engine.setScene(sceneId);

  @override
  Future<void> setBrightness(double value) => _engine.setBrightness(value);

  @override
  Stream<Duration> watchLatency() => _engine.watchLatency();

  @override
  void setLatency(Duration latency) => _engine.setLatency(latency);

  @override
  Future<void> dispose() => _engine.dispose();
}
