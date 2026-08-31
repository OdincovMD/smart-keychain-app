final class DeviceCapabilities {
  const DeviceCapabilities({
    required this.supportsBrightness,
    required this.reportsBattery,
    required this.supportsStaticScenes,
    required this.supportsAnimatedScenes,
  });

  final bool supportsBrightness;
  final bool reportsBattery;
  final bool supportsStaticScenes;
  final bool supportsAnimatedScenes;

  DeviceCapabilities copyWith({
    bool? supportsBrightness,
    bool? reportsBattery,
    bool? supportsStaticScenes,
    bool? supportsAnimatedScenes,
  }) {
    return DeviceCapabilities(
      supportsBrightness: supportsBrightness ?? this.supportsBrightness,
      reportsBattery: reportsBattery ?? this.reportsBattery,
      supportsStaticScenes: supportsStaticScenes ?? this.supportsStaticScenes,
      supportsAnimatedScenes:
          supportsAnimatedScenes ?? this.supportsAnimatedScenes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceCapabilities &&
          supportsBrightness == other.supportsBrightness &&
          reportsBattery == other.reportsBattery &&
          supportsStaticScenes == other.supportsStaticScenes &&
          supportsAnimatedScenes == other.supportsAnimatedScenes;

  @override
  int get hashCode => Object.hash(
    supportsBrightness,
    reportsBattery,
    supportsStaticScenes,
    supportsAnimatedScenes,
  );
}
