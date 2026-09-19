import 'dart:typed_data';

import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/image_processor.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset_repository.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/domain/image/user_image_id_generator.dart';

final class FakeUserImageAssetRepository implements UserImageAssetRepository {
  FakeUserImageAssetRepository([Iterable<UserImageAsset> initial = const []]) {
    for (final asset in initial) {
      _assets[asset.id] = asset;
    }
  }

  final _assets = <String, UserImageAsset>{};

  bool failReads = false;
  bool failSaves = false;
  bool failDeletes = false;

  List<UserImageAsset> get values => List.unmodifiable(_assets.values);

  @override
  Future<Result<void, UserImageFailure>> delete(String id) async {
    if (failDeletes) {
      return const Err(ImagePersistenceFailure('delete'));
    }
    _assets.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<List<UserImageAsset>, UserImageFailure>> getAll() async {
    if (failReads) return const Err(ImagePersistenceFailure('list'));
    return Ok(List.unmodifiable(_assets.values));
  }

  @override
  Future<Result<UserImageAsset?, UserImageFailure>> getById(String id) async {
    if (failReads) return const Err(ImagePersistenceFailure('read'));
    return Ok(_assets[id]);
  }

  @override
  Future<Result<void, UserImageFailure>> save(UserImageAsset asset) async {
    if (failSaves) return const Err(ImagePersistenceFailure('save'));
    _assets[asset.id] = asset;
    return const Ok(null);
  }
}

final class FakeImagePickerGateway implements ImagePickerGateway {
  FakeImagePickerGateway(this.outcome);

  ImagePickOutcome outcome;
  int callCount = 0;

  @override
  Future<ImagePickOutcome> pickFromGallery() async {
    callCount++;
    return outcome;
  }
}

final class FakeImageProcessor implements ImageProcessor {
  bool failValidation = false;
  bool failProcessing = false;
  Uint8List previewBytes = Uint8List.fromList([9, 8, 7]);

  @override
  Future<Result<ProcessedImage, UserImageFailure>> generatePreview({
    required Uint8List originalBytes,
    required CropSpec cropSpec,
    required DisplayProfile targetProfile,
  }) async {
    if (failProcessing) return const Err(ImageProcessingFailure());
    return Ok(
      ProcessedImage(
        bytes: Uint8List.fromList(previewBytes),
        width: targetProfile.width,
        height: targetProfile.height,
      ),
    );
  }

  @override
  Future<Result<void, UserImageFailure>> validate(
    Uint8List originalBytes,
  ) async {
    return failValidation
        ? const Err(UnsupportedImageFailure())
        : const Ok(null);
  }
}

final class FakeUserImageIdGenerator implements UserImageIdGenerator {
  FakeUserImageIdGenerator([this.value = 'asset-1']);

  final String value;

  @override
  String next(DateTime createdAt) => value;
}
