import 'device_connection_status.dart';
import 'device_info.dart';
import 'device_snapshot.dart';

abstract interface class DeviceRepository {
  Future<List<DeviceInfo>> discoverDevices();

  Future<void> connect(String deviceId);

  Future<void> disconnect();

  Stream<DeviceConnectionStatus> watchConnectionState();

  Stream<DeviceSnapshot> watchDeviceState();

  Future<void> setScene(String sceneId);

  Future<void> setBrightness(double value);

  Future<void> dispose();
}
