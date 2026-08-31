import '../../domain/device/device_connection_status.dart';

final class VirtualDeviceState {
  const VirtualDeviceState({
    required this.deviceId,
    required this.connectionStatus,
    required this.batteryPercent,
    required this.brightness,
    required this.activeSceneId,
  });

  final String deviceId;
  final DeviceConnectionStatus connectionStatus;
  final int batteryPercent;
  final double brightness;
  final String activeSceneId;

  VirtualDeviceState copyWith({
    String? deviceId,
    DeviceConnectionStatus? connectionStatus,
    int? batteryPercent,
    double? brightness,
    String? activeSceneId,
  }) {
    return VirtualDeviceState(
      deviceId: deviceId ?? this.deviceId,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      brightness: brightness ?? this.brightness,
      activeSceneId: activeSceneId ?? this.activeSceneId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirtualDeviceState &&
          deviceId == other.deviceId &&
          connectionStatus == other.connectionStatus &&
          batteryPercent == other.batteryPercent &&
          brightness == other.brightness &&
          activeSceneId == other.activeSceneId;

  @override
  int get hashCode => Object.hash(
    deviceId,
    connectionStatus,
    batteryPercent,
    brightness,
    activeSceneId,
  );
}
