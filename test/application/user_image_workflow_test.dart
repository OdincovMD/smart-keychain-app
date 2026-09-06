import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/application/user_image_workflow.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/domain/image/image_picker_gateway.dart';
import 'package:smart_keychain_app/domain/image/user_image_asset.dart';
import 'package:smart_keychain_app/domain/image/user_image_failure.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';

import '../support/fake_local_file_storage.dart';
import '../support/fake_user_image_services.dart';

void main() {
  const profile = DisplayProfile(
    width: 64,
    height: 64,
    shape: DisplayShape.circle,
    aspectRatio: 1,
  );
  final now = DateTime.utc(2026, 9, 2, 12);
  final originalBytes = Uint8List.fromList([1, 2, 3, 4]);

  test(
    'retains original, creates preview, and persists metadata last',
    () async {
      final storage = FakeLocalFileStorage();
      final assets = FakeUserImageAssetRepository();
      final workflow = _workflow(
        now: now,
        originalBytes: originalBytes,
        storage: storage,
        assets: assets,
      );

      final draft = await _begin(workflow);
      final result = await workflow.completeImport(
        draft: draft,
        cropSpec: CropSpec.centered,
        targetProfile: profile,
      );

      expect(result, isA<Ok<UserImageAsset, UserImageFailure>>());
      final asset = (result as Ok<UserImageAsset, UserImageFailure>).value;
      final storedOriginal = await storage.read(asset.originalStorageKey);
      expect(
        (storedOriginal as Ok<Uint8List, StorageFailure>).value,
        originalBytes,
      );
      expect(
        await storage.exists(asset.previewStorageKey),
        isA<Ok<bool, StorageFailure>>(),
      );
      expect(assets.values, [asset]);
    },
  );

  test('cleans original and preview when metadata persistence fails', () async {
    final storage = FakeLocalFileStorage();
    final assets = FakeUserImageAssetRepository()..failSaves = true;
    final workflow = _workflow(
      now: now,
      originalBytes: originalBytes,
      storage: storage,
      assets: assets,
    );

    final draft = await _begin(workflow);
    final result = await workflow.completeImport(
      draft: draft,
      cropSpec: CropSpec.centered,
      targetProfile: profile,
    );

    expect(result, isA<Err<UserImageAsset, UserImageFailure>>());
    expect(storage.existingPaths, isEmpty);
    expect(assets.values, isEmpty);
  });

  test('picker cancellation is not an error and creates no files', () async {
    final storage = FakeLocalFileStorage();
    final workflow = UserImageWorkflow(
      clock: Clock.fixed(now),
      idGenerator: FakeUserImageIdGenerator(),
      picker: FakeImagePickerGateway(const ImagePickCancelled()),
      processor: FakeImageProcessor(),
      storage: storage,
      assets: FakeUserImageAssetRepository(),
    );

    expect(await workflow.beginImport(), isA<UserImageImportCancelled>());
    expect(storage.existingPaths, isEmpty);
  });

  test('loads the original and persisted crop for editing', () async {
    final storage = FakeLocalFileStorage();
    final crop = CropSpec(
      centerX: 0.24,
      centerY: 0.68,
      scale: 2.3,
      rotation: 0.4,
    );
    final asset = await _seedAsset(
      storage: storage,
      originalBytes: originalBytes,
      cropSpec: crop,
    );
    final workflow = _workflow(
      now: now,
      originalBytes: originalBytes,
      storage: storage,
      assets: FakeUserImageAssetRepository([asset]),
    );

    final result = await workflow.loadForEdit(asset.id);

    expect(result, isA<Ok<UserImageEditDraft, UserImageFailure>>());
    final draft = (result as Ok<UserImageEditDraft, UserImageFailure>).value;
    expect(draft.assetId, asset.id);
    expect(draft.originalBytes, originalBytes);
    expect(draft.cropSpec, crop);
  });

  test('edit regenerates preview without changing the asset id', () async {
    final storage = FakeLocalFileStorage();
    final asset = await _seedAsset(
      storage: storage,
      originalBytes: originalBytes,
      cropSpec: CropSpec.centered,
    );
    final assets = FakeUserImageAssetRepository([asset]);
    final processor = FakeImageProcessor()
      ..previewBytes = Uint8List.fromList([6, 5, 4]);
    final workflow = UserImageWorkflow(
      clock: Clock.fixed(now),
      idGenerator: FakeUserImageIdGenerator(),
      picker: FakeImagePickerGateway(const ImagePickCancelled()),
      processor: processor,
      storage: storage,
      assets: assets,
    );
    final crop = CropSpec(
      centerX: 0.7,
      centerY: 0.3,
      scale: 1.8,
      rotation: -0.2,
    );

    final result = await workflow.updateCrop(
      assetId: asset.id,
      cropSpec: crop,
      targetProfile: profile,
    );

    expect(result, isA<Ok<UserImageAsset, UserImageFailure>>());
    final updated = (result as Ok<UserImageAsset, UserImageFailure>).value;
    expect(updated.id, asset.id);
    expect(updated.cropSpec, crop);
    expect(assets.values.single, updated);
    final preview = await storage.read(asset.previewStorageKey);
    expect(
      (preview as Ok<Uint8List, StorageFailure>).value,
      processor.previewBytes,
    );
  });

  test('failed edit preserves previous metadata and valid preview', () async {
    final storage = FakeLocalFileStorage();
    final oldPreview = Uint8List.fromList([7, 7, 7]);
    final asset = await _seedAsset(
      storage: storage,
      originalBytes: originalBytes,
      previewBytes: oldPreview,
      cropSpec: CropSpec.centered,
    );
    final assets = FakeUserImageAssetRepository([asset])..failSaves = true;
    final workflow = UserImageWorkflow(
      clock: Clock.fixed(now),
      idGenerator: FakeUserImageIdGenerator(),
      picker: FakeImagePickerGateway(const ImagePickCancelled()),
      processor: FakeImageProcessor()
        ..previewBytes = Uint8List.fromList([9, 9, 9]),
      storage: storage,
      assets: assets,
    );

    final result = await workflow.updateCrop(
      assetId: asset.id,
      cropSpec: asset.cropSpec.copyWith(scale: 2),
      targetProfile: profile,
    );

    expect(result, isA<Err<UserImageAsset, UserImageFailure>>());
    expect(assets.values.single, asset);
    final preview = await storage.read(asset.previewStorageKey);
    expect((preview as Ok<Uint8List, StorageFailure>).value, oldPreview);
  });
}

