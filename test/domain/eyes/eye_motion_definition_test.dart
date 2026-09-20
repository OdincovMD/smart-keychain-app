import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';

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
