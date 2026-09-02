final class AppSettings {
  const AppSettings({this.activeSceneId, this.brightness = defaultBrightness})
    : assert(brightness >= 0 && brightness <= 1);

  static const defaultBrightness = 0.8;
  static const defaults = AppSettings();

  final String? activeSceneId;
  final double brightness;

  AppSettings copyWith({String? activeSceneId, double? brightness}) {
    return AppSettings(
      activeSceneId: activeSceneId ?? this.activeSceneId,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          activeSceneId == other.activeSceneId &&
          brightness == other.brightness;

  @override
  int get hashCode => Object.hash(activeSceneId, brightness);
}
