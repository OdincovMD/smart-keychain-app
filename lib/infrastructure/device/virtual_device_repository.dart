import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_info.dart';
import '../../domain/device/device_repository.dart';
import '../../domain/device/device_snapshot.dart';
import 'simulator_controls.dart';
import 'virtual_device_engine.dart';

final class VirtualDeviceRepository
    implements DeviceRepository, SimulatorControls {
  VirtualDeviceRepository({VirtualDeviceEngine? engine})
    : _engine = engine ?? VirtualDeviceEngine();

  final VirtualDeviceEngine _engine;

  @override
  Duration get latency => _engine.latency;

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
    return _engine.watchState().map((_) => _engine.snapshot);
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
