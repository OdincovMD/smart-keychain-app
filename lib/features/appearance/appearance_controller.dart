import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/settings/app_appearance.dart';

final initialAppAppearanceProvider = Provider<AppAppearance>(
  (ref) => AppAppearance.system,
);

final appAppearanceProvider =
    NotifierProvider<AppearanceController, AppAppearance>(
      AppearanceController.new,
    );

final class AppearanceController extends Notifier<AppAppearance> {
  Future<void> _writeTail = Future<void>.value();

  @override
  AppAppearance build() => ref.watch(initialAppAppearanceProvider);

  void setAppearance(AppAppearance appearance) {
    if (appearance == state) return;
    _writeTail = _writeTail.then((_) => _persist(appearance));
  }

  Future<void> _persist(AppAppearance appearance) async {
    try {
      await ref.read(appSettingsRepositoryProvider).saveAppearance(appearance);
      if (ref.mounted) state = appearance;
    } catch (error, stackTrace) {
      ref.read(failureLoggerProvider)('appearance.save', error, stackTrace);
    }
  }
}
