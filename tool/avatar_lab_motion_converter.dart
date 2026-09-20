import 'dart:io';

import 'package:smart_keychain_app/core/result.dart';

import 'src/avatar_lab_motion_adapter.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'usage: dart run tool/avatar_lab_motion_converter.dart INPUT OUTPUT',
    );
    exitCode = 64;
    return;
  }

  try {
    final source = await File(arguments[0]).readAsString();
    final result = convertAvatarLabMotion(source);
    switch (result) {
      case Ok(:final value):
        await File(arguments[1]).writeAsString('${value.encode()}\n');
      case Err(:final failure):
        stderr.writeln(failure.code);
        exitCode = 65;
    }
  } on FileSystemException catch (error) {
    stderr.writeln(
      'avatar_lab_motion.io_error: ${error.osError?.errorCode ?? 0}',
    );
    exitCode = 74;
  }
}
