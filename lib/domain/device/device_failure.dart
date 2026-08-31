sealed class DeviceFailure implements Exception {
  const DeviceFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ConnectionFailure extends DeviceFailure {
  const ConnectionFailure(super.message);
}

final class DeviceUnavailableFailure extends DeviceFailure {
  const DeviceUnavailableFailure(super.message);
}

final class DeviceTimeoutFailure extends DeviceFailure {
  const DeviceTimeoutFailure(super.message);
}

final class UnsupportedFeatureFailure extends DeviceFailure {
  const UnsupportedFeatureFailure(super.message);
}

final class InvalidDeviceCommandFailure extends DeviceFailure {
  const InvalidDeviceCommandFailure(super.message);
}
