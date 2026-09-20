import 'dart:convert';

import '../../core/failure.dart';
import '../../core/result.dart';
import 'eye_motion_clip.dart';
import 'eye_motion_transition.dart';
import 'eye_runtime_state.dart';

abstract final class EyeMotionLimits {
  static const maximumJsonBytes = 256 * 1024;
  static const maximumPoses = 64;
  static const maximumClips = 32;
  static const maximumStepsPerClip = 256;
  static const maximumStepDuration = Duration(seconds: 10);
  static const maximumClipDuration = Duration(minutes: 1);
}

sealed class EyeMotionFailure extends Failure {
  const EyeMotionFailure();
}

final class EyeMotionJsonTooLarge extends EyeMotionFailure {
  const EyeMotionJsonTooLarge(this.actualBytes);

  final int actualBytes;

  @override
  String get code => 'eye_motion.json_too_large';
}

final class EyeMotionMalformedJson extends EyeMotionFailure {
  const EyeMotionMalformedJson();

  @override
  String get code => 'eye_motion.malformed_json';
}

final class EyeMotionUnsupportedSchema extends EyeMotionFailure {
  const EyeMotionUnsupportedSchema({
    required this.schema,
    required this.schemaVersion,
  });

  final Object? schema;
  final Object? schemaVersion;

  @override
  String get code => 'eye_motion.unsupported_schema';
}

final class EyeMotionInvalidField extends EyeMotionFailure {
  const EyeMotionInvalidField(this.path);

  final String path;

  @override
  String get code => 'eye_motion.invalid_field';
}

final class EyeMotionLimitExceeded extends EyeMotionFailure {
  const EyeMotionLimitExceeded({required this.kind, required this.maximum});

  final String kind;
  final int maximum;

  @override
  String get code => 'eye_motion.limit_exceeded';
}

final class EyeMotionMissingPoseReference extends EyeMotionFailure {
  const EyeMotionMissingPoseReference({required this.clip, required this.pose});

  final String clip;
  final String pose;

  @override
  String get code => 'eye_motion.missing_pose_reference';
}

final class EyeMotionPose {
  const EyeMotionPose({
    this.gazeX,
    this.gazeY,
    this.leftEyelidOpen,
    this.rightEyelidOpen,
    this.pupilScale,
    this.eyeScaleX,
    this.eyeScaleY,
    this.expressionTilt,
    this.verticalOffset,
  });

  final double? gazeX;
  final double? gazeY;
  final double? leftEyelidOpen;
  final double? rightEyelidOpen;
  final double? pupilScale;
  final double? eyeScaleX;
  final double? eyeScaleY;
  final double? expressionTilt;
  final double? verticalOffset;

  EyeRuntimeState applyTo(EyeRuntimeState base) {
    return base.copyWith(
      gazeX: gazeX,
      gazeY: gazeY,
      leftEyelidOpen: leftEyelidOpen,
      rightEyelidOpen: rightEyelidOpen,
      pupilScale: pupilScale,
      eyeScaleX: eyeScaleX,
      eyeScaleY: eyeScaleY,
      expressionTilt: expressionTilt,
      verticalOffset: verticalOffset,
    );
  }

  Map<String, Object?> toJson() => {
    if (gazeX != null) 'gazeX': gazeX,
    if (gazeY != null) 'gazeY': gazeY,
    if (leftEyelidOpen != null) 'leftEyelidOpen': leftEyelidOpen,
    if (rightEyelidOpen != null) 'rightEyelidOpen': rightEyelidOpen,
    if (pupilScale != null) 'pupilScale': pupilScale,
    if (eyeScaleX != null) 'eyeScaleX': eyeScaleX,
    if (eyeScaleY != null) 'eyeScaleY': eyeScaleY,
    if (expressionTilt != null) 'expressionTilt': expressionTilt,
    if (verticalOffset != null) 'verticalOffset': verticalOffset,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeMotionPose &&
          gazeX == other.gazeX &&
          gazeY == other.gazeY &&
          leftEyelidOpen == other.leftEyelidOpen &&
          rightEyelidOpen == other.rightEyelidOpen &&
          pupilScale == other.pupilScale &&
          eyeScaleX == other.eyeScaleX &&
          eyeScaleY == other.eyeScaleY &&
          expressionTilt == other.expressionTilt &&
          verticalOffset == other.verticalOffset;

  @override
  int get hashCode => Object.hash(
    gazeX,
    gazeY,
    leftEyelidOpen,
    rightEyelidOpen,
    pupilScale,
    eyeScaleX,
    eyeScaleY,
    expressionTilt,
    verticalOffset,
  );
}

final class EyeMotionDefinition {
  const EyeMotionDefinition({
    required this.poses,
    required this.clips,
    this.metadata = const {},
  });

  static const schema = 'chrome-kiss/eye-motion';
  static const schemaVersion = 1;

