import 'app_appearance.dart';

final class AppSettings {
  const AppSettings({
    this.activeSceneId,
    this.brightness = defaultBrightness,
    this.appearance = AppAppearance.system,
  }) : assert(brightness >= 0 && brightness <= 1);

  static const defaultBrightness = 0.8;
  static const defaults = AppSettings();

  final String? activeSceneId;
  final double brightness;
  final AppAppearance appearance;

  AppSettings copyWith({
    String? activeSceneId,
    double? brightness,
    AppAppearance? appearance,
  }) {
    return AppSettings(
      activeSceneId: activeSceneId ?? this.activeSceneId,
      brightness: brightness ?? this.brightness,
      appearance: appearance ?? this.appearance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          activeSceneId == other.activeSceneId &&
          brightness == other.brightness &&
          appearance == other.appearance;

  @override
  int get hashCode => Object.hash(activeSceneId, brightness, appearance);
}
