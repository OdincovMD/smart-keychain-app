// ignore_for_file: prefer_initializing_formals

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:path/path.dart' as path;

import '../../core/failure_logger.dart';
import '../../domain/image/image_picker_gateway.dart';
import '../../domain/image/user_image_failure.dart';

final class PlatformImagePickerGateway implements ImagePickerGateway {
  PlatformImagePickerGateway({
    required FailureLogger log,
    picker.ImagePicker? imagePicker,
  }) : _log = log,
       _imagePicker = imagePicker ?? picker.ImagePicker();

  final FailureLogger _log;
  final picker.ImagePicker _imagePicker;

  @override
  Future<ImagePickOutcome> pickFromGallery() async {
    picker.XFile? selected;
    try {
      selected = await _imagePicker.pickImage(
        source: picker.ImageSource.gallery,
      );
    } on PlatformException catch (error, stackTrace) {
      _log('image.picker.select', error, stackTrace);
      return const ImagePickFailed(ImageReadFailure());
    }
    if (selected == null) return const ImagePickCancelled();

    try {
      final bytes = await selected.readAsBytes();
      return ImagePicked(
        PickedImage(bytes: bytes, fileExtension: _safeExtension(selected.name)),
      );
    } on Exception catch (error, stackTrace) {
      _log('image.picker.read', error, stackTrace);
      return const ImagePickFailed(ImageReadFailure());
    }
  }

  static String _safeExtension(String fileName) {
    final extension = path
        .extension(fileName)
        .replaceFirst('.', '')
        .toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' => extension,
      _ => 'image',
    };
  }
}
