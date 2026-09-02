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
