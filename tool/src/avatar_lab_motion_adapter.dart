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

final class AvatarLabUnsupportedSchema extends AvatarLabMotionFailure {
  const AvatarLabUnsupportedSchema({
    required this.schema,
    required this.schemaVersion,
  });

  final Object? schema;
  final Object? schemaVersion;

  @override
  String get code => 'avatar_lab_motion.unsupported_schema';
}

final class AvatarLabInvalidField extends AvatarLabMotionFailure {
  const AvatarLabInvalidField(this.path);

  final String path;

  @override
  String get code => 'avatar_lab_motion.invalid_field';
}

final class AvatarLabMissingExpressionReference extends AvatarLabMotionFailure {
  const AvatarLabMissingExpressionReference({
    required this.animation,
    required this.expression,
  });

  final String animation;
  final String expression;

  @override
  String get code => 'avatar_lab_motion.missing_expression_reference';
}

final class AvatarLabLimitExceeded extends AvatarLabMotionFailure {
  const AvatarLabLimitExceeded(this.kind);

  final String kind;

  @override
  String get code => 'avatar_lab_motion.limit_exceeded';
}

/// Clean-room adapter for the public Avatar Definition v1 JSON schema.
///
/// Only nested eye geometry and animation data cross into the owned Chrome
/// Kiss format. Body geometry, colours, head, perspective, and motion fields
/// are structurally validated but deliberately not transferred.
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
        'schema',
        'schemaVersion',
        'name',
        'body',
        'colors',
        'expressions',
        'expressionOrder',
        'animations',
        'animationOrder',
        'standardAnimationSet',
      })) {
    return const Err(AvatarLabInvalidField(r'$'));
  }
  if (decoded['schema'] != 'bible-strong/avatar-definition' ||
      decoded['schemaVersion'] != 1) {
    return Err(
      AvatarLabUnsupportedSchema(
        schema: decoded['schema'],
        schemaVersion: decoded['schemaVersion'],
      ),
    );
  }
  final standardAnimationSet = decoded['standardAnimationSet'];
  if (!_optionalBoundedString(decoded['name'], 120) ||
      standardAnimationSet != null && standardAnimationSet != 1) {
    return const Err(AvatarLabInvalidField(r'$'));
  }
  if (!_validBody(decoded['body'])) {
    return const Err(AvatarLabInvalidField(r'$.body'));
  }
  if (!_validColours(decoded['colors'], requireBoth: true)) {
    return const Err(AvatarLabInvalidField(r'$.colors'));
  }

  final expressionsJson = decoded['expressions'];
  final animationsJson = decoded['animations'];
  if (expressionsJson is! Map<String, Object?> || expressionsJson.isEmpty) {
    return const Err(AvatarLabInvalidField(r'$.expressions'));
  }
  if (expressionsJson.length > EyeMotionLimits.maximumPoses) {
    return const Err(AvatarLabLimitExceeded('expressions'));
  }
  if (animationsJson is! Map<String, Object?> || animationsJson.isEmpty) {
    return const Err(AvatarLabInvalidField(r'$.animations'));
  }
  if (animationsJson.length > EyeMotionLimits.maximumClips) {
    return const Err(AvatarLabLimitExceeded('animations'));
  }
  if (!_validOrder(
        decoded['expressionOrder'],
        expressionsJson.keys.toSet(),
        maximum: 128,
        requireNonEmpty: true,
      ) ||
      !_validOrder(
        decoded['animationOrder'],
        animationsJson.keys.toSet(),
        maximum: 64,
      )) {
    return const Err(AvatarLabInvalidField(r'$.expressionOrder'));
  }

  final expressions = <String, _AvatarExpression>{};
  for (final entry in expressionsJson.entries) {
    if (!_validSemanticKey(entry.key)) {
      return Err(AvatarLabInvalidField(r'$.expressions.${entry.key}'));
    }
    final result = _readExpression(entry.value, r'$.expressions.' + entry.key);
    switch (result) {
      case Ok(:final value):
        expressions[entry.key] = value;
      case Err(:final failure):
        return Err(failure);
    }
  }
  final neutral = expressions['neutral'];
  if (neutral == null ||
      neutral.left.width == 0 ||
      neutral.left.height == 0 ||
      neutral.right.width == 0 ||
      neutral.right.height == 0) {
    return const Err(AvatarLabInvalidField(r'$.expressions.neutral'));
  }

  final poses = <String, EyeMotionPose>{};
  for (final entry in expressions.entries) {
    poses[entry.key] = entry.key == 'neutral'
        ? const EyeMotionPose(
            gazeX: 0,
            gazeY: 0,
            leftEyelidOpen: 1,
            rightEyelidOpen: 1,
            eyeScaleX: 1,
            expressionTilt: 0,
          )
        : _normalisePose(entry.value, neutral);
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
      metadata: Map.unmodifiable({
        'sourceFormat': 'bible-strong/avatar-definition',
        'sourceSchemaVersion': 1,
        'converter': 'chrome-kiss-clean-room',
        if (decoded['name'] case final String name) 'sourceName': name,
      }),
    ),
  );
}