  final Map<String, EyeMotionPose> poses;
  final Map<String, EyeMotionClip> clips;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'schemaVersion': schemaVersion,
    'poses': poses.map((name, pose) => MapEntry(name, pose.toJson())),
    'clips': clips.map(
      (name, clip) => MapEntry(name, {
        'mode': clip.playbackMode.name,
        'blink': clip.blinkPolicy.name,
        'steps': [
          for (final step in clip.steps)
            {
              'pose': step.pose,
              'hold': step.hold.inMilliseconds,
              'transition': step.transition.inMilliseconds,
              'style': step.transitionStyle.name,
            },
        ],
      }),
    ),
    if (metadata.isNotEmpty) 'metadata': metadata,
  };

  String encode({bool pretty = true}) =>
      (pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder())
          .convert(toJson());
}

Result<EyeMotionDefinition, EyeMotionFailure> decodeEyeMotionDefinition(
  String source,
) {
  final byteCount = utf8.encode(source).length;
  if (byteCount > EyeMotionLimits.maximumJsonBytes) {
    return Err(EyeMotionJsonTooLarge(byteCount));
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return const Err(EyeMotionMalformedJson());
  }
  if (decoded is! Map<String, Object?>) {
    return const Err(EyeMotionInvalidField(r'$'));
  }
  if (!_onlyKeys(decoded, const {
    'schema',
    'schemaVersion',
    'poses',
    'clips',
    'metadata',
  })) {
    return const Err(EyeMotionInvalidField(r'$'));
  }
  if (decoded['schema'] != EyeMotionDefinition.schema ||
      decoded['schemaVersion'] != EyeMotionDefinition.schemaVersion) {
    return Err(
      EyeMotionUnsupportedSchema(
        schema: decoded['schema'],
        schemaVersion: decoded['schemaVersion'],
      ),
    );
  }

  final posesJson = decoded['poses'];
  final clipsJson = decoded['clips'];
  if (posesJson is! Map<String, Object?>) {
    return const Err(EyeMotionInvalidField(r'$.poses'));
  }
  if (clipsJson is! Map<String, Object?>) {
    return const Err(EyeMotionInvalidField(r'$.clips'));
  }
  if (posesJson.isEmpty || clipsJson.isEmpty) {
    return const Err(EyeMotionInvalidField(r'$'));
  }
  if (posesJson.length > EyeMotionLimits.maximumPoses) {
    return const Err(
      EyeMotionLimitExceeded(
        kind: 'poses',
        maximum: EyeMotionLimits.maximumPoses,
      ),
    );
  }
  if (clipsJson.length > EyeMotionLimits.maximumClips) {
    return const Err(
      EyeMotionLimitExceeded(
        kind: 'clips',
        maximum: EyeMotionLimits.maximumClips,
      ),
    );
  }

  final poses = <String, EyeMotionPose>{};
  for (final entry in posesJson.entries) {
    final parsed = _parsePose(entry.key, entry.value);
    switch (parsed) {
      case Ok(:final value):
        poses[entry.key] = value;
      case Err(:final failure):
        return Err(failure);
    }
  }

  final clips = <String, EyeMotionClip>{};
  for (final entry in clipsJson.entries) {
    final parsed = _parseClip(entry.key, entry.value, poses);
    switch (parsed) {
      case Ok(:final value):
        clips[entry.key] = value;
      case Err(:final failure):
        return Err(failure);
    }
  }

  final metadata = decoded['metadata'];
  if (metadata != null && metadata is! Map<String, Object?>) {
    return const Err(EyeMotionInvalidField(r'$.metadata'));
  }
  return Ok(
    EyeMotionDefinition(
      poses: Map.unmodifiable(poses),
      clips: Map.unmodifiable(clips),
      metadata: Map.unmodifiable(
        metadata is Map<String, Object?> ? metadata : const <String, Object?>{},
      ),
    ),
  );
}

