import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_clip.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_transition.dart';

void main() {
  group('EyeMotionDefinition', () {
    test('round trips the owned schema without loss', () {
      final decoded = decodeEyeMotionDefinition(
        chromeKissEyeMotionDefinition.encode(),
      );

      expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
      final value =
          (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>).value;
      expect(value.poses, chromeKissEyeMotionDefinition.poses);
      expect(value.clips, chromeKissEyeMotionDefinition.clips);
    });

    test('round trips optional blink configuration and clip metadata', () {
      const clip = EyeMotionClip(
        name: 'avatar-loop',
        playbackMode: EyeMotionPlaybackMode.loop,
        steps: [
          EyeMotionStep(
            pose: 'neutral',
            hold: Duration(milliseconds: 500),
            transition: Duration(milliseconds: 200),
            transitionStyle: EyeMotionTransitionStyle.easeInOut,
          ),
        ],
        blinkConfiguration: EyeMotionBlinkConfiguration(
          initialDelay: Duration(milliseconds: 900),
          minimumInterval: Duration(milliseconds: 2400),
          maximumInterval: Duration(milliseconds: 4600),
          duration: Duration(milliseconds: 220),
        ),
        metadata: EyeMotionClipMetadata(label: 'Avatar loop'),
      );
      const definition = EyeMotionDefinition(
        poses: {'neutral': EyeMotionPose(gazeX: 0)},
        clips: {'avatar-loop': clip},
      );

      final decoded = decodeEyeMotionDefinition(definition.encode());

      expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
      expect(
        (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>)
            .value
            .clips['avatar-loop'],
        clip,
      );
    });

    test('rejects unknown fields and non-finite numbers', () {
      final unknown = jsonDecode(
        chromeKissEyeMotionDefinition.encode(),
      ) as Map<String, Object?>;
      unknown['runtime'] = 'not-owned';
      expect(
        _failureOf(decodeEyeMotionDefinition(jsonEncode(unknown))),
        isA<EyeMotionInvalidField>(),
      );

      final invalid = jsonDecode(
        chromeKissEyeMotionDefinition.encode(),
      ) as Map<String, Object?>;
      final poses = invalid['poses']! as Map<String, Object?>;
      final rest = poses['rest']! as Map<String, Object?>;
      rest['gazeX'] = 2;
      expect(
        _failureOf(decodeEyeMotionDefinition(jsonEncode(invalid))),
        isA<EyeMotionInvalidField>(),
      );
    });

    test('rejects missing pose references with a typed failure', () {
      final invalid = jsonDecode(
        chromeKissEyeMotionDefinition.encode(),
      ) as Map<String, Object?>;
      final clips = invalid['clips']! as Map<String, Object?>;
      final idle = clips['neutral_idle']! as Map<String, Object?>;
      final steps = idle['steps']! as List<Object?>;
      (steps.first! as Map<String, Object?>)['pose'] = 'missing';

      expect(
        _failureOf(decodeEyeMotionDefinition(jsonEncode(invalid))),
        isA<EyeMotionMissingPoseReference>(),
      );
    });

    test('rejects oversized input before JSON decoding', () {
      final oversized = ' ' * (EyeMotionLimits.maximumJsonBytes + 1);
      expect(
        _failureOf(decodeEyeMotionDefinition(oversized)),
        isA<EyeMotionJsonTooLarge>(),
      );
    });

    test('rejects excessive clip counts before playback', () {
      final clips = {
        for (var index = 0; index <= EyeMotionLimits.maximumClips; index++)
          'clip_$index': {
            'mode': 'once',
            'blink': 'suppress',
            'steps': [
              {'pose': 'rest', 'hold': 1, 'transition': 0, 'style': 'linear'},
            ],
          },
      };
      final source = jsonEncode({
        'schema': EyeMotionDefinition.schema,
        'schemaVersion': EyeMotionDefinition.schemaVersion,
        'poses': {
          'rest': {'gazeX': 0},
        },
        'clips': clips,
      });

      expect(
        _failureOf(decodeEyeMotionDefinition(source)),
        isA<EyeMotionLimitExceeded>(),
      );
    });
  });
}

EyeMotionFailure? _failureOf(
  Result<EyeMotionDefinition, EyeMotionFailure> result,
) => switch (result) {
  Ok() => null,
  Err(:final failure) => failure,
};