EyeMotionPose _normalisePose(
  _AvatarExpression value,
  _AvatarExpression neutral,
) {
  final neutralHeight =
      (neutral.left.height.abs() + neutral.right.height.abs()) / 2;
  final spacingScale = math.max(1.0, neutral.spacing.abs());
  final gazeX =
      ((value.left.x - neutral.left.x) + (value.right.x - neutral.right.x)) /
      2 /
      spacingScale;
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
      !_onlyKeys(value, const {
        'head',
        'eyes',
        'perspective',
        'motion',
        'colors',
      }) ||
      !_validVectorObject(value['head'], const {'x', 'y', 'z'}) ||
      !_validPerspective(value['perspective']) ||
      !_validMotion(value['motion']) ||
      value['colors'] != null &&
          !_validColours(value['colors'], requireBoth: false)) {
    return Err(AvatarLabInvalidField(path));
  }
  final eyes = value['eyes'];
  if (eyes is! Map<String, Object?> ||
      !_onlyKeys(eyes, const {'left', 'right', 'spacing'})) {
    return Err(AvatarLabInvalidField('$path.eyes'));
  }
  final left = _readEye(eyes['left']);
  final right = _readEye(eyes['right']);
  final spacing = _boundedNumber(eyes['spacing']);
  if (left == null || right == null || spacing == null) {
    return Err(AvatarLabInvalidField('$path.eyes'));
  }
  return Ok(_AvatarExpression(left: left, right: right, spacing: spacing));
}

