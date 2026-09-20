import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

void main() {
  test('production motion asset rejects Avatar Lab and Strobi provenance', () {
    final root = jsonDecode(
      File(BundledEyeMotionDefinitionLoader.productionAssetPath)
          .readAsStringSync(),
    ) as Map<String, Object?>;
    final metadata = root['metadata']! as Map<String, Object?>;
    final poses = root['poses']! as Map<String, Object?>;

    expect(metadata['sourceFormat'], isNot('avatar-definition-v1'));
    expect(metadata['sourceFormat'], isNot('bible-strong/avatar-definition'));
    expect(poses.keys.toSet().intersection(_knownStrobiPoseNames), isEmpty);
    expect(poses.keys, everyElement(startsWith('ck_')));
  });
}

const _knownStrobiPoseNames = {
  'surprised-left',
  'surprised-wide-left',
  'upward-side-glance',
  'far-right-glance',
  'curious-left',
};
