// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import '../core/failure_logger.dart';
import '../core/result.dart';
import '../domain/device/device_failure.dart';
import '../domain/device/device_repository.dart';
import '../domain/image/user_image_asset.dart';
import '../domain/image/user_image_asset_repository.dart';
import '../domain/image/user_image_failure.dart';
import '../domain/settings/app_settings_repository.dart';
import '../domain/storage/local_file_storage.dart';
import '../infrastructure/content/user_image_scene_repository.dart';

final class DeleteUserImageScene {
  const DeleteUserImageScene({
    required UserImageAssetRepository assets,
    required LocalFileStorage storage,
    required DeviceRepository device,
    required AppSettingsRepository settings,
    required String fallbackSceneId,
    required FailureLogger log,
  }) : _assets = assets,
       _storage = storage,
       _device = device,
       _settings = settings,
       _fallbackSceneId = fallbackSceneId,
       _log = log;

  final UserImageAssetRepository _assets;
  final LocalFileStorage _storage;
  final DeviceRepository _device;
  final AppSettingsRepository _settings;
  final String _fallbackSceneId;
  final FailureLogger _log;

  Future<Result<void, UserImageFailure>> call(String sceneId) async {
    final assetId = UserImageSceneRepository.assetIdFromScene(sceneId);
    if (assetId == null || assetId.isEmpty) {
      return const Err(ImagePersistenceFailure('not_user_scene'));
    }
    final lookup = await _assets.getById(assetId);
    final UserImageAsset? asset;
    switch (lookup) {
      case Ok(:final value):
        asset = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (asset == null) return const Ok(null);

    try {
      final snapshot = await _device.watchDeviceState().first;
      if (snapshot.activeSceneId == sceneId) {
        await _device.setScene(_fallbackSceneId);
        await _settings.saveActiveSceneId(_fallbackSceneId);
      }
    } on DeviceFailure catch (error, stackTrace) {
      _log('image.delete.device_fallback', error, stackTrace);
      return const Err(ImageDeviceFallbackFailure());
    } on Exception catch (error, stackTrace) {
      _log('image.delete.settings_fallback', error, stackTrace);
      return const Err(ImagePersistenceFailure('save_fallback'));
    }

    final originalResult = await _storage.read(asset.originalStorageKey);
    final previewResult = await _storage.read(asset.previewStorageKey);
    final Uint8List originalBytes;
    switch (originalResult) {
      case Ok(:final value):
        originalBytes = value;
      case Err():
        return const Err(ImageStorageFailure('read_before_delete'));
    }
    final Uint8List previewBytes;
    switch (previewResult) {
      case Ok(:final value):
        previewBytes = value;
      case Err():
        return const Err(ImageStorageFailure('read_before_delete'));
    }

    final deleted = await _assets.delete(asset.id);
    if (deleted case Err(:final failure)) return Err(failure);

    final originalDeleted = await _storage.delete(asset.originalStorageKey);
    final previewDeleted = await _storage.delete(asset.previewStorageKey);
    final originalWasDeleted = switch (originalDeleted) {
      Ok() => true,
      Err() => false,
    };
    final previewWasDeleted = switch (previewDeleted) {
      Ok() => true,
      Err() => false,
    };
    if (!originalWasDeleted || !previewWasDeleted) {
      await _restore(asset, originalBytes, previewBytes);
      return const Err(ImageStorageFailure('delete_files'));
    }
    return const Ok(null);
  }

  Future<void> _restore(
    UserImageAsset asset,
    Uint8List originalBytes,
    Uint8List previewBytes,
  ) async {
    await _storage.write(
      namespace: LocalStorageNamespace.userImageOriginals,
      fileName: asset.originalStorageKey.split('/').last,
      bytes: originalBytes,
    );
    await _storage.write(
      namespace: LocalStorageNamespace.userImagePreviews,
      fileName: asset.previewStorageKey.split('/').last,
      bytes: previewBytes,
    );
    await _assets.save(asset);
  }
}
