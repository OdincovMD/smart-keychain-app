import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';

void main() {
  test('V2.1 moods retain safe silhouettes and optical cores', () {
    for (final mood in KissCutVisualMood.values) {
      final state = KissCutStudyPose.forMood(
        mood,
        style: KissCutRendererStyle.v21Pure,
      );
      final geometry = KissCutGeometrySnapshot.fromState(
        state,
        visualMoodOverride: mood,
        style: KissCutRendererStyle.v21Pure,
      );

      expect(geometry.left.pupilInsideEye, isTrue, reason: mood.name);
      expect(geometry.right.pupilInsideEye, isTrue, reason: mood.name);
      expect(
        geometry.contentRadiusFraction,
        lessThanOrEqualTo(0.36),
        reason: mood.name,
      );
    }
  });

  test('seeded V2.1 geometry remains bounded for extreme runtime inputs', () {
    final random = Random(210021);
    for (var sample = 0; sample < 300; sample++) {
      final mood = KissCutVisualMood
          .values[random.nextInt(KissCutVisualMood.values.length)];
      final state =
          KissCutStudyPose.forMood(
            mood,
            style: KissCutRendererStyle.v21Pure,
          ).copyWith(
            gazeX: random.nextDouble() * 2 - 1,
            gazeY: random.nextDouble() * 2 - 1,
            pupilScale: 0.69 + random.nextDouble() * 0.51,
            leftEyelidOpen: 0.35 + random.nextDouble() * 0.65,
            rightEyelidOpen: 0.35 + random.nextDouble() * 0.65,
          );
      final geometry = KissCutGeometrySnapshot.fromState(
        state,
        visualMoodOverride: mood,
        style: KissCutRendererStyle.v21OpticalGlint,
      );

      expect(geometry.left.pupilInsideEye, isTrue, reason: 'left $sample');
      expect(geometry.right.pupilInsideEye, isTrue, reason: 'right $sample');
      expect(geometry.contentRadiusFraction, lessThanOrEqualTo(0.36));
    }
  });

  test('pure and optical-glint studies are distinct immutable scenes', () {
    final state = KissCutStudyPose.forMood(
      KissCutVisualMood.neutral,
      style: KissCutRendererStyle.v21Pure,
    );
    final pure = KissCutPaintScene(
      fromState: state,
      toState: state,
      motionCurve: Curves.linear,
      displayShape: DisplayShape.circle,
      style: KissCutRendererStyle.v21Pure,
    );
    final glint = KissCutPaintScene(
      fromState: state,
      toState: state,
      motionCurve: Curves.linear,
      displayShape: DisplayShape.circle,
      style: KissCutRendererStyle.v21OpticalGlint,
    );

    expect(pure, isNot(glint));
  });

  for (final size in [64.0, 240.0]) {
    testWidgets('V2.1 paints every mood at ${size.toInt()} px', (tester) async {
      for (final mood in KissCutVisualMood.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.square(
                dimension: size,
                child: KissCutEyesView(
                  state: KissCutStudyPose.forMood(
                    mood,
                    style: KissCutRendererStyle.v21Pure,
                  ),
                  visualMoodOverride: mood,
                  style: KissCutRendererStyle.v21Pure,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('kiss_cut_eye_painter')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: mood.name);
      }
    });
  }

  testWidgets('reduced motion freezes V2.1 in an expressive static pose', (
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
                child: ProceduralEyesView(
                  initialEmotion: EyeEmotion.curious,
                  rendererVariant: EyeRendererVariant.kissCutV21,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('kiss_cut_eye_painter')),
    );
    final painter = paint.painter! as KissCutEyePainter;
    expect(painter.scene.style, KissCutRendererStyle.v21Pure);
    expect(painter.scene.fromState, painter.scene.toState);
    expect(painter.scene.toState.emotion, EyeEmotion.curious);
  });

  testWidgets('V2.1 continues to consume the seeded behaviour controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eyeRandomProvider.overrideWithValue(Random(21))],
        child: const MaterialApp(
          home: SizedBox.square(
            dimension: 240,
            child: ProceduralEyesView(
              initialEmotion: EyeEmotion.neutral,
              rendererVariant: EyeRendererVariant.kissCutV21,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProceduralEyesView)),
    );
    container.read(eyePreviewControllerProvider.notifier).requestLookRight();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('kiss_cut_eye_painter')),
    );
    final painter = paint.painter! as KissCutEyePainter;
    expect(painter.scene.toState.gazeX, greaterThan(0));
  });
}
