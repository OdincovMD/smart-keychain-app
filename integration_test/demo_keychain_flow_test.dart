import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_catalog.dart';
import 'package:smart_keychain_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connect, customize, and disconnect Demo Keychain', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connect_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scene_sunny_friend_static_v1')));
    await tester.tap(find.byKey(const Key('install_scene_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey(BuiltInSceneCatalog.sunnyFriendId)),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('brightness_slider')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('disconnect_button')));
    await tester.pumpAndSettle();
    expect(find.text('Выберите брелок'), findsOneWidget);
  });
}