_AvatarEye? _readEye(Object? value) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'width', 'height', 'x', 'y', 'angle'})) {
    return null;
  }
  final width = _boundedNumber(value['width']);
  final height = _boundedNumber(value['height']);
  final x = _boundedNumber(value['x']);
  final y = _boundedNumber(value['y']);
  final angle = _boundedNumber(value['angle']);
  if (width == null ||
      height == null ||
      x == null ||
      y == null ||
      angle == null) {
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
  if (!_validSemanticKey(name) ||
      value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'playbackMode', 'steps', 'blink', 'metadata'})) {
    return Err(AvatarLabInvalidField(path));
  }
  final mode = switch (value['playbackMode']) {
    'once' => EyeMotionPlaybackMode.once,
    'loop' => EyeMotionPlaybackMode.loop,
    'pingPong' => EyeMotionPlaybackMode.pingPong,
    _ => null,
  };
  final blinkResult = _readBlink(value['blink'], '$path.blink');
  final ({
    EyeMotionBlinkPolicy policy,
    EyeMotionBlinkConfiguration configuration,
  })
  blink;
  switch (blinkResult) {
    case Ok(:final value):
      blink = value;
    case Err(:final failure):
      return Err(failure);
  }
  final metadataResult = _readMetadata(value['metadata'], '$path.metadata');
  final EyeMotionClipMetadata? metadata;
  switch (metadataResult) {
    case Ok(:final value):
      metadata = value;
    case Err(:final failure):
      return Err(failure);
  }
  final stepsJson = value['steps'];
  if (mode == null || stepsJson is! List<Object?> || stepsJson.isEmpty) {
    return Err(AvatarLabInvalidField(path));
  }
  if (stepsJson.length > 128 ||
      stepsJson.length > EyeMotionLimits.maximumStepsPerClip) {
    return Err(AvatarLabLimitExceeded('steps:$name'));
  }
  final steps = <EyeMotionStep>[];
  var total = Duration.zero;
  for (var index = 0; index < stepsJson.length; index++) {
    final raw = stepsJson[index];
    final stepPath = '$path.steps[$index]';
    if (raw is! Map<String, Object?> ||
        !_onlyKeys(raw, const {
          'expression',
          'holdMs',
          'transitionMs',
          'transition',
        })) {
      return Err(AvatarLabInvalidField(stepPath));
    }
    final pose = raw['expression'];
    if (pose is! String || !poses.containsKey(pose)) {
      return Err(
        AvatarLabMissingExpressionReference(
          animation: name,
          expression: '$pose',
        ),
      );
    }
    final hold = _milliseconds(raw['holdMs']);
    final transition = _milliseconds(raw['transitionMs']);
    final style = switch (raw['transition']) {
      'smooth' => EyeMotionTransitionStyle.easeInOut,
      'snappy' => EyeMotionTransitionStyle.easeOut,
      'spring' => EyeMotionTransitionStyle.emphasized,
      _ => null,
    };
    if (hold == null ||
        transition == null ||
        hold < const Duration(milliseconds: 100) ||
        hold > const Duration(minutes: 1) ||
        transition > const Duration(seconds: 5) ||
        hold > EyeMotionLimits.maximumStepDuration ||
        transition > EyeMotionLimits.maximumStepDuration ||
        style == null) {
      return Err(AvatarLabInvalidField(stepPath));
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
      blinkPolicy: blink.policy,
      blinkConfiguration: blink.configuration,
      metadata: metadata,
    ),
  );
}

Result<
  ({EyeMotionBlinkPolicy policy, EyeMotionBlinkConfiguration configuration}),
  AvatarLabMotionFailure
>
_readBlink(Object? value, String path) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {
        'enabled',
        'initialDelayMs',
        'minIntervalMs',
        'maxIntervalMs',
        'durationMs',
      }) ||
      value.length != 5) {
    return Err(AvatarLabInvalidField(path));
  }
  final enabled = value['enabled'];
  final initialDelay = _milliseconds(value['initialDelayMs']);
  final minimumInterval = _milliseconds(value['minIntervalMs']);
  final maximumInterval = _milliseconds(value['maxIntervalMs']);
  final duration = _milliseconds(value['durationMs']);
  if (enabled is! bool ||
      initialDelay == null ||
      minimumInterval == null ||
      maximumInterval == null ||
      duration == null ||
      initialDelay > const Duration(minutes: 1) ||
      minimumInterval < const Duration(milliseconds: 250) ||
      maximumInterval > const Duration(minutes: 2) ||
      minimumInterval > maximumInterval ||
      duration < const Duration(milliseconds: 50) ||
      duration > const Duration(seconds: 2)) {
    return Err(AvatarLabInvalidField(path));
  }
  return Ok((
    policy: enabled
        ? EyeMotionBlinkPolicy.natural
        : EyeMotionBlinkPolicy.suppress,
    configuration: EyeMotionBlinkConfiguration(
      initialDelay: initialDelay,
      minimumInterval: minimumInterval,
      maximumInterval: maximumInterval,
      duration: duration,
    ),
  ));
}

Result<EyeMotionClipMetadata?, AvatarLabMotionFailure> _readMetadata(
  Object? value,
  String path,
) {
  if (value == null) return const Ok(null);
  if (value is! Map<String, Object?> ||
      value.isEmpty ||
      !_onlyKeys(value, const {'label', 'description', 'group'})) {
    return Err(AvatarLabInvalidField(path));
  }
  final label = value['label'];
  final description = value['description'];
  final group = value['group'];
  if (!_optionalBoundedString(label, 120) ||
      !_optionalBoundedString(description, 512) ||
      !_optionalBoundedString(group, 64)) {
    return Err(AvatarLabInvalidField(path));
  }
  return Ok(
    EyeMotionClipMetadata(
      label: label as String?,
      description: description as String?,
      group: group as String?,
    ),
  );
}

