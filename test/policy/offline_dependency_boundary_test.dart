import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release Android manifest has no internet permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });

  test('product code does not import network clients', () {
    const bannedImports = <String>[
      "package:dio/",
      "package:http/",
      "package:web_socket/",
      "package:web_socket_channel/",
    ];
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final bannedImport in bannedImports) {
        expect(
          source,
          isNot(contains(bannedImport)),
          reason: '${file.path} imports banned network client $bannedImport',
        );
      }
    }
  });
}
