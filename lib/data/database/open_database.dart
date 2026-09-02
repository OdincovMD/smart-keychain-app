import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseFile = File(
      path.join(supportDirectory.path, 'smart_keychain.sqlite'),
    );
    return NativeDatabase.createInBackground(
      databaseFile,
      setup: (database) {
        database.execute('PRAGMA journal_mode = WAL');
        database.execute('PRAGMA synchronous = FULL');
        database.execute('PRAGMA foreign_keys = ON');
        database.execute('PRAGMA busy_timeout = 5000');
      },
    );
  });
}
