import 'eye_motion_definition.dart';
import 'eye_motion_library.dart';

abstract final class ChromeKissProductionEyeClips {
  static const kissIdle = 'kiss-idle';
  static const kissFlirtyScan = 'kiss-flirty-scan';

  static const values = [kissIdle, kissFlirtyScan];
}

String resolveInitialEyeMotionClip(
  EyeMotionDefinition definition, {
  String? requestedClip,
}) {
  if (requestedClip != null && definition.clips.containsKey(requestedClip)) {
    return requestedClip;
  }
  if (definition.clips.containsKey(ChromeKissProductionEyeClips.kissIdle)) {
    return ChromeKissProductionEyeClips.kissIdle;
  }
  if (definition.clips.containsKey(ChromeKissEyeClips.neutralIdle)) {
    return ChromeKissEyeClips.neutralIdle;
  }
  if (definition.clips.isNotEmpty) return definition.clips.keys.first;
  return ChromeKissEyeClips.neutralIdle;
}
