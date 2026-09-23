import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/features/device_discovery/device_discovery_screen.dart';
import 'package:smart_keychain_app/features/device_discovery/pairing_presentation_state.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/jewel_button.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

void main() {
  testWidgets('found presents the companion and its available action', (
    tester,
  ) async {
    await _pumpPairing(tester, state: PairingPresentationState.found);

    expect(find.text('Нашли тебя'), findsOneWidget);
    expect(find.text('Виртуальный брелок'), findsOneWidget);
    expect(find.text('ДЕМО'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('Подключить'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('pairing_lens_stage'))),
      matchesSemantics(label: 'Виртуальный брелок найден', isImage: true),
    );
  });

  testWidgets('connecting keeps the JewelButton stable and disabled', (
    tester,
  ) async {
    await _pumpPairing(tester, state: PairingPresentationState.found);
    final foundSize = tester.getSize(find.byKey(const Key('connect_button')));

    await _pumpPairing(tester, state: PairingPresentationState.connecting);
    final button = tester.widget<JewelButton>(
      find.byKey(const Key('connect_button')),
    );

    expect(find.text('Подключаем…'), findsWidgets);
    expect(button.busy, isTrue);
    expect(button.onPressed, isNull);
    expect(tester.getSize(find.byKey(const Key('connect_button'))), foundSize);
  });

  testWidgets('error explains recovery and retry invokes the action', (
    tester,
  ) async {
    var retryCount = 0;
    await _pumpPairing(
      tester,
      state: PairingPresentationState.error,
      onPrimaryAction: () => retryCount++,
    );

    expect(find.text('Не получилось подключиться'), findsOneWidget);
    expect(find.textContaining('останутся на месте'), findsOneWidget);
    await tester.tap(find.byKey(const Key('connect_button')));
    expect(retryCount, 1);
  });

  testWidgets('connected state is a short confirmed wake beat', (tester) async {
    await _pumpPairing(tester, state: PairingPresentationState.connected);

    expect(find.text('Вы на связи'), findsOneWidget);
    expect(find.textContaining('уже просыпается'), findsOneWidget);
    expect(
      find.byKey(const Key('pairing_connected_confirmation')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('connect_button')), findsNothing);
  });

  testWidgets(
    'reduced motion leaves searching state without a running ticker',
    (tester) async {
      await _pumpPairing(
        tester,
        state: PairingPresentationState.searching,
        disableAnimations: true,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Ищем рядом…'), findsWidgets);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('pairing states use the production Medium mood mapping', (
    tester,
  ) async {
    const cases = {
      PairingPresentationState.idle: KissCutVisualMood.sleepy,
      PairingPresentationState.searching: KissCutVisualMood.sleepy,
      PairingPresentationState.found: KissCutVisualMood.curious,
      PairingPresentationState.connecting: KissCutVisualMood.neutral,
      PairingPresentationState.connected: KissCutVisualMood.happy,
      PairingPresentationState.error: KissCutVisualMood.sleepy,
    };

    for (final entry in cases.entries) {
      await _pumpPairing(tester, state: entry.key);
      final eyes = tester.widget<ChromeKissProductionEyes>(
        find.byType(ChromeKissProductionEyes),
      );

      expect(eyes.scale, ChromeKissEyeScale.medium, reason: entry.key.name);
      expect(eyes.mood, entry.value, reason: entry.key.name);
      expect(eyes.animate, isFalse, reason: entry.key.name);
      expect(eyes.useProductionMotion, isFalse, reason: entry.key.name);
    }
  });

  testWidgets('Obsidian and Pearl share the black companion lens', (
    tester,
  ) async {
    for (final appearance in ResolvedAppAppearance.values) {
      await _pumpPairing(
        tester,
        state: PairingPresentationState.idle,
        appearance: appearance,
      );
      final context = tester.element(
        find.byKey(const Key('pairing_lens_stage')),
      );
      final tokens = Theme.of(context).extension<ChromeKissColors>()!;
      expect(tokens.lens, ChromeKissColors.obsidian.lens);
    }
  });

  for (final scenario in const [
    (name: 'compact', size: Size(320, 640), scale: 1.0, top: 0.0, bottom: 0.0),
    (
      name: 'iPhone 13',
      size: Size(390, 844),
      scale: 1.0,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: 'Android insets',
      size: Size(390, 844),
      scale: 1.0,
      top: 24.0,
      bottom: 24.0,
    ),
    (name: 'large', size: Size(430, 932), scale: 1.0, top: 0.0, bottom: 0.0),
    (
      name: '180% text',
      size: Size(390, 844),
      scale: 1.8,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: '300% text',
      size: Size(390, 844),
      scale: 3.0,
      top: 0.0,
      bottom: 0.0,
    ),
  ]) {
    testWidgets('pairing remains reachable at ${scenario.name}', (
      tester,
    ) async {
      await _pumpPairing(
        tester,
        state: PairingPresentationState.found,
        size: scenario.size,
        textScale: scenario.scale,
        viewPadding: EdgeInsets.only(
          top: scenario.top,
          bottom: scenario.bottom,
        ),
      );
      final cta = find.byKey(const Key('connect_button'));
      await tester.ensureVisible(cta);
      await tester.pump();
      final rect = tester.getRect(cta);
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(scenario.size.height));
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpPairing(
  WidgetTester tester, {
  required PairingPresentationState state,
  ResolvedAppAppearance appearance = ResolvedAppAppearance.obsidian,
  Size size = const Size(390, 844),
  double textScale = 1,
  EdgeInsets viewPadding = EdgeInsets.zero,
  bool disableAnimations = true,
  VoidCallback? onPrimaryAction,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = FakeViewPadding(
      top: viewPadding.top,
      bottom: viewPadding.bottom,
    )
    ..viewPadding = FakeViewPadding(
      top: viewPadding.top,
      bottom: viewPadding.bottom,
    );
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: PairingDiscoveryView(
          state: state,
          batteryPercent: 78,
          onPrimaryAction:
              onPrimaryAction ??
              (state == PairingPresentationState.found ? () {} : null),
        ),
      ),
    ),
  );
  await tester.pump();
}
