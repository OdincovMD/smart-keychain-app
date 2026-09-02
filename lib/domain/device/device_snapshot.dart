import 'device_capabilities.dart';
import 'device_connection_status.dart';
import 'display_profile.dart';

final class DeviceSnapshot {
  const DeviceSnapshot({
    required this.deviceId,
    required this.connectionStatus,
    required this.batteryPercent,
    required this.brightness,
    required this.activeSceneId,
    required this.displayProfile,
    required this.capabilities,
  });

  final String deviceId;
  final DeviceConnectionStatus connectionStatus;
  final int batteryPercent;
  final double brightness;
  final String activeSceneId;
  final DisplayProfile displayProfile;
  final DeviceCapabilities capabilities;

  DeviceSnapshot copyWith({
    String? deviceId,
    DeviceConnectionStatus? connectionStatus,
    int? batteryPercent,
    double? brightness,
    String? activeSceneId,
    DisplayProfile? displayProfile,
    DeviceCapabilities? capabilities,
  }) {
    return DeviceSnapshot(
      deviceId: deviceId ?? this.deviceId,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      brightness: brightness ?? this.brightness,
      activeSceneId: activeSceneId ?? this.activeSceneId,
      displayProfile: displayProfile ?? this.displayProfile,
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
          displayProfile == other.displayProfile &&
          capabilities == other.capabilities;

  @override
  int get hashCode => Object.hash(
    deviceId,
    connectionStatus,
    batteryPercent,
    brightness,
    activeSceneId,
    displayProfile,
    capabilities,
  );
}
