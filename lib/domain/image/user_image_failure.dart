import '../../core/failure.dart';

sealed class UserImageFailure extends Failure {
  const UserImageFailure();
}

final class UnsupportedImageFailure extends UserImageFailure {
  const UnsupportedImageFailure();

  @override
  String get code => 'image.unsupported';
}

final class ImageReadFailure extends UserImageFailure {
  const ImageReadFailure();

  @override
  String get code => 'image.read_failed';
}

final class ImageProcessingFailure extends UserImageFailure {
  const ImageProcessingFailure();

  @override
  String get code => 'image.processing_failed';
}

final class ImageStorageFailure extends UserImageFailure {
  const ImageStorageFailure(this.operation);

  final String operation;

  @override
  String get code => 'image.storage_failed';
}

final class ImagePersistenceFailure extends UserImageFailure {
  const ImagePersistenceFailure(this.operation);

  final String operation;

  @override
  String get code => 'image.persistence_failed';
}

final class ImageDeviceFallbackFailure extends UserImageFailure {
  const ImageDeviceFallbackFailure();

  @override
  String get code => 'image.device_fallback_failed';
}
