import 'dart:typed_data';

import 'user_image_failure.dart';

final class PickedImage {
  const PickedImage({required this.bytes, required this.fileExtension});

  final Uint8List bytes;
  final String fileExtension;
}

sealed class ImagePickOutcome {
  const ImagePickOutcome();
}

final class ImagePicked extends ImagePickOutcome {
  const ImagePicked(this.image);

  final PickedImage image;
}

final class ImagePickCancelled extends ImagePickOutcome {
  const ImagePickCancelled();
}

final class ImagePickFailed extends ImagePickOutcome {
  const ImagePickFailed(this.failure);

  final UserImageFailure failure;
}

abstract interface class ImagePickerGateway {
  Future<ImagePickOutcome> pickFromGallery();
}
