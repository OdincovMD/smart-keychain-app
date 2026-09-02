import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_processor.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/infrastructure/image/isolated_image_processor.dart';

void main() {
  const profile = DisplayProfile(
    width: 64,
    height: 64,
    shape: DisplayShape.circle,
    aspectRatio: 1,
  );
  const processor = IsolatedImageProcessor(log: _ignoreFailure);

  test('validates, crops, resizes, and encodes a PNG preview', () async {
    final original = await File('assets/scenes/eyes_mint_static_v1.png')
        .readAsBytes();

    expect(
      await processor.validate(original),
      isA<Ok<void, UserImageFailure>>(),
    );
    final result = await processor.generatePreview(
      originalBytes: original,
      cropSpec: CropSpec(centerX: 0.4, centerY: 0.6, scale: 1.5, rotation: 0),
      targetProfile: profile,
    );

    expect(result, isA<Ok<ProcessedImage, UserImageFailure>>());
    final preview = (result as Ok<ProcessedImage, UserImageFailure>).value;
    final decoded = image.decodePng(preview.bytes);
    expect(decoded?.width, 64);
    expect(decoded?.height, 64);
  });

  test('corrupt bytes return a typed unsupported failure', () async {
    final result = await processor.validate(Uint8List.fromList([1, 2, 3]));

    expect(result, isA<Err<void, UserImageFailure>>());
    expect(
      (result as Err<void, UserImageFailure>).failure,
      isA<UnsupportedImageFailure>(),
    );
  });
}

void _ignoreFailure(String code, Object error, StackTrace stackTrace) {}
