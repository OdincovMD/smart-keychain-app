import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/data/database/app_database.dart';
import 'package:smart_keychain_app/data/settings/drift_app_settings_repository.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';

void main() {
  test('database reopen restores the selected appearance', () async {
    final directory = await Directory.systemTemp.createTemp(
      'smart-keychain-appearance-',
    );
    final databaseFile = File('${directory.path}/app.sqlite');
    final firstDatabase = AppDatabase(NativeDatabase(databaseFile));

    await DriftAppSettingsRepository(firstDatabase)
        .saveAppearance(AppAppearance.pearl);
    await firstDatabase.close();

    final restartedDatabase = AppDatabase(NativeDatabase(databaseFile));
    addTearDown(() async {
      await restartedDatabase.close();
      await directory.delete(recursive: true);
    });

    final restored = await DriftAppSettingsRepository(restartedDatabase).load();

    expect(restored.appearance, AppAppearance.pearl);
  });
}
