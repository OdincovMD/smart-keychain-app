import 'device_capabilities.dart';
import 'display_profile.dart';

final class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.displayProfile,
    required this.capabilities,
  });

  final String id;
  final String name;
  final DisplayProfile displayProfile;
  final DeviceCapabilities capabilities;

  DeviceInfo copyWith({
    String? id,
    String? name,
    DisplayProfile? displayProfile,
    DeviceCapabilities? capabilities,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      displayProfile: displayProfile ?? this.displayProfile,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          id == other.id &&
          name == other.name &&
          displayProfile == other.displayProfile &&
          capabilities == other.capabilities;

  @override
  int get hashCode => Object.hash(id, name, displayProfile, capabilities);
}
