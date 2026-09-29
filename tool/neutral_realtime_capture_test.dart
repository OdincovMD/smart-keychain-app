@Tags(['capture'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/neutral_living_idle.dart';
import 'package:smart_keychain_app/domain/settings/app_appearance.dart';
import 'package:smart_keychain_app/features/appearance/appearance_controller.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/eye_motion_ticker.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

import '../test/support/load_app_fonts.dart';
import '../test/support/neutral_realtime_capture.dart';

const _captureBoundary = Key('neutral_realtime_capture_boundary');
const _outputEnvironment = 'NEUTRAL_REALTIME_CAPTURE_OUTPUT';

final _productionDefinition = _loadProductionDefinition();
final _sceneRepository = BuiltInSceneRepository();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);

  tearDown(_resetSurface);

  testWidgets('captures Neutral close-up at sequential 30 FPS runtime steps', (
    tester,
  ) async {
    _setSurface(const Size(240, 240));
    final harness = await _pumpCloseup(tester);
    final trace = NeutralTraceBuilder(spec: neutralCloseupSpec);
    final full = StreamingGifCapture(neutralCloseupSpec);
    final preview = StreamingGifCapture(neutralCloseupPreviewSpec);

    prepareRuntimeForDeterministicCapture(harness.runtime);
    for (var frame = 0; frame < neutralCloseupSpec.frameCount; frame++) {
      _reportProgress(neutralCloseupSpec, frame);
      advanceRuntimeFrame(harness.runtime, neutralCloseupSpec, frame);
      await tester.pump();
      if (frame % 3 == 0) {
        trace.sample(
          harness.runtime.player,
          neutralCloseupSpec.frameTime(frame),
        );
      }
      final rgba = await captureBoundaryRgba(
        tester,
        find.byKey(_captureBoundary),
        neutralCloseupSpec,
      );
      full.addRgbaFrame(rgba, frame);
      if (frame.isEven) preview.addRgbaFrame(rgba, frame ~/ 2);
    }

    _advanceToDurationEnd(harness.runtime, neutralCloseupSpec);
    trace.sample(harness.runtime.player, neutralCloseupSpec.duration);
    final output = _outputDirectory();
    full.finish(output);
    preview.finish(output);
    File(
      '${output.path}/neutral-living-idle-seed-4-trace.json',
    ).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(trace.build(harness.runtime.player))}\n',
    );
  }, timeout: const Timeout(Duration(minutes: 45)));

  testWidgets(
    'captures production Obsidian Home at sequential 15 FPS runtime steps',
    (tester) async {
      _setSurface(const Size(390, 844));
      final repository = VirtualDeviceRepository(engine: _createEngine());
      addTearDown(repository.dispose);
      final runtime = await _pumpConnectedHome(tester, repository);
      final capture = StreamingGifCapture(neutralHomeSpec);

      prepareRuntimeForDeterministicCapture(runtime);
      for (var frame = 0; frame < neutralHomeSpec.frameCount; frame++) {
        _reportProgress(neutralHomeSpec, frame);
        advanceRuntimeFrame(runtime, neutralHomeSpec, frame);
        await tester.pump();
        capture.addRgbaFrame(
          await captureBoundaryRgba(
            tester,
            find.byKey(_captureBoundary),
            neutralHomeSpec,
          ),
          frame,
        );
      }
      capture.finish(_outputDirectory());
    },
    timeout: const Timeout(Duration(minutes: 45)),
  );

  testWidgets(
    'captures production blink commands at sequential 30 FPS runtime steps',
    (tester) async {
      _setSurface(const Size(240, 240));
      final harness = await _pumpCloseup(tester);
      harness.controller.setLivingIdleConfiguration(
        const EyeLivingIdleConfiguration(
          blinks: false,
          signatureMoments: false,
        ),
      );
      await tester.pump();
      final commands = <int, void Function()>{
        30: harness.controller.requestBlink,
        75: harness.controller.requestDoubleBlink,
        135: harness.controller.requestSlowBlink,
        195: harness.controller.requestWink,
      };
      final capture = StreamingGifCapture(neutralBlinkSpec);

      prepareRuntimeForDeterministicCapture(harness.runtime);
      for (var frame = 0; frame < neutralBlinkSpec.frameCount; frame++) {
        _reportProgress(neutralBlinkSpec, frame);
        advanceRuntimeFrame(harness.runtime, neutralBlinkSpec, frame);
        commands[frame]?.call();
        await tester.pump();
        capture.addRgbaFrame(
          await captureBoundaryRgba(
            tester,
            find.byKey(_captureBoundary),
            neutralBlinkSpec,
          ),
          frame,
        );
      }
      capture.finish(_outputDirectory());
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );

  testWidgets(
    'captures production signature commands with ambient returns at 30 FPS',
    (tester) async {
      _setSurface(const Size(240, 240));
      final harness = await _pumpCloseup(tester);
      harness.controller.setLivingIdleConfiguration(
        const EyeLivingIdleConfiguration(
          blinks: false,
          signatureMoments: false,
        ),
      );
      await tester.pump();
      final commands = <int, void Function()>{
        30: harness.controller.requestSignatureCuriousGlance,
        90: harness.controller.requestSignatureSoftCenterBlink,
        159: harness.controller.requestSignatureSideHoldReturn,
      };
      final capture = StreamingGifCapture(neutralSignatureSpec);

      prepareRuntimeForDeterministicCapture(harness.runtime);
      for (var frame = 0; frame < neutralSignatureSpec.frameCount; frame++) {
        _reportProgress(neutralSignatureSpec, frame);
        advanceRuntimeFrame(harness.runtime, neutralSignatureSpec, frame);
        commands[frame]?.call();
        await tester.pump();
        capture.addRgbaFrame(
          await captureBoundaryRgba(
            tester,
            find.byKey(_captureBoundary),
            neutralSignatureSpec,
          ),
          frame,
        );
      }
      capture.finish(_outputDirectory());
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

final class _CloseupHarness {
  const _CloseupHarness({required this.runtime, required this.controller});

  final EyeMotionTicker runtime;
  final EyePreviewController controller;
}

Future<_CloseupHarness> _pumpCloseup(WidgetTester tester) async {
  EyeMotionTicker? runtime;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eyeRandomProvider.overrideWithValue(Random(neutralCaptureSeed)),
        productionEyeMotionDefinitionProvider.overrideWithValue(
          _productionDefinition,
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: RepaintBoundary(
          key: _captureBoundary,
          child: ColoredBox(
            color: KissCutEyePainter.lensColor,
            child: Center(
              child: ChromeKissProductionEyes(
                scale: ChromeKissEyeScale.hero,
                mood: KissCutVisualMood.neutral,
                animate: true,
                useProductionMotion: true,
                behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
                onRuntimeReady: (value) => runtime = value,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final resolvedRuntime = runtime;
  if (resolvedRuntime == null) {
    throw StateError('Production close-up did not expose its eye runtime.');
  }
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChromeKissProductionEyes)),
  );
  return _CloseupHarness(
    runtime: resolvedRuntime,
    controller: container.read(eyePreviewControllerProvider.notifier),
  );
}

Future<EyeMotionTicker> _pumpConnectedHome(
  WidgetTester tester,
  VirtualDeviceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sceneRepositoryProvider.overrideWithValue(_sceneRepository),
        deviceRepositoryProvider.overrideWithValue(repository),
        initialAppAppearanceProvider.overrideWithValue(AppAppearance.obsidian),
        productionEyeMotionDefinitionProvider.overrideWithValue(
          _productionDefinition,
        ),
        eyeRandomProvider.overrideWithValue(Random(neutralCaptureSeed)),
      ],
      child: const RepaintBoundary(
        key: _captureBoundary,
        child: SmartKeychainApp(),
      ),
    ),
  );
  await tester.pump();
  await _precacheHomeAssets(tester);
  await tester.tap(find.byKey(const Key('connect_button')));
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 181));
  await tester.pump(const Duration(milliseconds: 601));
  await tester.pump();
  await tester.pump();

  final stage = find.byKey(const Key('companion_stage'));
  expect(stage, findsOneWidget);
  final container = ProviderScope.containerOf(tester.element(stage));
  container
      .read(eyePreviewControllerProvider.notifier)
      .setRandomSeed(neutralCaptureSeed);
  await tester.pump();
  await tester.pump();

  final eyePainter = find.descendant(
    of: stage,
    matching: find.byKey(const Key('kiss_cut_eye_painter')),
  );
  final paint = tester.widget<CustomPaint>(eyePainter);
  final painter = paint.painter! as KissCutEyePainter;
  final runtime = painter.stateSource;
  if (runtime is! EyeMotionTicker) {
    throw StateError('Production Home did not use EyeMotionTicker.');
  }
  return runtime;
}

