import 'dart:convert';
import 'dart:math' as math;

import 'package:smart_keychain_app/core/failure.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_clip.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_transition.dart';

sealed class AvatarLabMotionFailure extends Failure {
  const AvatarLabMotionFailure();
}

final class AvatarLabMalformedJson extends AvatarLabMotionFailure {
  const AvatarLabMalformedJson();

  @override
  String get code => 'avatar_lab_motion.malformed_json';
}

final class AvatarLabInvalidField extends AvatarLabMotionFailure {
  const AvatarLabInvalidField(this.path);

  final String path;

  @override
  String get code => 'avatar_lab_motion.invalid_field';
}

final class AvatarLabLimitExceeded extends AvatarLabMotionFailure {
  const AvatarLabLimitExceeded(this.kind);

  final String kind;

  @override
  String get code => 'avatar_lab_motion.limit_exceeded';
}

/// Clean-room adapter for the documented Avatar Definition v1 concepts.
///
/// Supported eye fields are `width`, `height`, `x`, `y`, `angle`, and the
/// expression-level `spacing`. `body` and `colors` are deliberately ignored.
Result<EyeMotionDefinition, AvatarLabMotionFailure> convertAvatarLabMotion(
  String source,
) {
  if (utf8.encode(source).length > EyeMotionLimits.maximumJsonBytes) {
    return const Err(AvatarLabLimitExceeded('jsonBytes'));
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return const Err(AvatarLabMalformedJson());
  }
  if (decoded is! Map<String, Object?> ||
      !_onlyKeys(decoded, const {
        'version',
        'neutral',
        'expressions',
        'animations',
        'body',
        'colors',
        'metadata',
      }) ||
      decoded['version'] != 1) {
    return const Err(AvatarLabInvalidField(r'$'));
  }

  final neutralResult = _readExpression(decoded['neutral'], r'$.neutral');
  final _AvatarExpression neutral;
  switch (neutralResult) {
    case Ok(:final value):
      neutral = value;
    case Err(:final failure):
      return Err(failure);
  }
  final expressionsJson = decoded['expressions'];
  final animationsJson = decoded['animations'];
  if (expressionsJson is! Map<String, Object?> ||
      animationsJson is! Map<String, Object?> ||
      expressionsJson.length > EyeMotionLimits.maximumPoses ||
      animationsJson.length > EyeMotionLimits.maximumClips) {
    return const Err(AvatarLabInvalidField(r'$.expressions'));
  }

  final poses = <String, EyeMotionPose>{
    'neutral': const EyeMotionPose(
      gazeX: 0,
      gazeY: 0,
      leftEyelidOpen: 1,
      rightEyelidOpen: 1,
      eyeScaleX: 1,
      expressionTilt: 0,
    ),
  };
  for (final entry in expressionsJson.entries) {
    if (!_validName(entry.key)) {
      return Err(AvatarLabInvalidField(r'$.expressions.${entry.key}'));
    }
    final result = _readExpression(entry.value, r'$.expressions.' + entry.key);
    switch (result) {
      case Ok(:final value):
        poses[entry.key] = _normalisePose(value, neutral);
      case Err(:final failure):
        return Err(failure);
    }
  }

  final clips = <String, EyeMotionClip>{};
  for (final entry in animationsJson.entries) {
    final result = _readClip(entry.key, entry.value, poses);
    switch (result) {
      case Ok(:final value):
        clips[entry.key] = value;
      case Err(:final failure):
        return Err(failure);
    }
  }
  return Ok(
    EyeMotionDefinition(
      poses: Map.unmodifiable(poses),
      clips: Map.unmodifiable(clips),
      metadata: const {
        'sourceFormat': 'avatar-definition-v1',
        'converter': 'chrome-kiss-clean-room',
      },
    ),
  );
}

EyeMotionPose _normalisePose(
  _AvatarExpression value,
  _AvatarExpression neutral,
) {
  final neutralHeight = (neutral.left.height + neutral.right.height) / 2;
  final gazeX =
      ((value.left.x - neutral.left.x) + (value.right.x - neutral.right.x)) /
      2 /
      math.max(1, neutral.spacing);
  final gazeY =
      ((value.left.y - neutral.left.y) + (value.right.y - neutral.right.y)) /
      2 /
      math.max(1, neutralHeight);
  final width =
      ((value.left.width / neutral.left.width) +
          (value.right.width / neutral.right.width)) /
      2;
  final angle =
      ((value.left.angle - neutral.left.angle) -
          (value.right.angle - neutral.right.angle)) /
      2 /
      180;
  return EyeMotionPose(
    gazeX: gazeX.clamp(-1, 1),
    gazeY: gazeY.clamp(-1, 1),
    leftEyelidOpen: (value.left.height / neutral.left.height).clamp(0, 1),
    rightEyelidOpen: (value.right.height / neutral.right.height).clamp(0, 1),
    eyeScaleX: width.clamp(0.65, 1.35),
    expressionTilt: angle.clamp(-0.35, 0.35),
  );
}

