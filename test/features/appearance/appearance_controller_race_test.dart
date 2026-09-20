import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/domain/settings/app_settings_repository.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';

void main() {
  test('active appearance is a no-op', () async {
    final repository = _ControlledSettingsRepository();
    final container = _container(repository, AppAppearance.obsidian);
    addTearDown(container.dispose);

    container
        .read(appAppearanceProvider.notifier)
        .setAppearance(AppAppearance.obsidian);
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, isEmpty);
  });

  test('each appearance publishes only after persistence succeeds', () async {
    final repository = _ControlledSettingsRepository();
    final container = _container(repository, AppAppearance.system);
    addTearDown(container.dispose);

    for (final appearance in const [
      AppAppearance.obsidian,
      AppAppearance.pearl,
      AppAppearance.system,
    ]) {
      container.read(appAppearanceProvider.notifier).setAppearance(appearance);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(appAppearanceProvider), isNot(appearance));
      repository.completeNext();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(appAppearanceProvider), appearance);
    }

    expect(repository.calls, [
      AppAppearance.obsidian,
      AppAppearance.pearl,
      AppAppearance.system,
    ]);
  });

  test(
    'rapid selections serialize and finish on the last confirmed value',
    () async {
      final repository = _ControlledSettingsRepository();
      final container = _container(repository, AppAppearance.obsidian);
      addTearDown(container.dispose);

      container
          .read(appAppearanceProvider.notifier)
          .setAppearance(AppAppearance.pearl);
      await Future<void>.delayed(Duration.zero);
      container
          .read(appAppearanceProvider.notifier)
          .setAppearance(AppAppearance.system);

      expect(repository.calls, [AppAppearance.pearl]);
      expect(container.read(appAppearanceProvider), AppAppearance.obsidian);

      repository.completeNext();
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, [AppAppearance.pearl, AppAppearance.system]);
      expect(container.read(appAppearanceProvider), AppAppearance.pearl);

      repository.completeNext();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(appAppearanceProvider), AppAppearance.system);
      expect(repository.maxConcurrentWrites, 1);
    },
  );

  test('latest selection replaces an intermediate queued value', () async {
    final repository = _ControlledSettingsRepository();
    final container = _container(repository, AppAppearance.obsidian);
    addTearDown(container.dispose);

    final controller = container.read(appAppearanceProvider.notifier);
    controller.setAppearance(AppAppearance.pearl);
    await Future<void>.delayed(Duration.zero);
    controller.setAppearance(AppAppearance.system);
    controller.setAppearance(AppAppearance.pearl);

    repository.completeNext();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, [AppAppearance.pearl]);
    expect(container.read(appAppearanceProvider), AppAppearance.pearl);
    expect(repository.maxConcurrentWrites, 1);
  });

  test(
    'persistence failure keeps the confirmed appearance and can retry',
    () async {
      final repository = _ControlledSettingsRepository();
      final container = _container(repository, AppAppearance.obsidian);
      addTearDown(container.dispose);
      final states = <AppearancePersistenceState>[];
      final subscription = container.listen(appearancePersistenceProvider, (
        previous,
        next,
      ) {
        if (next.value case final value?) states.add(value);
      }, fireImmediately: true);
      addTearDown(subscription.close);

      container
          .read(appAppearanceProvider.notifier)
          .setAppearance(AppAppearance.pearl);
      await Future<void>.delayed(Duration.zero);
      repository.failNext(StateError('disk unavailable'));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(appAppearanceProvider), AppAppearance.obsidian);
      expect(
        states,
        contains(const AppearancePersistenceState.failed(AppAppearance.pearl)),
      );

      container.read(appAppearanceProvider.notifier).retry(AppAppearance.pearl);
      await Future<void>.delayed(Duration.zero);
      repository.completeNext();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(appAppearanceProvider), AppAppearance.pearl);
    },
  );

  test('late persistence failure is ignored after disposal', () async {
    final repository = _ControlledSettingsRepository();
    final errors = <Object>[];

    final guarded = runZonedGuarded(() async {
      final container = _container(repository, AppAppearance.obsidian);
      container
          .read(appAppearanceProvider.notifier)
          .setAppearance(AppAppearance.pearl);
      await Future<void>.delayed(Duration.zero);

      container.dispose();
      repository.failNext(StateError('late failure'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }, (error, stackTrace) => errors.add(error));

    await guarded;
    expect(errors, isEmpty);
  });
}

ProviderContainer _container(
  AppSettingsRepository repository,
  AppAppearance initial,
) {
  return ProviderContainer(
    overrides: [
      initialAppAppearanceProvider.overrideWithValue(initial),
      appSettingsRepositoryProvider.overrideWithValue(repository),
      failureLoggerProvider.overrideWithValue((code, error, stackTrace) {}),
    ],
  );
}

final class _ControlledSettingsRepository implements AppSettingsRepository {
  final calls = <AppAppearance>[];
  final _writes = <Completer<void>>[];
  var _settings = AppSettings.defaults;
  var _concurrentWrites = 0;
  var maxConcurrentWrites = 0;

  @override
  Future<void> saveAppearance(AppAppearance appearance) async {
    calls.add(appearance);
    final write = Completer<void>();
    _writes.add(write);
    _concurrentWrites++;
    if (_concurrentWrites > maxConcurrentWrites) {
      maxConcurrentWrites = _concurrentWrites;
    }
    try {
      await write.future;
      _settings = _settings.copyWith(appearance: appearance);
    } finally {
      _concurrentWrites--;
    }
  }

  void completeNext() => _writes.removeAt(0).complete();

  void failNext(Object error) => _writes.removeAt(0).completeError(error);

  @override
  Future<void> flush() async {}

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> saveActiveSceneId(String sceneId) async {
    _settings = _settings.copyWith(activeSceneId: sceneId);
  }

  @override
  Future<void> saveBrightness(double brightness) async {
    _settings = _settings.copyWith(brightness: brightness);
  }
}
