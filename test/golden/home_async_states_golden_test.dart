@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/features/device_home/home_async_state_view.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  for (final appearance in ResolvedAppAppearance.values) {
    for (final state in const <({String name, HomeAsyncStateKind kind})>[
      (name: 'loading', kind: HomeAsyncStateKind.initialLoading),
      (name: 'error', kind: HomeAsyncStateKind.snapshotUnavailable),
    ]) {
      testWidgets('home ${state.name} ${appearance.name} 390x844', (
        tester,
      ) async {
        await _pumpAsyncState(tester, appearance: appearance, kind: state.kind);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'baselines/home_${state.name}_${appearance.name}_390x844.png',
          ),
        );
      });
    }
  }
}

Future<void> _pumpAsyncState(
  WidgetTester tester, {
  required ResolvedAppAppearance appearance,
  required HomeAsyncStateKind kind,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: HomeAsyncStateView(
            kind: kind,
            onRetry: _noop,
            onReturnToDiscovery: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await Future.wait(
      const <String>[
        'assets/chrome_kiss/eye_left_figma.png',
        'assets/chrome_kiss/eye_right_figma.png',
      ].map((path) => precacheImage(AssetImage(path), context)),
    );
  });
  await tester.pump();
}

void _noop() {}
