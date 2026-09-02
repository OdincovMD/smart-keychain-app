import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';

import '../infrastructure/logging/crash_log.dart';

void installErrorHandlers(CrashLog crashLog) {
  FlutterError.onError = (details) {
    try {
      FlutterError.presentError(details);
      crashLog.record(details.exception, details.stack);
    } catch (_) {
      // ignore: swallowed_catch
      // A crash handler must never recursively throw while handling a failure.
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    try {
      final unwrapped = _unwrapProviderException(error);
      crashLog.record(unwrapped, stackTrace);
      if (kDebugMode) debugPrint('$unwrapped\n$stackTrace');
    } catch (_) {
      // ignore: swallowed_catch
      // A crash handler must never recursively throw while handling a failure.
    }
    return true;
  };
}

Object _unwrapProviderException(Object error) {
  var current = error;
  while (current is ProviderException) {
    current = current.exception;
  }
  return current;
}
