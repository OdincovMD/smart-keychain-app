import 'dart:typed_data';

import '../../core/result.dart';
import '../device/display_profile.dart';
import 'crop_spec.dart';
import 'user_image_failure.dart';

final class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

abstract interface class ImageProcessor {
  Future<Result<void, UserImageFailure>> validate(Uint8List originalBytes);

  Future<Result<ProcessedImage, UserImageFailure>> generatePreview({
    required Uint8List originalBytes,
    required CropSpec cropSpec,
    required DisplayProfile targetProfile,
  });
}
