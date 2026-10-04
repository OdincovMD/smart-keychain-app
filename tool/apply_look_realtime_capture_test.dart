@Tags(['capture'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/device/device_capabilities.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_info.dart';
import 'package:smart_keychain_app/domain/device/device_repository.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/domain/settings/app_settings.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_eye_reaction_lens.dart';
import 'package:smart_keychain_app/features/device_home/widgets/eye_motion_ticker.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/user_content/look_application_controller.dart';
import 'package:smart_keychain_app/features/user_content/look_details_sheet.dart';
import 'package:smart_keychain_app/features/user_content/look_eye_reaction_coordinator.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../test/support/apply_look_realtime_capture.dart';
import '../test/support/fake_app_settings_repository.dart';
import '../test/support/load_app_fonts.dart';
import '../test/support/neutral_realtime_capture.dart';

const _captureBoundary = Key('apply_look_realtime_capture_boundary');
const _outputEnvironment = 'APPLY_LOOK_CAPTURE_OUTPUT';
final _productionDefinition = _loadProductionDefinition();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCompanionHomeFonts);
  tearDown(_resetSurface);

  testWidgets('captures success close-up from sequential 30 FPS steps', (
    tester,
  ) async {
    _setSurface(const Size(240, 240));
    final key = GlobalKey<_CaptureRuntimeHostState>();
    await _pumpCloseup(tester, key);
    final runtime = key.currentState!.runtime;
    final coordinator = LookEyeReactionCoordinator(
      player: runtime.player,
      refresh: runtime.refresh,
    );
    final capture = StreamingGifCapture(applyLookSuccessSpec);
    final trace = ApplyLookTraceBuilder(spec: applyLookSuccessSpec);
    var status = LookApplicationStatus.ready;

    prepareRuntimeForDeterministicCapture(runtime);
    for (var frame = 0; frame < applyLookSuccessSpec.frameCount; frame++) {
      _reportProgress(applyLookSuccessSpec, frame);
      advanceRuntimeFrame(runtime, applyLookSuccessSpec, frame);
      if (frame == 30) {
        status = LookApplicationStatus.applying;
        coordinator.sync(status, reducedMotion: false);
      } else if (frame == 75) {
        status = LookApplicationStatus.applied;
        coordinator.sync(status, reducedMotion: false);
      }
      await tester.pump();
      if (frame % 3 == 0) {
        trace.sample(
          runtime.player,
          applyLookSuccessSpec.frameTime(frame),
          status,
        );
      }
      capture.addRgbaFrame(
        await captureBoundaryRgba(
          tester,
          find.byKey(_captureBoundary),
          applyLookSuccessSpec,
        ),
        frame,
      );
    }
    _advanceToEnd(runtime, applyLookSuccessSpec);
    trace.sample(runtime.player, applyLookSuccessSpec.duration, status);
    final output = _outputDirectory();
    capture.finish(output);
    File('${output.path}/apply-look-eye-reaction-seed-4-trace.json')
        .writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(trace.build())}\n',
        );
    coordinator.dispose();
  }, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('captures failure and retry from sequential 30 FPS steps', (
    tester,
  ) async {
    _setSurface(const Size(240, 240));
    final key = GlobalKey<_CaptureRuntimeHostState>();
    await _pumpCloseup(tester, key);
    final runtime = key.currentState!.runtime;
    final coordinator = LookEyeReactionCoordinator(
      player: runtime.player,
      refresh: runtime.refresh,
    );
    final capture = StreamingGifCapture(applyLookFailureRetrySpec);

    prepareRuntimeForDeterministicCapture(runtime);
    for (var frame = 0; frame < applyLookFailureRetrySpec.frameCount; frame++) {
      _reportProgress(applyLookFailureRetrySpec, frame);
      advanceRuntimeFrame(runtime, applyLookFailureRetrySpec, frame);
      if (frame == 15) {
        coordinator.sync(LookApplicationStatus.applying, reducedMotion: false);
      } else if (frame == 60) {
        coordinator.sync(LookApplicationStatus.failed, reducedMotion: false);
      } else if (frame == 105) {
        coordinator.sync(LookApplicationStatus.applying, reducedMotion: false);
      }
      await tester.pump();
      capture.addRgbaFrame(
        await captureBoundaryRgba(
          tester,
          find.byKey(_captureBoundary),
          applyLookFailureRetrySpec,
        ),
        frame,
      );
    }
    capture.finish(_outputDirectory());
    coordinator.dispose();
  }, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('captures real Look Application UI and confirmation contract', (
    tester,
  ) async {
    _setSurface(const Size(390, 844));
    final device = _ScriptedDeviceRepository();
    addTearDown(device.dispose);
    final key = GlobalKey<_CaptureRuntimeHostState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(device),
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(
              initialSettings: AppSettings(
                activeSceneId: device.snapshot.activeSceneId,
                brightness: AppSettings.defaultBrightness,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _CaptureRuntimeHost(
            key: key,
            childBuilder: (runtime) => RepaintBoundary(
              key: _captureBoundary,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: LookDetailsSheet(
                    scene: _targetScene,
                    eyeRuntime: runtime,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final runtime = key.currentState!.runtime;
    prepareRuntimeForDeterministicCapture(runtime);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LookDetailsSheet)),
    );
    final controller = container.read(
      lookApplicationControllerProvider(_targetScene.id).notifier,
    );
    final capture = StreamingGifCapture(applyLookLifecycleSpec);

    for (var frame = 0; frame < applyLookLifecycleSpec.frameCount; frame++) {
      _reportProgress(applyLookLifecycleSpec, frame);
      advanceRuntimeFrame(runtime, applyLookLifecycleSpec, frame);
      if (frame == 15) {
        controller.apply();
      } else if (frame == 45) {
        device
          ..emitScene(_targetScene.id)
          ..completeCommand();
      }
      await tester.pump(applyLookLifecycleSpec.frameDelta(frame));
      capture.addRgbaFrame(
        await captureBoundaryRgba(
          tester,
          find.byKey(_captureBoundary),
          applyLookLifecycleSpec,
        ),
        frame,
      );
    }
    expect(device.setSceneCalls, 1);
    expect(
      container.read(lookApplicationControllerProvider(_targetScene.id)).status,
      LookApplicationStatus.applied,
    );
    capture.finish(_outputDirectory());
  }, timeout: const Timeout(Duration(minutes: 45)));

  test('writes compact review contact sheets without frame sequences', () {
    final output = _outputDirectory();
    _writeCloseupContactSheet(output);
    _writeLifecycleContactSheet(output);
  });
}

void _writeCloseupContactSheet(Directory output) {
  const sources = [
    (
      spec: applyLookSuccessSpec,
      frames: [
        0,
        24,
        30,
        34,
        42,
        60,
        74,
        76,
        82,
        86,
        89,
        91,
        93,
        96,
        102,
        110,
        130,
        179,
      ],
    ),
    (
      spec: applyLookFailureRetrySpec,
      frames: [
        0,
        14,
        15,
        20,
        28,
        42,
        59,
        60,
        64,
        70,
        80,
        96,
        104,
        105,
        109,
        120,
        140,
        179,
      ],
    ),
  ];
  final sheet = image.Image(width: 720, height: 720, numChannels: 4);
  for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
    final source = sources[sourceIndex];
    final animation = image.decodeGif(
      File('${output.path}/${source.spec.name}.gif').readAsBytesSync(),
    )!;
    for (var index = 0; index < source.frames.length; index++) {
      image.compositeImage(
        sheet,
        animation.frames[source.frames[index]],
        dstX: (index % 6) * 120,
        dstY: (sourceIndex * 3 + index ~/ 6) * 120,
        dstW: 120,
        dstH: 120,
      );
    }
  }
  File('${output.path}/apply-look-reactions-contact-sheet.png')
      .writeAsBytesSync(image.encodePng(sheet));
}

void _writeLifecycleContactSheet(Directory output) {
  const frames = [0, 14, 15, 22, 44, 45, 50, 65, 89];
  final animation = image.decodeGif(
    File('${output.path}/${applyLookLifecycleSpec.name}.gif').readAsBytesSync(),
  )!;
  final sheet = image.Image(width: 390, height: 843, numChannels: 4);
  for (var index = 0; index < frames.length; index++) {
    image.compositeImage(
      sheet,
      animation.frames[frames[index]],
      dstX: (index % 3) * 130,
      dstY: (index ~/ 3) * 281,
      dstW: 130,
      dstH: 281,
    );
  }
  File('${output.path}/apply-look-lifecycle-contact-sheet.png')
      .writeAsBytesSync(image.encodePng(sheet));
}

Future<void> _pumpCloseup(
  WidgetTester tester,
  GlobalKey<_CaptureRuntimeHostState> key,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(),
        home: _CaptureRuntimeHost(
          key: key,
          childBuilder: (runtime) => RepaintBoundary(
            key: _captureBoundary,
            child: ColoredBox(
              color: KissCutEyePainter.lensColor,
              child: Center(
                child: ChromeKissEyeReactionLens(
                  size: ChromeKissEyeReactionLensSize.medium,
                  mood: KissCutVisualMood.neutral,
                  animate: true,
                  useProductionMotion: true,
                  runtime: runtime,
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

final class _CaptureRuntimeHost extends StatefulWidget {
  const _CaptureRuntimeHost({required this.childBuilder, super.key});

  final Widget Function(EyeMotionTicker runtime) childBuilder;

  @override
  State<_CaptureRuntimeHost> createState() => _CaptureRuntimeHostState();
}

final class _CaptureRuntimeHostState extends State<_CaptureRuntimeHost>
    with SingleTickerProviderStateMixin {
  late final EyeMotionTicker runtime;

  @override
  void initState() {
    super.initState();
    final engine = EyeBehaviourEngine(
      math.Random(applyLookCaptureSeed),
      initialMood: EyeEmotion.neutral,
    );
    runtime = EyeMotionTicker(
      vsync: this,
      player: EyeMotionPlayer(
        behaviourEngine: engine,
        definition: _productionDefinition,
        initialMood: EyeEmotion.neutral,
        initialClip: resolveInitialEyeMotionClip(_productionDefinition),
        behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.childBuilder(runtime);

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }
}

final class _ScriptedDeviceRepository implements DeviceRepository {
  _ScriptedDeviceRepository() : _snapshot = _snapshotFor('builtin-living-eyes');

  final StreamController<DeviceSnapshot> _snapshots =
      StreamController<DeviceSnapshot>.broadcast();
  DeviceSnapshot _snapshot;
  Completer<void>? _command;
  var setSceneCalls = 0;

  DeviceSnapshot get snapshot => _snapshot;

  void emitScene(String sceneId) {
    _snapshot = _snapshot.copyWith(activeSceneId: sceneId);
    _snapshots.add(_snapshot);
  }

  void completeCommand() {
    final command = _command;
    if (command != null && !command.isCompleted) command.complete();
  }

  @override
  Future<List<DeviceInfo>> discoverDevices() async => const [];

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<DeviceConnectionStatus> watchConnectionState() =>
      Stream.value(DeviceConnectionStatus.ready);

  @override
  Stream<DeviceSnapshot> watchDeviceState() async* {
    yield _snapshot;
    yield* _snapshots.stream;
  }

  @override
  Future<void> setScene(String sceneId) {
    setSceneCalls++;
    _command = Completer<void>();
    return _command!.future;
  }

  @override
  Future<void> setBrightness(double value) async {}

  @override
  Future<void> dispose() => _snapshots.close();
}

const _targetScene = Scene(
  id: 'builtin-eyes-mint',
  name: 'Мятный взгляд',
  source: SceneSource.builtIn,
  tags: {'eyes', 'animated'},
  content: ProceduralEyesContent(defaultEmotion: EyeEmotion.neutral),
);

const _profile = DisplayProfile(
  width: 240,
  height: 240,
  shape: DisplayShape.circle,
  aspectRatio: 1,
);

const _capabilities = DeviceCapabilities(
  supportsBrightness: true,
  reportsBattery: true,
  supportsStaticScenes: true,
  supportsAnimatedScenes: true,
);

DeviceSnapshot _snapshotFor(String sceneId) => DeviceSnapshot(
  deviceId: 'capture-keychain',
  connectionStatus: DeviceConnectionStatus.ready,
  batteryPercent: 82,
  brightness: AppSettings.defaultBrightness,
  activeSceneId: sceneId,
  displayProfile: _profile,
  capabilities: _capabilities,
);

EyeMotionDefinition _loadProductionDefinition() {
  final decoded = decodeEyeMotionDefinition(
    File(BundledEyeMotionDefinitionLoader.productionAssetPath)
        .readAsStringSync(),
  );
  return switch (decoded) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError(failure.code),
  };
}

void _advanceToEnd(EyeMotionTicker runtime, NeutralCaptureSpec spec) {
  final lastFrameTime = spec.frameTime(spec.frameCount - 1);
  runtime.player.advance(spec.duration - lastFrameTime);
  runtime.refresh();
}

Directory _outputDirectory() => Directory(
  Platform.environment[_outputEnvironment] ??
      'artifacts/apply-look-eye-reaction-v1',
);

void _reportProgress(NeutralCaptureSpec spec, int frame) {
  if (frame % 60 == 0) {
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
