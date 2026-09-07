import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';
import 'package:smart_keychain_app/features/device_home/widgets/companion_stage.dart';

void main() {
  testWidgets('Stage confirms a committed scene change with one short glint', (
    tester,
  ) async {
    final scene = ValueNotifier<Scene>(_mintScene);
    addTearDown(scene.dispose);
    final engine = _engine();
    addTearDown(engine.dispose);

    await _pumpStage(tester, scene: scene, engine: engine);
    expect(tester.hasRunningAnimations, isFalse);

    scene.value = _sunnyScene;
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion keeps confirmation static', (tester) async {
    final scene = ValueNotifier<Scene>(_mintScene);
    addTearDown(scene.dispose);
    final engine = _engine();
    addTearDown(engine.dispose);

    await _pumpStage(
      tester,
      scene: scene,
      engine: engine,
      disableAnimations: true,
    );
    scene.value = _sunnyScene;
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byKey(const Key('companion_stage_rim')), findsOneWidget);
    expect(
      find.byKey(const Key('companion_stage_confirmation')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpStage(
  WidgetTester tester, {
  required ValueNotifier<Scene> scene,
  required VirtualDeviceEngine engine,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: Center(
              child: ValueListenableBuilder(
                valueListenable: scene,
                builder: (context, value, child) => CompanionStage(
                  scene: value,
                  displayProfile: engine.snapshot.displayProfile,
                  snapshot: engine.snapshot,
                  diameter: 280,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

VirtualDeviceEngine _engine() {
  return VirtualDeviceEngine(
    sceneRepository: BuiltInSceneRepository(),
    initialSceneId: BuiltInSceneRepository.mintEyesId,
    latency: Duration.zero,
  );
}

const _mintScene = Scene(
  id: BuiltInSceneRepository.mintEyesId,
  name: 'Мятный взгляд',
  content: StaticImageContent(
    previewAssetPath: 'assets/scenes/eyes_mint_static_v1.png',
  ),
  source: SceneSource.builtIn,
);

const _sunnyScene = Scene(
  id: BuiltInSceneRepository.sunnyFriendId,
  name: 'Солнечный друг',
  content: StaticImageContent(
    previewAssetPath: 'assets/scenes/sunny_friend_static_v1.png',
  ),
  source: SceneSource.builtIn,
);