Future<UserImageAsset> _seedAsset({
  required FakeLocalFileStorage storage,
  required Uint8List originalBytes,
  required CropSpec cropSpec,
  Uint8List? previewBytes,
}) async {
  final original = await storage.write(
    namespace: LocalStorageNamespace.userImageOriginals,
    fileName: 'asset-1.jpg',
    bytes: originalBytes,
  );
  final preview = await storage.write(
    namespace: LocalStorageNamespace.userImagePreviews,
    fileName: 'asset-1.png',
    bytes: previewBytes ?? Uint8List.fromList([3, 2, 1]),
  );
  return UserImageAsset(
    id: 'asset-1',
    originalStorageKey: (original as Ok<String, StorageFailure>).value,
    previewStorageKey: (preview as Ok<String, StorageFailure>).value,
    cropSpec: cropSpec,
    createdAt: DateTime.utc(2026, 9, 2),
  );
}

UserImageWorkflow _workflow({
  required DateTime now,
  required Uint8List originalBytes,
  required FakeLocalFileStorage storage,
  required FakeUserImageAssetRepository assets,
}) {
  return UserImageWorkflow(
    clock: Clock.fixed(now),
    idGenerator: FakeUserImageIdGenerator(),
    picker: FakeImagePickerGateway(
      ImagePicked(PickedImage(bytes: originalBytes, fileExtension: 'jpg')),
    ),
    processor: FakeImageProcessor(),
    storage: storage,
    assets: assets,
  );
}

Future<PendingUserImage> _begin(UserImageWorkflow workflow) async {
  final result = await workflow.beginImport();
  expect(result, isA<UserImageImportReady>());
  return (result as UserImageImportReady).draft;
}
