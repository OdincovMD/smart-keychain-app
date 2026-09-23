import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

import '../../tool/src/avatar_lab_motion_adapter.dart';

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
        lessThanOrEqualTo(0.41),
        reason: mood.name,
      );
    }
  });

  test(
    'production scales stay finite, circular-safe, and readable at 64 px',
    () {
      for (final scale in ChromeKissEyeScale.values) {
        expect(scale.size.width.isFinite, isTrue);
        expect(scale.size.height.isFinite, isTrue);
        expect(scale.size.aspectRatio, closeTo(216 / 112, 0.001));

        for (final mood in KissCutVisualMood.values) {
          final state = KissCutStudyPose.forMood(
            mood,
            style: KissCutRendererStyle.v21OpticalGlint,
          );
          final geometry = KissCutGeometrySnapshot.fromState(
            state,
            visualMoodOverride: mood,
            style: KissCutRendererStyle.v21OpticalGlint,
          );
          final coordinates = [
            geometry.left.silhouetteBounds.left,
            geometry.left.silhouetteBounds.top,
            geometry.left.silhouetteBounds.right,
            geometry.left.silhouetteBounds.bottom,
            geometry.right.silhouetteBounds.left,
            geometry.right.silhouetteBounds.top,
            geometry.right.silhouetteBounds.right,
            geometry.right.silhouetteBounds.bottom,
          ];

          expect(coordinates.every((value) => value.isFinite), isTrue);
          expect(geometry.left.pupilInsideEye, isTrue);
          expect(geometry.right.pupilInsideEye, isTrue);
          expect(geometry.contentRadiusFraction, lessThanOrEqualTo(0.41));
          expect(
            geometry.left.silhouetteBounds.width * 64,
            greaterThanOrEqualTo(16),
            reason: '${scale.name}/${mood.name} left eye readability',
          );
          expect(
            geometry.right.silhouetteBounds.width * 64,
            greaterThanOrEqualTo(16),
            reason: '${scale.name}/${mood.name} right eye readability',
          );
        }
      }
    },
  );

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
      expect(geometry.contentRadiusFraction, lessThanOrEqualTo(0.41));
    }
  });

  test('every authored clip frame remains finite and geometry-safe', () {
    final base = EyeRuntimeState.resting(EyeEmotion.neutral);
    for (final clip in chromeKissEyeMotionDefinition.clips.values) {
      for (
        var elapsed = Duration.zero;
        elapsed <= clip.duration;
        elapsed += const Duration(milliseconds: 16)
      ) {
        final state = EyeMotionClipSampler.sample(
          definition: chromeKissEyeMotionDefinition,
          clip: clip,
          elapsed: elapsed,
          base: base,
          initial: base,
        ).state;
        final values = [
          state.gazeX,
          state.gazeY,
          state.leftEyelidOpen,
          state.rightEyelidOpen,
          state.pupilScale,
          state.eyeScaleX,
          state.eyeScaleY,
          state.expressionTilt,
          state.verticalOffset,
        ];
        final geometry = KissCutGeometrySnapshot.fromState(
          state,
          style: KissCutRendererStyle.v21OpticalGlint,
        );

        expect(values.every((value) => value.isFinite), isTrue);
        expect(state.leftEyelidOpen, inInclusiveRange(0, 1));
        expect(state.rightEyelidOpen, inInclusiveRange(0, 1));
        expect(geometry.left.pupilInsideEye, isTrue);
        expect(geometry.right.pupilInsideEye, isTrue);
        expect(
          geometry.contentRadiusFraction,
          lessThanOrEqualTo(0.41),
          reason: '${clip.name} at $elapsed',
        );
      }
    }
  });

  test('production clips remain finite and contained at 16–33 ms samples', () {
    final decoded = decodeEyeMotionDefinition(
      File(BundledEyeMotionDefinitionLoader.productionAssetPath)
          .readAsStringSync(),
    );
    expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
    final definition =
        (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>).value;
    final base = EyeRuntimeState.resting(EyeEmotion.neutral);

    for (final clipName in ChromeKissProductionEyeClips.values) {
      final clip = definition.clips[clipName]!;
      for (final interval in const [16, 33]) {
        for (
          var elapsed = Duration.zero;
          elapsed <= clip.duration;
          elapsed += Duration(milliseconds: interval)
        ) {
          final state = EyeMotionClipSampler.sample(
            definition: definition,
            clip: clip,
            elapsed: elapsed,
            base: base,
            initial: base,
          ).state;
          final geometry = KissCutGeometrySnapshot.fromState(
            state,
            style: KissCutRendererStyle.v21OpticalGlint,
          );
          final values = [
            state.gazeX,
            state.gazeY,
            state.leftEyelidOpen,
            state.rightEyelidOpen,
            state.pupilScale,
            state.eyeScaleX,
            state.eyeScaleY,
            state.expressionTilt,
            state.verticalOffset,
          ];

          expect(values.every((value) => value.isFinite), isTrue);
          expect(state.leftEyelidOpen, inInclusiveRange(0, 1));
          expect(state.rightEyelidOpen, inInclusiveRange(0, 1));
          expect(geometry.left.pupilInsideEye, isTrue);
          expect(geometry.right.pupilInsideEye, isTrue);
          expect(
            geometry.contentRadiusFraction,
            lessThanOrEqualTo(0.41),
            reason: '$clipName @ ${elapsed.inMilliseconds} ms / $interval ms',
          );
        }
      }
    }
  });

  test(
    'converted Avatar Lab frames remain inside renderer geometry bounds',
    () {
      final converted = convertAvatarLabMotion(
        File('tool/fixtures/avatar_lab_real_export_v1.avatar.json')
            .readAsStringSync(),
      );
      expect(converted, isA<Ok<EyeMotionDefinition, AvatarLabMotionFailure>>());
      final definition =
          (converted as Ok<EyeMotionDefinition, AvatarLabMotionFailure>).value;
      final base = EyeRuntimeState.resting(EyeEmotion.neutral);

      for (final clip in definition.clips.values) {
        for (
          var elapsed = Duration.zero;
          elapsed <= clip.duration;
          elapsed += const Duration(milliseconds: 16)
        ) {
          final state = EyeMotionClipSampler.sample(
            definition: definition,
            clip: clip,
            elapsed: elapsed,
            base: base,
            initial: base,
          ).state;
          final geometry = KissCutGeometrySnapshot.fromState(
            state,
            style: KissCutRendererStyle.v21OpticalGlint,
          );

          expect(geometry.left.pupilInsideEye, isTrue);
          expect(geometry.right.pupilInsideEye, isTrue);
          expect(state.leftEyelidOpen, inInclusiveRange(0, 1));
          expect(state.rightEyelidOpen, inInclusiveRange(0, 1));
          expect(
            geometry.contentRadiusFraction,
            lessThanOrEqualTo(0.41),
            reason: '${clip.name} at $elapsed',
          );
        }
      }
    },
  );

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
    expect(painter.scene.style, KissCutRendererStyle.v21OpticalGlint);
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
    expect(painter.currentState.gazeX, greaterThan(0));
  });
}
