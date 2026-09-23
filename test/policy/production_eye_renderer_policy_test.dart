import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production code does not select legacy or reference eye renderers', () {
    const ownerAndDeveloperAllowlist = {
      'lib/features/device_home/widgets/procedural_eyes_view.dart',
      'lib/features/device_home/widgets/character_study_screen.dart',
    };
    final productionFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !ownerAndDeveloperAllowlist.contains(file.path));
    final bannedSelections = [
      RegExp(r'EyeRendererVariant\.legacy\b'),
      RegExp(r'EyeRendererVariant\.kissCutV2\b'),
      RegExp(r'EyeRendererVariant\.figmaJewelry\b'),
    ];

    for (final file in productionFiles) {
      final source = file.readAsStringSync();
      for (final selection in bannedSelections) {
        expect(
          selection.hasMatch(source),
          isFalse,
          reason: '${file.path} selects non-production renderer $selection',
        );
      }
    }
  });
}