Future<void> _precacheHomeAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await Future.wait(
      const <String>[
        'assets/scenes/eyes_mint_static_v1.png',
        'assets/scenes/sunny_friend_static_v1.png',
        'assets/chrome_kiss/key_ring.png',
        'assets/chrome_kiss/key_ring_opening.png',
        'assets/chrome_kiss/pendant_chrome_shell.png',
        'assets/chrome_kiss/pendant_lens.png',
        'assets/chrome_kiss/lens_inner_rim.png',
        'assets/chrome_kiss/lens_glint_lilac.png',
        'assets/chrome_kiss/lens_glint_white.png',
        'assets/chrome_kiss/lens_glint_orchid.png',
        'assets/chrome_kiss/bow_left.png',
        'assets/chrome_kiss/bow_right.png',
        'assets/chrome_kiss/bow_knot.png',
        'assets/chrome_kiss/charm_ring.png',
        'assets/chrome_kiss/atmosphere_orchid_halo.png',
        'assets/chrome_kiss/home_look_original.png',
        'assets/chrome_kiss/home_look_mint.png',
        'assets/chrome_kiss/home_look_lilac.png',
        'assets/chrome_kiss/home_look_photo.png',
      ].map((path) => precacheImage(AssetImage(path), context)),
    );
  });
  await tester.pump();
}

void _advanceToDurationEnd(EyeMotionTicker runtime, NeutralCaptureSpec spec) {
  final lastFrameTime = spec.frameTime(spec.frameCount - 1);
  runtime.player.advance(spec.duration - lastFrameTime);
  runtime.refresh();
}

EyeMotionDefinition _loadProductionDefinition() {
  final decoded = decodeEyeMotionDefinition(
    File(BundledEyeMotionDefinitionLoader.productionAssetPath)
        .readAsStringSync(),
  );
  return switch (decoded) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError(
      'Production motion definition failed: ${failure.code}.',
    ),
  };
}

VirtualDeviceEngine _createEngine() => VirtualDeviceEngine(
  sceneRepository: _sceneRepository,
  initialSceneId: BuiltInSceneRepository.livingEyesId,
  latency: Duration.zero,
);

Directory _outputDirectory() => Directory(
  Platform.environment[_outputEnvironment] ??
      'artifacts/neutral-living-idle-v2/realtime',
);

void _reportProgress(NeutralCaptureSpec spec, int frame) {
  if (frame % 100 == 0) {
    debugPrint('${spec.name}: frame $frame/${spec.frameCount}');
  }
}

void _setSurface(Size size) {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
}

void _resetSurface() {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  view.resetPhysicalSize();
  view.resetDevicePixelRatio();
}
