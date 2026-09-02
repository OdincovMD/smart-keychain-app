import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';
import 'package:smart_keychain_app/features/device_home/widgets/scene_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/virtual_screen.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';

void main() {
  testWidgets('procedural and static scenes use their matching renderers', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      sceneId: BuiltInSceneRepository.livingEyesId,
      disableAnimations: true,
    );
    expect(find.byKey(const Key('procedural_eyes_painter')), findsOneWidget);
    expect(find.byType(ProceduralEyesSceneRenderer), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await _pumpScreen(
      tester,
      sceneId: BuiltInSceneRepository.mintEyesId,
      disableAnimations: true,
    );
    expect(find.byKey(const Key('procedural_eyes_painter')), findsNothing);
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
    expect(painter.scene.toState.emotion, EyeEmotion.sleepy);
  });
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
