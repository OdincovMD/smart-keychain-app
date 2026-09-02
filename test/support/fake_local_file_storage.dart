import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';

final class FakeLocalFileStorage implements LocalFileStorage {
  final _files = <String, Uint8List>{};

  bool failWrites = false;
  bool failReads = false;
  bool failDeletes = false;

  Set<String> get existingPaths => Set.unmodifiable(_files.keys);

  @override
  Future<Result<String, StorageFailure>> createControlledPath({
    required LocalStorageNamespace namespace,
    required String fileName,
  }) async {
    return Ok(path.posix.join(_namespacePath(namespace), fileName));
  }

  @override
  Future<Result<void, StorageFailure>> delete(String storageKey) async {
    if (failDeletes) {
      return Err(
        StorageUnavailableFailure(operation: 'delete', storageKey: storageKey),
      );
    }
    _files.remove(storageKey);
    return const Ok(null);
  }

  @override
  Future<Result<bool, StorageFailure>> exists(String storageKey) async {
    return Ok(_files.containsKey(storageKey));
  }

  @override
  Future<Result<Uint8List, StorageFailure>> read(String storageKey) async {
    if (failReads) {
      return Err(
        StorageUnavailableFailure(operation: 'read', storageKey: storageKey),
      );
    }
    final bytes = _files[storageKey];
    if (bytes == null) {
      return Err(StorageItemNotFoundFailure(storageKey: storageKey));
    }
    return Ok(Uint8List.fromList(bytes));
  }

  @override
  Future<Result<String, StorageFailure>> write({
    required LocalStorageNamespace namespace,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (failWrites) {
      return const Err(StorageUnavailableFailure(operation: 'write'));
    }
    final storageKey = path.posix.join(_namespacePath(namespace), fileName);
    _files[storageKey] = Uint8List.fromList(bytes);
    return Ok(storageKey);
  }

  static String _namespacePath(LocalStorageNamespace namespace) {
    return switch (namespace) {
      LocalStorageNamespace.userImageOriginals => 'user-content/originals',
      LocalStorageNamespace.userImagePreviews => 'user-content/previews',
    };
  }
}
