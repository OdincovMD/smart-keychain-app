import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/storage/local_file_storage.dart';
import 'package:smart_keychain_app/domain/storage/storage_failure.dart';

import '../../support/fake_local_file_storage.dart';

void main() {
  test('fake file storage uses relative controlled paths', () async {
    final storage = FakeLocalFileStorage();
    final pathResult = await storage.write(
      namespace: LocalStorageNamespace.userImageOriginals,
      fileName: 'scene-1.png',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    expect(pathResult, isA<Ok<String, StorageFailure>>());
    final relativePath = (pathResult as Ok<String, StorageFailure>).value;

    expect(relativePath, 'user-content/originals/scene-1.png');
    expect(await storage.exists(relativePath), isA<Ok<bool, StorageFailure>>());
    expect(
      await storage.read(relativePath),
      isA<Ok<Uint8List, StorageFailure>>(),
    );

    await storage.delete(relativePath);

    final exists = await storage.exists(relativePath);
    expect((exists as Ok<bool, StorageFailure>).value, isFalse);
  });
}
