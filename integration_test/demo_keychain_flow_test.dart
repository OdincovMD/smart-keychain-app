import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connect, customize, and disconnect Demo Keychain', (
    tester,
  ) async {
    await app.main();
    await tester.pump();

    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.livingEyesId)),
      findsOneWidget,
    );

    final staticScene = find.byKey(const Key('scene_eyes_mint_static_v1'));
    await tester.scrollUntilVisible(
      staticScene,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    await tester.tap(staticScene);
    await tester.tap(find.byKey(const Key('install_scene_button')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const ValueKey(BuiltInSceneRepository.mintEyesId)),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-120, 0),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byKey(const Key('disconnect_button')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Выберите брелок'), findsOneWidget);
  });
}