bool _validBody(Object? value) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'primary', 'nodes'})) {
    return false;
  }
  final nodes = value['nodes'];
  if (!_validSurface(value['primary'], primary: true) ||
      nodes is! List<Object?> ||
      nodes.length > 16) {
    return false;
  }
  for (final node in nodes) {
    if (node is! Map<String, Object?> ||
        !_onlyKeys(node, const {'surface', 'position', 'rotation'}) ||
        !_validSurface(node['surface'], primary: false) ||
        !_validTriple(node['position'], -10000, 10000) ||
        !_validTriple(node['rotation'], -360, 360)) {
      return false;
    }
  }
  return true;
}

bool _validSurface(Object? value, {required bool primary}) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {
        'type',
        'width',
        'height',
        'depth',
        'roundness',
        'morphRoundness',
        'tipRoundness',
        'baseRoundness',
      })) {
    return false;
  }
  const nodeTypes = {
    'sphere',
    'cube',
    'capsule',
    'cylinder',
    'cone',
    'diamond',
  };
  const primaryTypes = {...nodeTypes, 'mickey', 'cursor'};
  final type = value['type'];
  if (type is! String || !(primary ? primaryTypes : nodeTypes).contains(type)) {
    return false;
  }
  for (final key in const ['width', 'height', 'depth']) {
    final number = _finiteNumber(value[key]);
    if (number == null || number < 0.001 || number > 10000) return false;
  }
  for (final key in const [
    'roundness',
    'morphRoundness',
    'tipRoundness',
    'baseRoundness',
  ]) {
    final raw = value[key];
    if (raw == null) continue;
    final number = _finiteNumber(raw);
    if (number == null || number < 0 || number > 2) return false;
  }
  return value.containsKey('roundness');
}

bool _validColours(Object? value, {required bool requireBoth}) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, const {'body', 'eyes'}) ||
      value.isEmpty) {
    return false;
  }
  if (requireBoth &&
      (!value.containsKey('body') || !value.containsKey('eyes'))) {
    return false;
  }
  return value.values.every(
    (colour) => colour is String && RegExp(r'^#[0-9a-f]{6}$').hasMatch(colour),
  );
}

bool _validVectorObject(Object? value, Set<String> keys) {
  if (value is! Map<String, Object?> ||
      !_onlyKeys(value, keys) ||
      value.length != keys.length) {
    return false;
  }
  return value.values.every((number) => _boundedNumber(number) != null);
}

bool _validPerspective(Object? value) {
  final number = _finiteNumber(value);
  return number != null && number >= 0.1 && number <= 10;
}

bool _validMotion(Object? value) =>
    value is Map<String, Object?> &&
    _onlyKeys(value, const {'eyes', 'body'}) &&
    value.length == 2 &&
    const {'none', 'microSaccades', 'shake'}.contains(value['eyes']) &&
    const {'none', 'slowDrift', 'shake'}.contains(value['body']);

bool _validOrder(
  Object? value,
  Set<String> names, {
  required int maximum,
  bool requireNonEmpty = false,
}) {
  if (value is! List<Object?> ||
      value.length > maximum ||
      requireNonEmpty && value.isEmpty) {
    return false;
  }
  final seen = <String>{};
  for (final name in value) {
    if (name is! String ||
        !_validSemanticKey(name) ||
        !names.contains(name) ||
        !seen.add(name)) {
      return false;
    }
  }
  return true;
}

bool _validTriple(Object? value, double minimum, double maximum) =>
    value is List<Object?> &&
    value.length == 3 &&
    value.every((item) {
      final number = _finiteNumber(item);
      return number != null && number >= minimum && number <= maximum;
    });

double? _boundedNumber(Object? value) {
  final number = _finiteNumber(value);
  return number != null && number >= -10000 && number <= 10000 ? number : null;
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

bool _validSemanticKey(String value) =>
    value.length <= 64 &&
    RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(value);

bool _optionalBoundedString(Object? value, int maximumLength) =>
    value == null || value is String && value.length <= maximumLength;

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
