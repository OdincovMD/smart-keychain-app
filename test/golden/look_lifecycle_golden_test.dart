@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/features/user_content/look_application_controller.dart';
import 'package:smart_keychain_app/features/user_content/look_application_view.dart';
import 'package:smart_keychain_app/features/user_content/look_delete_confirmation_sheet.dart';
import 'package:smart_keychain_app/features/user_content/look_details_ready.dart';
import 'package:smart_keychain_app/features/shared/chrome_kiss_material_sheet.dart';

import '../support/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  for (final appearance in ResolvedAppAppearance.values) {
    final themeName = appearance.name;

    testWidgets('look details $themeName 390x844', (tester) async {
      await _pumpSurface(
        tester,
        appearance: appearance,
        child: ChromeKissMaterialSheet(
          child: LookDetailsReady(
            scene: _scene,
            isActive: false,
            onClose: _noop,
            onApply: _noop,
            onEdit: _noop,
            onDelete: _noop,
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/look_details_${themeName}_390x844.png'),
      );
    });

    for (final status in const [
      LookApplicationStatus.applying,
      LookApplicationStatus.applied,
      LookApplicationStatus.failed,
    ]) {
      final stateName = status == LookApplicationStatus.failed
          ? 'error'
          : status.name;
      testWidgets('look ${status.name} $themeName 390x844', (tester) async {
        await _pumpSurface(
          tester,
          appearance: appearance,
          child: ChromeKissMaterialSheet(
            child: LookApplicationView(
              scene: _scene,
              status: status,
              onRetry: _noop,
              onReturn: _noop,
            ),
          ),
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'baselines/look_${stateName}_${themeName}_390x844.png',
          ),
        );
      });
    }

    testWidgets('look delete $themeName 390x844', (tester) async {
      await _pumpSurface(
        tester,
        appearance: appearance,
        child: const LookDeleteConfirmationSheet(scene: _scene),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/look_delete_${themeName}_390x844.png'),
      );
    });
  }
}

const _scene = Scene(
  id: 'golden-look',
  name: 'Мятный взгляд',
  source: SceneSource.userGenerated,
  tags: {'eyes', 'static', 'user'},
  content: StaticImageContent(
    previewAssetPath: 'assets/scenes/eyes_mint_static_v1.png',
  ),
);

void _noop() {}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required ResolvedAppAppearance appearance,
  required Widget child,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await precacheImage(
      const AssetImage('assets/scenes/eyes_mint_static_v1.png'),
      context,
    );
  });
  await tester.pump();
}
