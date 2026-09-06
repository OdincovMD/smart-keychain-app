import '../../domain/image/user_image_failure.dart';
import '../../l10n/app_localizations.dart';

String imageFailureLabel(AppLocalizations l10n, UserImageFailure failure) {
  return switch (failure) {
    UnsupportedImageFailure() => l10n.imageUnsupported,
    ImageReadFailure() => l10n.imageReadFailed,
    ImageProcessingFailure() => l10n.imageProcessingFailed,
    ImageStorageFailure() => l10n.imageStorageFailed,
    ImagePersistenceFailure() => l10n.imagePersistenceFailed,
    ImageDeviceFallbackFailure() => l10n.imageDeviceFallbackFailed,
  };
}
