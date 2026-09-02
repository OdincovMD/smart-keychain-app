import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';

void main() {
  test('accepts normalized coordinates and preserves value equality', () {
    final first = CropSpec(
      centerX: 0.25,
      centerY: 0.75,
      scale: 2.5,
      rotation: math.pi / 2,
    );
    final second = CropSpec(
      centerX: 0.25,
      centerY: 0.75,
      scale: 2.5,
      rotation: math.pi / 2,
    );

    expect(first, second);
    expect(first.centerX, inInclusiveRange(0, 1));
    expect(first.centerY, inInclusiveRange(0, 1));
  });

  test('rejects coordinates and transforms outside canonical ranges', () {
    expect(
      () => CropSpec(centerX: -0.01, centerY: 0.5, scale: 1, rotation: 0),
      throwsRangeError,
    );
    expect(
      () => CropSpec(centerX: 0.5, centerY: 1.01, scale: 1, rotation: 0),
      throwsRangeError,
    );
    expect(
      () => CropSpec(centerX: 0.5, centerY: 0.5, scale: 0.9, rotation: 0),
      throwsRangeError,
    );
    expect(
      () => CropSpec(
        centerX: 0.5,
        centerY: 0.5,
        scale: 1,
        rotation: math.pi + 0.01,
      ),
      throwsRangeError,
    );
  });
}
