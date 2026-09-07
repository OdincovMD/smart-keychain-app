import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';

import '../../support/fake_app_settings_repository.dart';

void main() {
  test('persists before publishing a selected appearance', () async {
    final settings = FakeAppSettingsRepository();
    final container = ProviderContainer(
      overrides: [
        initialAppAppearanceProvider.overrideWithValue(AppAppearance.obsidian),
        appSettingsRepositoryProvider.overrideWithValue(settings),
        failureLoggerProvider.overrideWithValue((code, error, stackTrace) {}),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appAppearanceProvider), AppAppearance.obsidian);

    container
        .read(appAppearanceProvider.notifier)
        .setAppearance(AppAppearance.pearl);
    expect(container.read(appAppearanceProvider), AppAppearance.obsidian);

    await Future<void>.delayed(Duration.zero);

    expect(settings.settings.appearance, AppAppearance.pearl);
    expect(container.read(appAppearanceProvider), AppAppearance.pearl);
  });
}
