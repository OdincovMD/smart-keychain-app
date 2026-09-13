import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/features/image_import/create_look_screen.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  testWidgets('photo target returns the pick-photo intent', (tester) async {
    await _pumpFlow(tester);

    await tester.tap(find.byKey(const Key('open_create_look')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(CreateLookScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_look_pick_photo')));
    await tester.pump();

    expect(find.text('pickPhoto'), findsOneWidget);
  });

  testWidgets('back keeps the flow unchanged', (tester) async {
    await _pumpFlow(tester);

    await tester.tap(find.byKey(const Key('open_create_look')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('create_look_back_button')));
    await tester.pump();

    expect(find.text('unchanged'), findsOneWidget);
  });

  for (final testCase in const [
    (
      name: 'compact 320x640',
      size: Size(320, 640),
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
    (
      name: 'large text 390x844',
      size: Size(390, 844),
      scale: 1.8,
      top: 0.0,
      bottom: 0.0,
    ),
    (
      name: 'accessibility text',
      size: Size(390, 844),
      scale: 3.0,
      top: 0.0,
      bottom: 0.0,
    ),
  ]) {
    testWidgets('Create Look remains usable at ${testCase.name}', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = testCase.size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: MediaQueryData(
              size: testCase.size,
              textScaler: TextScaler.linear(testCase.scale),
              padding: EdgeInsets.only(
                top: testCase.top,
                bottom: testCase.bottom,
              ),
              viewPadding: EdgeInsets.only(
                top: testCase.top,
                bottom: testCase.bottom,
              ),
            ),
            child: const CreateLookScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('create_look_pick_photo')), findsOneWidget);
      final scroll = find.byKey(const Key('create_look_scroll'));
      final continueButton = find.byKey(
        const Key('create_look_continue_button'),
      );
      for (
        var attempt = 0;
        attempt < 8 && continueButton.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(scroll, const Offset(0, -500));
        await tester.pump();
      }
      await tester.ensureVisible(continueButton);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(continueButton, findsOneWidget);
      expect(tester.getRect(continueButton).height, greaterThanOrEqualTo(48));
      expect(
        tester.getRect(continueButton).bottom,
        lessThanOrEqualTo(testCase.size.height),
      );
    });
  }
}

Future<void> _pumpFlow(WidgetTester tester) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const _CreateLookFlowHarness()));
  await tester.pump();
}

Widget _app(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('ru'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

final class _CreateLookFlowHarness extends StatefulWidget {
  const _CreateLookFlowHarness();

  @override
  State<_CreateLookFlowHarness> createState() => _CreateLookFlowHarnessState();
}

final class _CreateLookFlowHarnessState extends State<_CreateLookFlowHarness> {
  var _result = 'unchanged';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_result),
          FilledButton(
            key: const Key('open_create_look'),
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<CreateLookScreenResult>(
                    MaterialPageRoute(
                      builder: (context) => const CreateLookScreen(),
                    ),
                  );
              if (!mounted || result == null) return;
              setState(() => _result = result.name);
            },
            child: const Text('open'),
          ),
        ],
      ),
    );
  }
}
