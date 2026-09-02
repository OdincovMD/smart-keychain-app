// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:clock/clock.dart';

import '../core/result.dart';
import '../domain/device/display_profile.dart';
import '../domain/image/crop_spec.dart';
import '../domain/image/image_picker_gateway.dart';
import '../domain/image/image_processor.dart';
import '../domain/image/user_image_asset.dart';
import '../domain/image/user_image_asset_repository.dart';
import '../domain/image/user_image_failure.dart';
import '../domain/image/user_image_id_generator.dart';
import '../domain/storage/local_file_storage.dart';

final class PendingUserImage {
  const PendingUserImage({
    required this.id,
    required this.originalStorageKey,
    required this.originalBytes,
    required this.createdAt,
  });

  final String id;
  final String originalStorageKey;
  final Uint8List originalBytes;
  final DateTime createdAt;
}

sealed class BeginUserImageImportOutcome {
  const BeginUserImageImportOutcome();
}

final class UserImageImportReady extends BeginUserImageImportOutcome {
  const UserImageImportReady(this.draft);

  final PendingUserImage draft;
}

final class UserImageImportCancelled extends BeginUserImageImportOutcome {
  const UserImageImportCancelled();
}

final class UserImageImportFailed extends BeginUserImageImportOutcome {
  const UserImageImportFailed(this.failure);

  final UserImageFailure failure;
}

final class UserImageWorkflow {
  const UserImageWorkflow({
    required Clock clock,
    required UserImageIdGenerator idGenerator,
    required ImagePickerGateway picker,
    required ImageProcessor processor,
    required LocalFileStorage storage,
    required UserImageAssetRepository assets,
  }) : _clock = clock,
       _idGenerator = idGenerator,
       _picker = picker,
       _processor = processor,
       _storage = storage,
       _assets = assets;

  final Clock _clock;
  final UserImageIdGenerator _idGenerator;
  final ImagePickerGateway _picker;
  final ImageProcessor _processor;
  final LocalFileStorage _storage;
  final UserImageAssetRepository _assets;

  Future<BeginUserImageImportOutcome> beginImport() async {
    final picked = await _picker.pickFromGallery();
    switch (picked) {
      case ImagePickCancelled():
        return const UserImageImportCancelled();
      case ImagePickFailed(:final failure):
        return UserImageImportFailed(failure);
      case ImagePicked(:final image):
        final validation = await _processor.validate(image.bytes);
        if (validation case Err(:final failure)) {
          return UserImageImportFailed(failure);
        }

        final createdAt = _clock.now().toUtc();
        final id = _idGenerator.next(createdAt);
        final original = await _storage.write(
          namespace: LocalStorageNamespace.userImageOriginals,
          fileName: '$id.${image.fileExtension}',
          bytes: image.bytes,
        );
        return switch (original) {
          Err() => const UserImageImportFailed(
            ImageStorageFailure('write_original'),
          ),
          Ok(:final value) => UserImageImportReady(
            PendingUserImage(
              id: id,
              originalStorageKey: value,
              originalBytes: Uint8List.fromList(image.bytes),
              createdAt: createdAt,
            ),
          ),
        };
    }
  }

  Future<Result<UserImageAsset, UserImageFailure>> completeImport({
    required PendingUserImage draft,
    required CropSpec cropSpec,
    required DisplayProfile targetProfile,
  }) async {
    final processed = await _processor.generatePreview(
      originalBytes: draft.originalBytes,
      cropSpec: cropSpec,
      targetProfile: targetProfile,
    );
    final ProcessedImage preview;
    switch (processed) {
      case Ok(:final value):
        preview = value;
      case Err(:final failure):
        await _storage.delete(draft.originalStorageKey);
        return Err(failure);
    }
    final storedPreview = await _storage.write(
      namespace: LocalStorageNamespace.userImagePreviews,
      fileName: '${draft.id}.png',
      bytes: preview.bytes,
    );
    final String previewStorageKey;
    switch (storedPreview) {
      case Ok(:final value):
        previewStorageKey = value;
      case Err():
        await _storage.delete(draft.originalStorageKey);
        return const Err(ImageStorageFailure('write_preview'));
    }
    final asset = UserImageAsset(
      id: draft.id,
      originalStorageKey: draft.originalStorageKey,
      previewStorageKey: previewStorageKey,
      cropSpec: cropSpec,
      createdAt: draft.createdAt,
    );
    final saved = await _assets.save(asset);
    if (saved case Err(:final failure)) {
      final previewCleanup = await _storage.delete(previewStorageKey);
      final originalCleanup = await _storage.delete(draft.originalStorageKey);
      final previewWasDeleted = switch (previewCleanup) {
        Ok() => true,
        Err() => false,
      };
      final originalWasDeleted = switch (originalCleanup) {
        Ok() => true,
        Err() => false,
      };
      if (!previewWasDeleted || !originalWasDeleted) {
        return const Err(ImageStorageFailure('cleanup'));
      }
      return Err(failure);
    }
    return Ok(asset);
  }

  Future<Result<void, UserImageFailure>> discard(PendingUserImage draft) async {
    return switch (await _storage.delete(draft.originalStorageKey)) {
      Ok() => const Ok(null),
      Err() => const Err(ImageStorageFailure('discard_original')),
    };
  }

  Future<Result<UserImageAsset, UserImageFailure>> updateCrop({
    required String assetId,
    required CropSpec cropSpec,
    required DisplayProfile targetProfile,
  }) async {
    final lookup = await _assets.getById(assetId);
    final UserImageAsset? asset;
    switch (lookup) {
      case Ok(:final value):
        asset = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (asset == null) {
      return const Err(ImagePersistenceFailure('not_found'));
    }

    final originalResult = await _storage.read(asset.originalStorageKey);
    final oldPreviewResult = await _storage.read(asset.previewStorageKey);
    final Uint8List original;
    switch (originalResult) {
      case Ok(:final value):
        original = value;
      case Err():
        return const Err(ImageStorageFailure('read_for_edit'));
    }
    final Uint8List oldPreview;
    switch (oldPreviewResult) {
      case Ok(:final value):
        oldPreview = value;
      case Err():
        return const Err(ImageStorageFailure('read_for_edit'));
    }
    final processed = await _processor.generatePreview(
      originalBytes: original,
      cropSpec: cropSpec,
      targetProfile: targetProfile,
    );
    final ProcessedImage preview;
    switch (processed) {
      case Ok(:final value):
        preview = value;
      case Err(:final failure):
        return Err(failure);
    }
    final write = await _storage.write(
      namespace: LocalStorageNamespace.userImagePreviews,
      fileName: '${asset.id}.png',
      bytes: preview.bytes,
    );
    if (write case Err()) {
      return const Err(ImageStorageFailure('update_preview'));
    }

    final updated = asset.copyWith(cropSpec: cropSpec);
    final saved = await _assets.save(updated);
    if (saved case Err(:final failure)) {
      await _storage.write(
        namespace: LocalStorageNamespace.userImagePreviews,
        fileName: '${asset.id}.png',
        bytes: oldPreview,
      );
      return Err(failure);
    }
    return Ok(updated);
  }
}
