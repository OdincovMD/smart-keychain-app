import 'dart:typed_data';

import '../../core/result.dart';
import 'storage_failure.dart';

enum LocalStorageNamespace { userImageOriginals, userImagePreviews }

abstract interface class LocalFileStorage {
  Future<Result<String, StorageFailure>> createControlledPath({
    required LocalStorageNamespace namespace,
    required String fileName,
  });

  Future<Result<String, StorageFailure>> write({
    required LocalStorageNamespace namespace,
    required String fileName,
    required Uint8List bytes,
  });

  Future<Result<Uint8List, StorageFailure>> read(String storageKey);

  Future<Result<bool, StorageFailure>> exists(String storageKey);

  Future<Result<void, StorageFailure>> delete(String storageKey);
}