Result<_AvatarExpression, AvatarLabMotionFailure> _readExpression(
  Object? value,
  String path,
) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'left', 'right', 'spacing'})) {
    return Err(AvatarLabInvalidField(path));
  }
  final left = _readEye(value['left']);
  final right = _readEye(value['right']);
  final spacing = _finiteNumber(value['spacing']);
  if (left == null || right == null || spacing == null || spacing <= 0) {
    return Err(AvatarLabInvalidField(path));
  }
  return Ok(_AvatarExpression(left: left, right: right, spacing: spacing));
}

_AvatarEye? _readEye(Object? value) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'width', 'height', 'x', 'y', 'angle'})) {
    return null;
  }
  final width = _finiteNumber(value['width']);
  final height = _finiteNumber(value['height']);
  final x = _finiteNumber(value['x']);
  final y = _finiteNumber(value['y']);
  final angle = _finiteNumber(value['angle']);
  if (width == null ||
      height == null ||
      x == null ||
      y == null ||
      angle == null ||
      width <= 0 ||
      height <= 0 ||
      [width, height, x, y, angle].any((number) => number.abs() > 10000)) {
    return null;
  }
  return _AvatarEye(width: width, height: height, x: x, y: y, angle: angle);
}

Result<EyeMotionClip, AvatarLabMotionFailure> _readClip(
  String name,
  Object? value,
  Map<String, EyeMotionPose> poses,
) {
  final path = r'$.animations.' + name;
  if (!_validName(name) ||
      value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'mode', 'blink', 'steps'})) {
    return Err(AvatarLabInvalidField(path));
  }
  final mode = switch (value['mode']) {
    'once' || 'playOnce' => EyeMotionPlaybackMode.once,
    'loop' => EyeMotionPlaybackMode.loop,
    'pingPong' => EyeMotionPlaybackMode.pingPong,
    _ => null,
  };
  final blink = switch (value['blink']) {
    true || 'natural' => EyeMotionBlinkPolicy.natural,
    false || 'suppress' => EyeMotionBlinkPolicy.suppress,
    'authored' => EyeMotionBlinkPolicy.authored,
    _ => null,
  };
  final stepsJson = value['steps'];
  if (mode == null ||
      blink == null ||
      stepsJson is! List<Object?> ||
      stepsJson.isEmpty ||
      stepsJson.length > EyeMotionLimits.maximumStepsPerClip) {
    return Err(AvatarLabInvalidField(path));
  }
  final steps = <EyeMotionStep>[];
  var total = Duration.zero;
  for (var index = 0; index < stepsJson.length; index++) {
    final raw = stepsJson[index];
    if (raw is! Map<String, Object?> ||
        !_onlyKeys(raw, const {'expression', 'hold', 'transition', 'style'})) {
      return Err(AvatarLabInvalidField('$path.steps[$index]'));
    }
    final pose = raw['expression'];
    final hold = _milliseconds(raw['hold']);
    final transition = _milliseconds(raw['transition']);
    final style = switch (raw['style']) {
      'linear' => EyeMotionTransitionStyle.linear,
      'easeIn' => EyeMotionTransitionStyle.easeIn,
      'easeOut' => EyeMotionTransitionStyle.easeOut,
      'easeInOut' => EyeMotionTransitionStyle.easeInOut,
      'spring' || 'emphasized' => EyeMotionTransitionStyle.emphasized,
      _ => null,
    };
    if (pose is! String ||
        !poses.containsKey(pose) ||
        hold == null ||
        transition == null ||
        style == null ||
        hold > EyeMotionLimits.maximumStepDuration ||
        transition > EyeMotionLimits.maximumStepDuration) {
      return Err(AvatarLabInvalidField('$path.steps[$index]'));
    }
    final step = EyeMotionStep(
      pose: pose,
      hold: hold,
      transition: transition,
      transitionStyle: style,
    );
    total += step.duration;
    steps.add(step);
  }
  if (total <= Duration.zero || total > EyeMotionLimits.maximumClipDuration) {
    return Err(AvatarLabLimitExceeded('clipDuration:$name'));
  }
  return Ok(
    EyeMotionClip(
      name: name,
      playbackMode: mode,
      steps: List.unmodifiable(steps),
      blinkPolicy: blink,
    ),
  );
}

double? _finiteNumber(Object? value) {
  if (value is! num) return null;
  final result = value.toDouble();
  return result.isFinite ? result : null;
}

Duration? _milliseconds(Object? value) {
  final number = _finiteNumber(value);
  if (number == null || number < 0 || number != number.roundToDouble()) {
    return null;
  }
  return Duration(milliseconds: number.toInt());
}

bool _onlyKeys(Map<String, Object?> value, Set<String> allowed) =>
    value.keys.every(allowed.contains);

bool _validName(String value) =>
    value.length <= 64 && RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value);

final class _AvatarExpression {
  const _AvatarExpression({
    required this.left,
    required this.right,
    required this.spacing,
  });

  final _AvatarEye left;
  final _AvatarEye right;
  final double spacing;
}

final class _AvatarEye {
  const _AvatarEye({
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.angle,
  });

  final double width;
  final double height;
  final double x;
  final double y;
  final double angle;
}
