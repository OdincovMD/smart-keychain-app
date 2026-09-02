import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/failure_logger.dart';
import '../../core/result.dart';
import '../../domain/storage/local_file_storage.dart';
import '../../domain/storage/storage_failure.dart';

final class ApplicationDocumentsFileStorage implements LocalFileStorage {
  ApplicationDocumentsFileStorage._(this._baseDirectory, this._log);

  final Directory _baseDirectory;
  final FailureLogger _log;

  static Future<ApplicationDocumentsFileStorage> open({
    required FailureLogger log,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final baseDirectory = Directory(
      path.join(documentsDirectory.path, 'smart_keychain_content'),
    );
    await baseDirectory.create(recursive: true);
    return ApplicationDocumentsFileStorage._(baseDirectory, log);
  }

  @override
  Future<Result<String, StorageFailure>> createControlledPath({
    required LocalStorageNamespace namespace,
    required String fileName,
  }) async {
    _validateSegment(fileName, 'fileName');
    final namespacePath = _namespacePath(namespace);
    try {
      await Directory(
        path.joinAll([_baseDirectory.path, ...path.posix.split(namespacePath)]),
      ).create(recursive: true);
      return Ok(path.posix.join(namespacePath, fileName));
    } on FileSystemException catch (error, stackTrace) {
      _log('storage.create', error, stackTrace);
      return const Err(StorageUnavailableFailure(operation: 'create'));
    }
  }

  @override
  Future<Result<void, StorageFailure>> delete(String storageKey) async {
    final file = _resolve(storageKey);
    try {
      if (await file.exists()) await file.delete();
      return const Ok(null);
    } on FileSystemException catch (error, stackTrace) {
      _log('storage.delete', error, stackTrace);
      return Err(
        StorageUnavailableFailure(operation: 'delete', storageKey: storageKey),
      );
    }
  }

  @override
  Future<Result<bool, StorageFailure>> exists(String storageKey) async {
    try {
      return Ok(await _resolve(storageKey).exists());
    } on FileSystemException catch (error, stackTrace) {
      _log('storage.exists', error, stackTrace);
      return Err(
        StorageUnavailableFailure(operation: 'exists', storageKey: storageKey),
      );
    }
  }

  @override
  Future<Result<Uint8List, StorageFailure>> read(String storageKey) async {
    final file = _resolve(storageKey);
    try {
      if (!await file.exists()) {
        return Err(StorageItemNotFoundFailure(storageKey: storageKey));
      }
      return Ok(await file.readAsBytes());
    } on FileSystemException catch (error, stackTrace) {
      _log('storage.read', error, stackTrace);
      return Err(
        StorageUnavailableFailure(operation: 'read', storageKey: storageKey),
      );
    }
  }

  @override
  Future<Result<String, StorageFailure>> write({
    required LocalStorageNamespace namespace,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final pathResult = await createControlledPath(
      namespace: namespace,
      fileName: fileName,
    );
    switch (pathResult) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final file = _resolve(value);
        final temporaryFile = File('${file.path}.part');
        try {
          await temporaryFile.writeAsBytes(bytes, flush: true);
          await temporaryFile.rename(file.path);
          return Ok(value);
        } on FileSystemException catch (error, stackTrace) {
          _log('storage.write', error, stackTrace);
          return Err(
            StorageUnavailableFailure(operation: 'write', storageKey: value),
          );
        }
    }
  }

  File _resolve(String relativePath) {
    final segments = path.posix.split(relativePath);
    if (segments.isEmpty) {
      throw ArgumentError.value(relativePath, 'relativePath');
    }
    for (final segment in segments) {
      _validateSegment(segment, 'relativePath');
    }
    return File(path.joinAll([_baseDirectory.path, ...segments]));
  }

  static void _validateSegment(String value, String parameterName) {
    final valid = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(value);
    if (!valid || value == '.' || value == '..') {
      throw ArgumentError.value(value, parameterName, 'Unsafe path segment.');
    }
  }

  static String _namespacePath(LocalStorageNamespace namespace) {
    return switch (namespace) {
      LocalStorageNamespace.userImageOriginals => 'user-content/originals',
      LocalStorageNamespace.userImagePreviews => 'user-content/previews',
    };
  }
}
