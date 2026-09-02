import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final class CrashLog {
  CrashLog._(this._file);

  static const _maxBytes = 128 * 1024;

  final File _file;

  static Future<CrashLog> open() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final file = File(path.join(supportDirectory.path, 'crash.log'));
    return CrashLog._(file);
  }

  void record(Object error, StackTrace? stackTrace) {
    try {
      if (_file.existsSync() && _file.lengthSync() >= _maxBytes) {
        _file.writeAsStringSync('', flush: true);
      }
      _file.writeAsStringSync(
        '$error\n${stackTrace ?? ''}\n\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // ignore: swallowed_catch
      // A crash handler must never recursively throw while recording a failure.
    }
  }
}
