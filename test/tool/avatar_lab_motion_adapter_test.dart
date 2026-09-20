import 'dart:convert';
import 'dart:io';

import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_clip.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_transition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/avatar_lab_motion_adapter.dart';

const _fixturePath = 'tool/fixtures/avatar_lab_real_export_v1.avatar.json';

void main() {
  late String fixtureSource;
  late Map<String, Object?> fixture;

  setUpAll(() async {
    fixtureSource = await File(_fixturePath).readAsString();
    fixture = jsonDecode(fixtureSource) as Map<String, Object?>;
  });

  test('real Avatar Definition v1 export fixture parses', () {
    final definition = _successOf(convertAvatarLabMotion(fixtureSource));

    expect(
      definition.poses.keys,
      containsAll(['neutral', 'curious', 'flirty']),
    );
    expect(definition.clips.keys, containsAll(['curious-once', 'flirty-loop']));
    expect(
      definition.metadata['sourceFormat'],
      'bible-strong/avatar-definition',
    );
  });

  test('schema and schemaVersion are validated explicitly', () {
    for (final mutation in <void Function(Map<String, Object?>)>[
      (json) => json['schema'] = 'internal-draft',
      (json) => json['schemaVersion'] = 2,
    ]) {
      final json = _copy(fixture)..let(mutation);

      expect(
        _failureOf(convertAvatarLabMotion(jsonEncode(json))),
        isA<AvatarLabUnsupportedSchema>(),
      );
    }
  });

  test('expressions.neutral is required', () {
    final json = _copy(fixture);
    (json['expressions']! as Map<String, Object?>).remove('neutral');
    json['expressionOrder'] = ['flirty', 'curious'];

    final failure = _failureOf(convertAvatarLabMotion(jsonEncode(json)));

    expect(failure, isA<AvatarLabInvalidField>());
    expect((failure! as AvatarLabInvalidField).path, r'$.expressions.neutral');
  });

  test('nested eyes are normalised relative to neutral', () {
    final pose = _successOf(convertAvatarLabMotion(fixtureSource))
        .poses['curious']!;

    expect(pose.gazeX, closeTo(0.2, 0.000001));
    expect(pose.gazeY, closeTo(-0.2, 0.000001));
    expect(pose.leftEyelidOpen, closeTo(0.9, 0.000001));
    expect(pose.rightEyelidOpen, closeTo(0.8, 0.000001));
    expect(pose.eyeScaleX, closeTo(1.1, 0.000001));
    expect(pose.expressionTilt, closeTo(28 / 2 / 180, 0.000001));
  });

  test('expressionOrder does not control or drop pose mapping', () {
    final json = _copy(fixture)
      ..['expressionOrder'] = ['curious', 'flirty', 'neutral'];

    final definition = _successOf(convertAvatarLabMotion(jsonEncode(json)));

    expect(definition.poses.keys.toSet(), {'neutral', 'curious', 'flirty'});
  });

  test('playbackMode maps once, loop, and pingPong', () {
    final definition = _successOf(convertAvatarLabMotion(fixtureSource));
    expect(
      definition.clips['curious-once']!.playbackMode,
      EyeMotionPlaybackMode.once,
    );
    expect(
      definition.clips['flirty-loop']!.playbackMode,
      EyeMotionPlaybackMode.loop,
    );

    final json = _copy(fixture);
    final animations = json['animations']! as Map<String, Object?>;
    (animations['curious-once']! as Map<String, Object?>)['playbackMode'] =
        'pingPong';
    expect(
      _successOf(convertAvatarLabMotion(jsonEncode(json)))
          .clips['curious-once']!
          .playbackMode,
      EyeMotionPlaybackMode.pingPong,
    );
  });

  test('holdMs, transitionMs, and all transition styles map exactly', () {
    final definition = _successOf(convertAvatarLabMotion(fixtureSource));
    final curious = definition.clips['curious-once']!;
    final flirty = definition.clips['flirty-loop']!;

    expect(curious.steps.first.hold, const Duration(milliseconds: 640));
    expect(curious.steps.first.transition, const Duration(milliseconds: 220));
    expect(
      curious.steps.first.transitionStyle,
      EyeMotionTransitionStyle.emphasized,
    );
    expect(
      curious.steps.last.transitionStyle,
      EyeMotionTransitionStyle.easeInOut,
    );
    expect(
      flirty.steps.first.transitionStyle,
      EyeMotionTransitionStyle.easeOut,
    );
  });

  test('complete enabled blink object and metadata are preserved', () {
    final clip = _successOf(convertAvatarLabMotion(fixtureSource))
        .clips['curious-once']!;

    expect(clip.blinkPolicy, EyeMotionBlinkPolicy.natural);
    expect(
      clip.blinkConfiguration,
      const EyeMotionBlinkConfiguration(
        initialDelay: Duration(milliseconds: 900),
        minimumInterval: Duration(milliseconds: 2400),
        maximumInterval: Duration(milliseconds: 4600),
        duration: Duration(milliseconds: 220),
      ),
    );
    expect(clip.metadata?.label, 'Curious once');
    expect(clip.metadata?.group, 'Chrome Kiss');
  });

  test('disabled blink maps to suppress without losing authored timings', () {
    final clip = _successOf(convertAvatarLabMotion(fixtureSource))
        .clips['flirty-loop']!;

    expect(clip.blinkPolicy, EyeMotionBlinkPolicy.suppress);
    expect(
      clip.blinkConfiguration?.duration,
      const Duration(milliseconds: 240),
    );
  });

  test('missing animation expression reference is a typed failure', () {
    final json = _copy(fixture);
    final animations = json['animations']! as Map<String, Object?>;
    final curious = animations['curious-once']! as Map<String, Object?>;
    final steps = curious['steps']! as List<Object?>;
    (steps.first! as Map<String, Object?>)['expression'] = 'missing-pose';

    expect(
      _failureOf(convertAvatarLabMotion(jsonEncode(json))),
      isA<AvatarLabMissingExpressionReference>(),
    );
  });

  test('malformed export returns a typed failure', () {
    expect(
      _failureOf(convertAvatarLabMotion('{not json')),
      isA<AvatarLabMalformedJson>(),
    );
  });

  test('excessive source bytes and animation steps are rejected', () {
    final oversized = ' ' * (EyeMotionLimits.maximumJsonBytes + 1);
    expect(
      _failureOf(convertAvatarLabMotion(oversized)),
      isA<AvatarLabLimitExceeded>(),
    );

    final json = _copy(fixture);
    final animations = json['animations']! as Map<String, Object?>;
    final curious = animations['curious-once']! as Map<String, Object?>;
    curious['steps'] = List<Object?>.generate(
      129,
      (_) => {
        'expression': 'neutral',
        'holdMs': 100,
        'transitionMs': 0,
        'transition': 'smooth',
      },
    );
    expect(
      _failureOf(convertAvatarLabMotion(jsonEncode(json))),
      isA<AvatarLabLimitExceeded>(),
    );
  });

  test('converter output round-trips through the owned decoder', () {
    final converted = _successOf(convertAvatarLabMotion(fixtureSource));
    final decoded = decodeEyeMotionDefinition(converted.encode());

    expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
    expect(
      (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>).value.clips,
      converted.clips,
    );
  });

  test('CLI converts the fixture into decoder-compatible output', () async {
    final directory = await Directory.systemTemp.createTemp('avatar-lab-cli-');
    addTearDown(() => directory.delete(recursive: true));
    final output = File('${directory.path}/fixture.eye-motion.json');

    final process = await Process.run(_dartExecutable(), [
      'tool/avatar_lab_motion_converter.dart',
      _fixturePath,
      output.path,
    ], workingDirectory: Directory.current.path);

    expect(process.exitCode, 0, reason: '${process.stdout}\n${process.stderr}');
    expect(output.existsSync(), isTrue);
    expect(
      decodeEyeMotionDefinition(await output.readAsString()),
      isA<Ok<EyeMotionDefinition, EyeMotionFailure>>(),
    );
  });
}

Map<String, Object?> _copy(Map<String, Object?> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, Object?>;

EyeMotionDefinition _successOf(
  Result<EyeMotionDefinition, AvatarLabMotionFailure> result,
) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw TestFailure(
    'Expected conversion success, got ${failure.code}',
  ),
};

AvatarLabMotionFailure? _failureOf(
  Result<EyeMotionDefinition, AvatarLabMotionFailure> result,
) => switch (result) {
  Ok() => null,
  Err(:final failure) => failure,
};

extension on Map<String, Object?> {
  void let(void Function(Map<String, Object?>) mutation) => mutation(this);
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = [
    if (flutterRoot != null) '$flutterRoot/bin/cache/dart-sdk/bin/dart',
    '.fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart',
  ];
  return candidates.firstWhere((path) => File(path).existsSync());
}
