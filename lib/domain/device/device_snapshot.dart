import 'device_capabilities.dart';
import 'device_connection_status.dart';

final class DeviceSnapshot {
  const DeviceSnapshot({
    required this.deviceId,
    required this.connectionStatus,
    required this.batteryPercent,
    required this.brightness,
    required this.activeSceneId,
    required this.capabilities,
  });

  final String deviceId;
  final DeviceConnectionStatus connectionStatus;
  final int batteryPercent;
  final double brightness;
  final String activeSceneId;
  final DeviceCapabilities capabilities;

  DeviceSnapshot copyWith({
    String? deviceId,
    DeviceConnectionStatus? connectionStatus,
    int? batteryPercent,
    double? brightness,
    String? activeSceneId,
    DeviceCapabilities? capabilities,
  }) {
    return DeviceSnapshot(
      deviceId: deviceId ?? this.deviceId,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      brightness: brightness ?? this.brightness,
      activeSceneId: activeSceneId ?? this.activeSceneId,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSnapshot &&
          deviceId == other.deviceId &&
          connectionStatus == other.connectionStatus &&
          batteryPercent == other.batteryPercent &&
          brightness == other.brightness &&
          activeSceneId == other.activeSceneId &&
          capabilities == other.capabilities;

  @override
  int get hashCode => Object.hash(
    deviceId,
    connectionStatus,
    batteryPercent,
    brightness,
    activeSceneId,
    capabilities,
  );
}
