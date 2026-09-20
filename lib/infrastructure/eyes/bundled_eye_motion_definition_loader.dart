import 'package:flutter/services.dart';

import '../../core/failure.dart';
import '../../core/failure_logger.dart';
import '../../core/result.dart';
import '../../domain/eyes/eye_motion_definition.dart';

sealed class BundledEyeMotionFailure extends Failure {
  const BundledEyeMotionFailure();
}

final class BundledEyeMotionAssetReadFailure extends BundledEyeMotionFailure {
  const BundledEyeMotionAssetReadFailure(this.assetPath);

  final String assetPath;

  @override
  String get code => 'eye_motion.asset_read_failed';
}

final class BundledEyeMotionInvalidDefinition extends BundledEyeMotionFailure {
  const BundledEyeMotionInvalidDefinition({
    required this.assetPath,
    required this.causeCode,
  });

  final String assetPath;
  final String causeCode;

  @override
  String get code => 'eye_motion.asset_invalid_definition';
}

final class BundledEyeMotionDefinitionLoader {
  BundledEyeMotionDefinitionLoader({
    required this.bundle,
    required this.log,
    this.assetPath = productionAssetPath,
  });

  static const productionAssetPath =
      'assets/chrome_kiss/motion/chrome_kiss_production_v1.eye-motion.json';

  final AssetBundle bundle;
  final FailureLogger log;
  final String assetPath;
  Future<Result<EyeMotionDefinition, BundledEyeMotionFailure>>? _cached;

  Future<Result<EyeMotionDefinition, BundledEyeMotionFailure>> load() =>
      _cached ??= _loadOnce();

  Future<EyeMotionDefinition> loadOrFallback(
    EyeMotionDefinition fallback,
  ) async {
    return switch (await load()) {
      Ok(:final value) => value,
      Err() => fallback,
    };
  }

  Future<Result<EyeMotionDefinition, BundledEyeMotionFailure>>
  _loadOnce() async {
    final String source;
    try {
      source = await bundle.loadString(assetPath, cache: false);
    } on Object catch (error, stackTrace) {
      final failure = BundledEyeMotionAssetReadFailure(assetPath);
      log(failure.code, error, stackTrace);
      return Err<EyeMotionDefinition, BundledEyeMotionFailure>(failure);
    }

    switch (decodeEyeMotionDefinition(source)) {
      case Ok(:final value):
        return Ok<EyeMotionDefinition, BundledEyeMotionFailure>(value);
      case Err(:final failure):
        final typedFailure = BundledEyeMotionInvalidDefinition(
          assetPath: assetPath,
          causeCode: failure.code,
        );
        log(typedFailure.code, failure, StackTrace.current);
        return Err<EyeMotionDefinition, BundledEyeMotionFailure>(typedFailure);
    }
  }
}
