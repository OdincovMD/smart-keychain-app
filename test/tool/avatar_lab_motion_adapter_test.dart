import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_clip.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_transition.dart';

import '../../tool/src/avatar_lab_motion_adapter.dart';

void main() {
  test('converts the owned minimal Avatar Definition v1 fixture', () async {
    final source = await File('tool/fixtures/avatar_definition_v1_minimal.json')
        .readAsString();

    final result = convertAvatarLabMotion(source);

    expect(result, isA<Ok<EyeMotionDefinition, AvatarLabMotionFailure>>());
    final definition =
        (result as Ok<EyeMotionDefinition, AvatarLabMotionFailure>).value;
    expect(definition.poses.keys, containsAll(['neutral', 'curious']));
    expect(definition.clips.keys, contains('curious_follow'));
    expect(definition.poses['curious']!.gazeX, greaterThan(0));
    final clip = definition.clips['curious_follow']!;
    expect(clip.playbackMode, EyeMotionPlaybackMode.once);
    expect(clip.steps.first.transitionStyle, EyeMotionTransitionStyle.easeOut);
  });

  test('ignores body and colors but rejects unknown eye fields', () {
    const source = '''
    {
      "version": 1,
      "neutral": {
        "left": {"width": 10, "height": 10, "x": -5, "y": 0, "angle": 0, "pupil": 1},
        "right": {"width": 10, "height": 10, "x": 5, "y": 0, "angle": 0},
        "spacing": 10
      },
      "expressions": {},
      "animations": {},
      "body": {},
      "colors": {}
    }
    ''';

    expect(
      _failureOf(convertAvatarLabMotion(source)),
      isA<AvatarLabInvalidField>(),
    );
  });
}

AvatarLabMotionFailure? _failureOf(
  Result<EyeMotionDefinition, AvatarLabMotionFailure> result,
) => switch (result) {
  Ok() => null,
  Err(:final failure) => failure,
};
