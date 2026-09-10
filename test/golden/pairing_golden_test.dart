@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/features/device_discovery/device_discovery_screen.dart';
import 'package:smart_keychain_app/features/device_discovery/pairing_presentation_state.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  const cases = <_PairingGoldenCase>[
    _PairingGoldenCase(
      name: 'Pairing idle Obsidian',
      fileName: 'pairing_idle_obsidian_390x844.png',
      state: PairingPresentationState.idle,
      appearance: ResolvedAppAppearance.obsidian,
    ),
    _PairingGoldenCase(
      name: 'Pairing found Obsidian',
      fileName: 'pairing_found_obsidian_390x844.png',
      state: PairingPresentationState.found,
      appearance: ResolvedAppAppearance.obsidian,
    ),
    _PairingGoldenCase(
      name: 'Pairing connecting Obsidian',
      fileName: 'pairing_connecting_obsidian.png',
      state: PairingPresentationState.connecting,
      appearance: ResolvedAppAppearance.obsidian,
    ),
    _PairingGoldenCase(
      name: 'Pairing connected Obsidian',
      fileName: 'pairing_connected_obsidian.png',
      state: PairingPresentationState.connected,
      appearance: ResolvedAppAppearance.obsidian,
    ),
    _PairingGoldenCase(
      name: 'Pairing error Obsidian',
      fileName: 'pairing_error_obsidian.png',
      state: PairingPresentationState.error,
      appearance: ResolvedAppAppearance.obsidian,
    ),
    _PairingGoldenCase(
      name: 'Pairing idle Pearl',
      fileName: 'pairing_idle_pearl_390x844.png',
      state: PairingPresentationState.idle,
      appearance: ResolvedAppAppearance.pearl,
    ),
    _PairingGoldenCase(
      name: 'Pairing found Pearl',
      fileName: 'pairing_found_pearl_390x844.png',
      state: PairingPresentationState.found,
      appearance: ResolvedAppAppearance.pearl,
    ),
  ];

  for (final goldenCase in cases) {
    testWidgets(goldenCase.name, (tester) async {
      await _pumpGolden(tester, goldenCase);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/${goldenCase.fileName}'),
      );
    });
  }
}

final class _PairingGoldenCase {
  const _PairingGoldenCase({
    required this.name,
    required this.fileName,
    required this.state,
    required this.appearance,
  });

  final String name;
  final String fileName;
  final PairingPresentationState state;
  final ResolvedAppAppearance appearance;
}

Future<void> _pumpGolden(
  WidgetTester tester,
  _PairingGoldenCase goldenCase,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(goldenCase.appearance),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: PairingDiscoveryView(
          state: goldenCase.state,
          batteryPercent: 78,
          onPrimaryAction: switch (goldenCase.state) {
            PairingPresentationState.idle ||
            PairingPresentationState.found ||
            PairingPresentationState.error => () {},
            PairingPresentationState.searching ||
            PairingPresentationState.connecting ||
            PairingPresentationState.connected => null,
          },
        ),
      ),
    ),
  );
  await tester.pump();
}
