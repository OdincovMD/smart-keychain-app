import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

void main() {
  final source = File(BundledEyeMotionDefinitionLoader.productionAssetPath)
      .readAsStringSync();

  test('loads and decodes the production definition only once', () async {
    final bundle = _CountingAssetBundle(source);
    final logs = <String>[];
    final loader = BundledEyeMotionDefinitionLoader(
      bundle: bundle,
      log: (code, error, stackTrace) => logs.add(code),
    );

    final first = loader.load();
    final second = loader.load();

    expect(identical(first, second), isTrue);
    expect(
      await first,
      isA<Ok<EyeMotionDefinition, BundledEyeMotionFailure>>(),
    );
    expect(bundle.loadCount, 1);
    expect(logs, isEmpty);
  });

  test('invalid definition logs typed failure and returns fallback', () async {
    final logs = <String>[];
    final loader = BundledEyeMotionDefinitionLoader(
      bundle: _CountingAssetBundle('{not-json'),
      log: (code, error, stackTrace) => logs.add(code),
    );

    final definition = await loader.loadOrFallback(
      chromeKissEyeMotionDefinition,
    );

    expect(definition, same(chromeKissEyeMotionDefinition));
    expect(logs, ['eye_motion.asset_invalid_definition']);
  });

  test('asset read failure logs typed failure and returns fallback', () async {
    final logs = <String>[];
    final loader = BundledEyeMotionDefinitionLoader(
      bundle: _CountingAssetBundle.failure(),
      log: (code, error, stackTrace) => logs.add(code),
    );

    final definition = await loader.loadOrFallback(
      chromeKissEyeMotionDefinition,
    );

    expect(definition, same(chromeKissEyeMotionDefinition));
    expect(logs, ['eye_motion.asset_read_failed']);
  });
}

final class _CountingAssetBundle extends CachingAssetBundle {
  _CountingAssetBundle(this.source) : readError = null;

  _CountingAssetBundle.failure()
    : source = '',
      readError = StateError('fixture read failed');

  final String source;
  final Object? readError;
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    if (readError case final error?) throw error;
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
  }
}
