import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/eye_motion_ticker.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';
import 'package:smart_keychain_app/features/device_home/widgets/scene_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/virtual_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

void main() {
  testWidgets('procedural and static scenes use their matching renderers', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      sceneId: BuiltInSceneRepository.livingEyesId,
      disableAnimations: true,
    );
    expect(find.byKey(const Key('kiss_cut_eye_painter')), findsOneWidget);
    expect(find.byType(ProceduralEyesSceneRenderer), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('kiss_cut_eye_painter')),
    );
    final painter = paint.painter! as KissCutEyePainter;
    expect(painter.scene.style, KissCutRendererStyle.v21OpticalGlint);
    expect(painter.scene.colourway, KissCutColourway.orchidLilac);

    await _pumpScreen(
      tester,
      sceneId: BuiltInSceneRepository.mintEyesId,
      disableAnimations: true,
    );
    expect(find.byKey(const Key('kiss_cut_eye_painter')), findsNothing);
    expect(find.byType(StaticImageSceneRenderer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a frozen card preview stays in its neutral pose', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.square(
          dimension: 240,
          child: ProceduralEyesView(
            initialEmotion: EyeEmotion.neutral,
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 8));

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('procedural_eyes_painter')),
    );
    final painter = paint.painter! as ProceduralEyePainter;
    expect(painter.scene.fromState, painter.scene.toState);
    expect(painter.scene.toState.emotion, EyeEmotion.neutral);
  });

  testWidgets('reduced motion snaps emotion and schedules no eye action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const MaterialApp(
              home: SizedBox.square(
                dimension: 240,
                child: ProceduralEyesView(initialEmotion: EyeEmotion.neutral),
              ),
            ),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProceduralEyesView)),
    );
    container
        .read(eyePreviewControllerProvider.notifier)
        .setEmotion(EyeEmotion.sleepy);
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('procedural_eyes_painter')),
    );
    final painter = paint.painter! as ProceduralEyePainter;
    expect(painter.scene.fromState, painter.scene.toState);
    expect(painter.currentState.emotion, EyeEmotion.sleepy);
  });

  testWidgets('normal blink closes asymmetrically and ends open', (
    tester,
  ) async {
    final container = await _pumpAnimatedEyes(tester, seed: 11);

    container.read(eyePreviewControllerProvider.notifier).requestBlink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    var painter = _eyePainter(tester);
    expect(
      painter.currentState.motionPhase,
      anyOf(EyeMotionPhase.closing, EyeMotionPhase.closed),
    );
    expect(painter.currentState.leftEyelidOpen, isNot(closeTo(0.04, 1e-9)));

    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 30));
    painter = _eyePainter(tester);
    expect(painter.currentState.eyelidOpen, greaterThan(0.8));
  });

  testWidgets('double blink performs a second close', (tester) async {
    final container = await _pumpAnimatedEyes(tester, seed: 17);

    container.read(eyePreviewControllerProvider.notifier).requestDoubleBlink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump(const Duration(milliseconds: 50));

    final painter = _eyePainter(tester);
    expect(
      painter.currentState.motionPhase,
      anyOf(EyeMotionPhase.closing, EyeMotionPhase.closed),
    );
  });

  testWidgets('directed gaze settles back at center', (tester) async {
    final container = await _pumpAnimatedEyes(tester, seed: 23);

    container.read(eyePreviewControllerProvider.notifier).requestLookLeft();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_eyePainter(tester).currentState.gazeX, lessThan(0));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 70));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 500));

    final state = _eyePainter(tester).currentState;
    expect(state.gazeX.abs(), lessThan(0.1));
  });

  testWidgets('special action returns smoothly to mood idle', (tester) async {
    final container = await _pumpAnimatedEyes(tester, seed: 31);
    container
        .read(eyePreviewControllerProvider.notifier)
        .setEmotion(EyeEmotion.curious);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 230));

    container
        .read(eyePreviewControllerProvider.notifier)
        .requestSpecialAction();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      _eyePainter(tester).currentState.motionPhase,
      EyeMotionPhase.special,
    );
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));

    final state = _eyePainter(tester).currentState;
    expect(state.mood, EyeEmotion.curious);
    expect(state.gazeX.abs(), lessThan(0.12));
  });

  testWidgets('disposing the view cancels pending timers and ticker', (
    tester,
  ) async {
    await _pumpAnimatedEyes(tester, seed: 41);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle pause resumes without catching up elapsed time', (
    tester,
  ) async {
    final productionDefinition = _productionDefinition();
    late EyeMotionTicker runtime;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eyeRandomProvider.overrideWithValue(Random(51)),
          productionEyeMotionDefinitionProvider.overrideWithValue(
            productionDefinition,
          ),
        ],
        child: MaterialApp(
          home: SizedBox.square(
            dimension: 240,
            child: ProceduralEyesView(
              initialEmotion: EyeEmotion.neutral,
              useProductionMotionDefinition: true,
              onRuntimeReady: (value) => runtime = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final beforePause = runtime.player.elapsed;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 8));
    expect(runtime.player.elapsed, beforePause);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runtime.player.elapsed - beforePause,
      lessThan(const Duration(milliseconds: 150)),
    );
  });

  testWidgets(
    'production timeline survives parent rebuild and appearance change',
    (tester) async {
      final definition = _productionDefinition();
      late EyeMotionTicker runtime;

      await tester.pumpWidget(
        _productionEyesHarness(
          definition: definition,
          themeMode: ThemeMode.light,
          onRuntimeReady: (value) => runtime = value,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final originalRuntime = runtime;
      final beforeRebuild = runtime.player.elapsed;

      expect(runtime.player.definition, same(definition));
      expect(runtime.player.clipName, ChromeKissProductionEyeClips.kissIdle);

      await tester.pumpWidget(
        _productionEyesHarness(
          definition: definition,
          themeMode: ThemeMode.light,
          onRuntimeReady: (value) => runtime = value,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(runtime, same(originalRuntime));
      final beforeAppearanceChange = runtime.player.elapsed;

      await tester.pumpWidget(
        _productionEyesHarness(
          definition: definition,
          themeMode: ThemeMode.dark,
          onRuntimeReady: (value) => runtime = value,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(runtime, same(originalRuntime));
      expect(beforeAppearanceChange, greaterThan(beforeRebuild));
      expect(runtime.player.elapsed, greaterThan(beforeAppearanceChange));
    },
  );

  testWidgets('opening and closing a sheet does not restart production eyes', (
    tester,
  ) async {
    final definition = _productionDefinition();
    late EyeMotionTicker runtime;

    await tester.pumpWidget(
      _productionSheetHarness(
        definition: definition,
        onRuntimeReady: (value) => runtime = value,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final originalRuntime = runtime;
    final beforeSheet = runtime.player.elapsed;

    await tester.tap(find.byKey(const Key('open_test_sheet')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('test_sheet')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('test_sheet')))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(runtime, same(originalRuntime));
    expect(runtime.player.elapsed, greaterThan(beforeSheet));
  });

  testWidgets('reduced motion keeps production eyes static', (tester) async {
    final definition = _productionDefinition();
    late EyeMotionTicker runtime;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productionEyeMotionDefinitionProvider.overrideWithValue(definition),
        ],
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: MaterialApp(
              home: SizedBox.square(
                dimension: 240,
                child: ProceduralEyesView(
                  initialEmotion: EyeEmotion.neutral,
                  useProductionMotionDefinition: true,
                  onRuntimeReady: (value) => runtime = value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final initial = runtime.state;
    await tester.pump(const Duration(seconds: 8));

    expect(runtime.player.clipName, ChromeKissProductionEyeClips.kissIdle);
    expect(runtime.isTicking, isFalse);
    expect(runtime.state, initial);
  });

  testWidgets('eye frames repaint without rebuilding the parent', (
    tester,
  ) async {
    var parentBuilds = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eyeRandomProvider.overrideWithValue(Random(61))],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              parentBuilds++;
              return const SizedBox.square(
                dimension: 240,
                child: ProceduralEyesView(
                  initialEmotion: EyeEmotion.neutral,
                  rendererVariant: EyeRendererVariant.kissCutV21,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final initialBuilds = parentBuilds;
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(parentBuilds, initialBuilds);
  });
}

Future<ProviderContainer> _pumpAnimatedEyes(
  WidgetTester tester, {
  required int seed,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [eyeRandomProvider.overrideWithValue(Random(seed))],
      child: const MaterialApp(
        home: SizedBox.square(
          dimension: 240,
          child: ProceduralEyesView(initialEmotion: EyeEmotion.neutral),
        ),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(
    tester.element(find.byType(ProceduralEyesView)),
  );
}

ProceduralEyePainter _eyePainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(const Key('procedural_eyes_painter')),
  );
  return paint.painter! as ProceduralEyePainter;
}

EyeMotionDefinition _productionDefinition() {
  final decoded = decodeEyeMotionDefinition(
    File(BundledEyeMotionDefinitionLoader.productionAssetPath)
        .readAsStringSync(),
  );
  expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
  return (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>).value;
}

Widget _productionEyesHarness({
  required EyeMotionDefinition definition,
  required ThemeMode themeMode,
  required ValueChanged<EyeMotionTicker> onRuntimeReady,
}) {
  return ProviderScope(
    overrides: [
      eyeRandomProvider.overrideWithValue(Random(101)),
      productionEyeMotionDefinitionProvider.overrideWithValue(definition),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: SizedBox.square(
        dimension: 240,
        child: ProceduralEyesView(
          initialEmotion: EyeEmotion.neutral,
          useProductionMotionDefinition: true,
          onRuntimeReady: onRuntimeReady,
        ),
      ),
    ),
  );
}

Widget _productionSheetHarness({
  required EyeMotionDefinition definition,
  required ValueChanged<EyeMotionTicker> onRuntimeReady,
}) {
  return ProviderScope(
    overrides: [
      eyeRandomProvider.overrideWithValue(Random(103)),
      productionEyeMotionDefinitionProvider.overrideWithValue(definition),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox.square(
              dimension: 240,
              child: ProceduralEyesView(
                initialEmotion: EyeEmotion.neutral,
                useProductionMotionDefinition: true,
                onRuntimeReady: onRuntimeReady,
              ),
            ),
            Builder(
              builder: (context) => TextButton(
                key: const Key('open_test_sheet'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (context) =>
                      const SizedBox(key: Key('test_sheet'), height: 120),
                ),
                child: const Text('Open'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required String sceneId,
  required bool disableAnimations,
}) async {
  final scene = await BuiltInSceneRepository().getById(sceneId);
  assert(scene != null);
  final snapshot = DeviceSnapshot(
    deviceId: VirtualDeviceEngine.deviceId,
    connectionStatus: DeviceConnectionStatus.ready,
    batteryPercent: 78,
    brightness: 0.8,
    activeSceneId: sceneId,
    displayProfile: VirtualDeviceEngine.displayProfile,
    capabilities: VirtualDeviceEngine.capabilities,
  );
  await tester.pumpWidget(
    ProviderScope(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Center(
              child: SizedBox.square(
                dimension: 240,
                child: VirtualScreen(
                  scene: scene!,
                  displayProfile: VirtualDeviceEngine.displayProfile,
                  snapshot: snapshot,
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