Result<EyeMotionPose, EyeMotionFailure> _parsePose(String name, Object? value) {
  if (!_validName(name) || value is! Map<String, Object?>) {
    return Err(EyeMotionInvalidField(r'$.poses.' + name));
  }
  const keys = {
    'gazeX',
    'gazeY',
    'leftEyelidOpen',
    'rightEyelidOpen',
    'pupilScale',
    'eyeScaleX',
    'eyeScaleY',
    'expressionTilt',
    'verticalOffset',
  };
  if (!_onlyKeys(value, keys) || value.isEmpty) {
    return Err(EyeMotionInvalidField(r'$.poses.' + name));
  }
  final gazeX = _bounded(value, 'gazeX', -1, 1);
  final gazeY = _bounded(value, 'gazeY', -1, 1);
  final leftOpen = _bounded(value, 'leftEyelidOpen', 0, 1);
  final rightOpen = _bounded(value, 'rightEyelidOpen', 0, 1);
  final pupil = _bounded(value, 'pupilScale', 0.55, 1.35);
  final scaleX = _bounded(value, 'eyeScaleX', 0.65, 1.35);
  final scaleY = _bounded(value, 'eyeScaleY', 0.65, 1.35);
  final tilt = _bounded(value, 'expressionTilt', -0.35, 0.35);
  final offset = _bounded(value, 'verticalOffset', -0.25, 0.25);
  if ([
    gazeX,
    gazeY,
    leftOpen,
    rightOpen,
    pupil,
    scaleX,
    scaleY,
    tilt,
    offset,
  ].any((field) => field.invalid)) {
    return Err(EyeMotionInvalidField(r'$.poses.' + name));
  }
  return Ok(
    EyeMotionPose(
      gazeX: gazeX.value,
      gazeY: gazeY.value,
      leftEyelidOpen: leftOpen.value,
      rightEyelidOpen: rightOpen.value,
      pupilScale: pupil.value,
      eyeScaleX: scaleX.value,
      eyeScaleY: scaleY.value,
      expressionTilt: tilt.value,
      verticalOffset: offset.value,
    ),
  );
}

Result<EyeMotionClip, EyeMotionFailure> _parseClip(
  String name,
  Object? value,
  Map<String, EyeMotionPose> poses,
) {
  if (!_validName(name) ||
      value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'mode', 'blink', 'steps'})) {
    return Err(EyeMotionInvalidField(r'$.clips.' + name));
  }
  final playback = _enumByName(EyeMotionPlaybackMode.values, value['mode']);
  final blink = _enumByName(
    EyeMotionBlinkPolicy.values,
    value['blink'] ?? EyeMotionBlinkPolicy.natural.name,
  );
  final stepsJson = value['steps'];
  if (playback == null || blink == null || stepsJson is! List<Object?>) {
    return Err(EyeMotionInvalidField(r'$.clips.' + name));
  }
  if (stepsJson.isEmpty ||
      stepsJson.length > EyeMotionLimits.maximumStepsPerClip) {
    return Err(
      EyeMotionLimitExceeded(
        kind: 'steps:$name',
        maximum: EyeMotionLimits.maximumStepsPerClip,
      ),
    );
  }

  final steps = <EyeMotionStep>[];
  var total = Duration.zero;
  for (var index = 0; index < stepsJson.length; index++) {
    final raw = stepsJson[index];
    final path =
        r'$.clips.'
        '$name.steps[$index]';
    if (raw is! Map<String, Object?> ||
        !_onlyKeys(raw, const {'pose', 'hold', 'transition', 'style'})) {
      return Err(EyeMotionInvalidField(path));
    }
    final pose = raw['pose'];
    if (pose is! String || !poses.containsKey(pose)) {
      return Err(EyeMotionMissingPoseReference(clip: name, pose: '$pose'));
    }
    final hold = _duration(raw['hold']);
    final transition = _duration(raw['transition']);
    final style = _enumByName(EyeMotionTransitionStyle.values, raw['style']);
    if (hold == null || transition == null || style == null) {
      return Err(EyeMotionInvalidField(path));
    }
    if (hold > EyeMotionLimits.maximumStepDuration ||
        transition > EyeMotionLimits.maximumStepDuration) {
      return Err(
        EyeMotionLimitExceeded(
          kind: 'duration:$name',
          maximum: EyeMotionLimits.maximumStepDuration.inMilliseconds,
        ),
      );
    }
    final step = EyeMotionStep(
      pose: pose,
      hold: hold,
      transition: transition,
      transitionStyle: style,
    );
    steps.add(step);
    total += step.duration;
  }
  if (total == Duration.zero || total > EyeMotionLimits.maximumClipDuration) {
    return Err(
      EyeMotionLimitExceeded(
        kind: 'clipDuration:$name',
        maximum: EyeMotionLimits.maximumClipDuration.inMilliseconds,
      ),
    );
  }
  return Ok(
    EyeMotionClip(
      name: name,
      playbackMode: playback,
      steps: List.unmodifiable(steps),
      blinkPolicy: blink,
    ),
  );
}

({double? value, bool invalid}) _bounded(
  Map<String, Object?> object,
  String key,
  double minimum,
  double maximum,
) {
  final raw = object[key];
  if (raw == null) return (value: null, invalid: false);
  if (raw is! num) return (value: null, invalid: true);
  final value = raw.toDouble();
  return (
    value: value,
    invalid: !value.isFinite || value < minimum || value > maximum,
  );
}

Duration? _duration(Object? value) {
  if (value is! int || value < 0) return null;
  return Duration(milliseconds: value);
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

bool _onlyKeys(Map<String, Object?> object, Set<String> allowed) =>
    object.keys.every(allowed.contains);

bool _validName(String value) =>
    RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(value);
