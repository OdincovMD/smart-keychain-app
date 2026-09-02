import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/data/database/app_database.dart';
import 'package:smart_keychain_app/data/settings/drift_app_settings_repository.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';

void main() {
  group('DriftAppSettingsRepository', () {
    late AppDatabase database;
    late DriftAppSettingsRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftAppSettingsRepository(database);
    });

    tearDown(() => database.close());

    test('returns domain defaults when settings row is absent', () async {
      expect(await repository.load(), AppSettings.defaults);
    });

    test('saves and restores activeSceneId', () async {
      await repository.saveActiveSceneId('eyes_mint_static_v1');

      final restored = await DriftAppSettingsRepository(database).load();

      expect(restored.activeSceneId, 'eyes_mint_static_v1');
      expect(restored.brightness, AppSettings.defaultBrightness);
    });

    test('saves and restores brightness', () async {
      await repository.saveBrightness(0.375);

      final restored = await DriftAppSettingsRepository(database).load();

      expect(restored.brightness, closeTo(0.375, 0.0001));
      expect(restored.activeSceneId, isNull);
    });

    test('preserves other settings across partial updates', () async {
      await repository.saveActiveSceneId('eyes_mint_static_v1');
      await repository.saveBrightness(0.42);

      final restored = await repository.load();

      expect(restored.activeSceneId, 'eyes_mint_static_v1');
      expect(restored.brightness, closeTo(0.42, 0.0001));
    });

    test('initializes schema version 2 as STRICT tables', () async {
      await repository.load();
      final versionRow = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      final schemaRow = await database
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE name = 'app_settings'",
          )
          .getSingle();

      final imageSchemaRow = await database
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE name = 'user_image_assets'",
          )
          .getSingle();

      expect(versionRow.read<int>('user_version'), 2);
      expect(schemaRow.read<String>('sql'), contains('STRICT'));
      expect(imageSchemaRow.read<String>('sql'), contains('STRICT'));
    });

    test('unknown migration step fails instead of resetting data', () async {
      await expectLater(
        database.migration.onUpgrade(Migrator(database), 2, 3),
        throwsA(isA<StateError>()),
      );
    });
  });
}
