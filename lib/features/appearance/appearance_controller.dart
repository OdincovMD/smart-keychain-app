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

final appearancePersistenceProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(appAppearanceProvider.notifier).watchPersistence(),
);

enum AppearancePersistenceStatus { idle, saving, failed }

final class AppearancePersistenceState {
  const AppearancePersistenceState({required this.status, this.target});

  const AppearancePersistenceState.idle()
    : status = AppearancePersistenceStatus.idle,
      target = null;

  const AppearancePersistenceState.saving(AppAppearance appearance)
    : status = AppearancePersistenceStatus.saving,
      target = appearance;

  const AppearancePersistenceState.failed(AppAppearance appearance)
    : status = AppearancePersistenceStatus.failed,
      target = appearance;

  final AppearancePersistenceStatus status;
  final AppAppearance? target;

  bool get isSaving => status == AppearancePersistenceStatus.saving;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppearancePersistenceState &&
          status == other.status &&
          target == other.target;

  @override
  int get hashCode => Object.hash(status, target);
}

final class AppearanceController extends Notifier<AppAppearance> {
  final _persistence = StreamController<AppearancePersistenceState>.broadcast(
    sync: true,
  );
  AppAppearance? _queuedAppearance;
  bool _processing = false;

  @override
  AppAppearance build() {
    ref.onDispose(_persistence.close);
    return ref.watch(initialAppAppearanceProvider);
  }

  Stream<AppearancePersistenceState> watchPersistence() async* {
    yield const AppearancePersistenceState.idle();
    yield* _persistence.stream;
  }

  void setAppearance(AppAppearance appearance) {
    if (appearance == state && !_processing) return;
    if (appearance == _queuedAppearance) return;
    _queuedAppearance = appearance;
    if (_processing) return;
    _processing = true;
    unawaited(_drainQueue());
  }

  void retry(AppAppearance appearance) => setAppearance(appearance);

  Future<void> _drainQueue() async {
    while (_queuedAppearance != null) {
      final appearance = _queuedAppearance!;
      _queuedAppearance = null;
      if (appearance == state) continue;
      _emit(AppearancePersistenceState.saving(appearance));
      try {
        await ref
            .read(appSettingsRepositoryProvider)
            .saveAppearance(appearance);
        if (!ref.mounted) return;
        state = appearance;
        _emit(const AppearancePersistenceState.idle());
      } catch (error, stackTrace) {
        if (!ref.mounted) return;
        ref.read(failureLoggerProvider)('appearance.save', error, stackTrace);
        _emit(AppearancePersistenceState.failed(appearance));
      }
    }
    _processing = false;
  }

  void _emit(AppearancePersistenceState next) {
    if (!_persistence.isClosed) _persistence.add(next);
  }
}
