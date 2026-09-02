// ignore_for_file: prefer_initializing_formals

import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

import '../../core/failure_logger.dart';
import '../../core/result.dart';
import '../../domain/device/display_profile.dart';
import '../../domain/image/crop_spec.dart';
import '../../domain/image/image_processor.dart';
import '../../domain/image/user_image_failure.dart';

final class IsolatedImageProcessor implements ImageProcessor {
  const IsolatedImageProcessor({required FailureLogger log}) : _log = log;

  final FailureLogger _log;

  @override
  Future<Result<ProcessedImage, UserImageFailure>> generatePreview({
    required Uint8List originalBytes,
    required CropSpec cropSpec,
    required DisplayProfile targetProfile,
  }) async {
    try {
      final bytes = await Isolate.run(
        () => _generatePreview(
          originalBytes,
          cropSpec.centerX,
          cropSpec.centerY,
          cropSpec.scale,
          cropSpec.rotation,
          targetProfile.width,
          targetProfile.height,
          targetProfile.shape == DisplayShape.circle,
        ),
      );
      if (bytes == null) return const Err(UnsupportedImageFailure());
      return Ok(
        ProcessedImage(
          bytes: bytes,
          width: targetProfile.width,
          height: targetProfile.height,
        ),
      );
    } on Exception catch (error, stackTrace) {
      _log('image.processor.preview', error, stackTrace);
      return const Err(ImageProcessingFailure());
    }
  }

  @override
  Future<Result<void, UserImageFailure>> validate(
    Uint8List originalBytes,
  ) async {
    try {
      final valid = await Isolate.run(() => _isSupported(originalBytes));
      return valid ? const Ok(null) : const Err(UnsupportedImageFailure());
    } on Exception catch (error, stackTrace) {
      _log('image.processor.validate', error, stackTrace);
      return const Err(ImageProcessingFailure());
    }
  }
}

bool _isSupported(Uint8List bytes) {
  final decoded = _decodeSupported(bytes);
  return decoded != null && decoded.numFrames == 1;
}

Uint8List? _generatePreview(
  Uint8List bytes,
  double centerX,
  double centerY,
  double scale,
  double rotation,
  int targetWidth,
  int targetHeight,
  bool circular,
) {
  final decoded = _decodeSupported(bytes);
  if (decoded == null || decoded.numFrames != 1) return null;

  var source = image.bakeOrientation(decoded);
  if (rotation != 0) {
    source = image.copyRotate(
      source,
      angle: rotation * 180 / math.pi,
      interpolation: image.Interpolation.linear,
    );
  }

  final targetAspect = targetWidth / targetHeight;
  final sourceAspect = source.width / source.height;
  final baseWidth = sourceAspect > targetAspect
      ? source.height * targetAspect
      : source.width.toDouble();
  final baseHeight = sourceAspect > targetAspect
      ? source.height.toDouble()
      : source.width / targetAspect;
  final cropWidth = math.max(1, (baseWidth / scale).round());
  final cropHeight = math.max(1, (baseHeight / scale).round());
  final requestedX = (centerX * source.width - cropWidth / 2).round();
  final requestedY = (centerY * source.height - cropHeight / 2).round();
  final cropX = requestedX.clamp(0, source.width - cropWidth).toInt();
  final cropY = requestedY.clamp(0, source.height - cropHeight).toInt();
  final cropped = image.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: cropWidth,
    height: cropHeight,
  );
  var resized = image.copyResize(
    cropped,
    width: targetWidth,
    height: targetHeight,
    interpolation: image.Interpolation.linear,
  );
  if (circular) resized = image.copyCropCircle(resized);
  return image.encodePng(resized);
}

image.Image? _decodeSupported(Uint8List bytes) {
  try {
    return image.decodeImage(bytes);
  } on RangeError {
    // Some decoders probe short corrupt buffers before reporting no match.
    return null;
  } on image.ImageException {
    return null;
  }
}
