import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/device/display_profile.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_library.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/domain/eyes/eye_runtime_state.dart';
import 'package:smart_keychain_app/features/device_home/eye_preview_controller.dart';
import 'package:smart_keychain_app/features/device_home/widgets/character_study_screen.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

void main() {
  test('all visual moods keep pupils and silhouettes in the safe region', () {
    for (final mood in KissCutVisualMood.values) {
      final geometry = KissCutGeometrySnapshot.fromState(
        KissCutStudyPose.forMood(mood),
        visualMoodOverride: mood,
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

  test('extreme deterministic inputs keep each pupil inside its eye', () {
    final random = Random(2917);
    for (var sample = 0; sample < 300; sample++) {
      final mood = KissCutVisualMood
          .values[random.nextInt(KissCutVisualMood.values.length)];
      final base = KissCutStudyPose.forMood(mood);
      final state = base.copyWith(
        gazeX: random.nextDouble() * 2 - 1,
        gazeY: random.nextDouble() * 2 - 1,
        pupilScale: 0.7 + random.nextDouble() * 0.5,
        leftEyelidOpen: 0.35 + random.nextDouble() * 0.65,
        rightEyelidOpen: 0.35 + random.nextDouble() * 0.65,
      );
      final geometry = KissCutGeometrySnapshot.fromState(
        state,
        visualMoodOverride: mood,
      );

      expect(geometry.left.pupilInsideEye, isTrue, reason: 'left $sample');
      expect(geometry.right.pupilInsideEye, isTrue, reason: 'right $sample');
      expect(geometry.contentRadiusFraction, lessThanOrEqualTo(0.36));
    }
  });

  test('identical renderer inputs produce equal immutable paint scenes', () {
    final state = KissCutStudyPose.forMood(KissCutVisualMood.curious);
    final first = KissCutPaintScene(
      fromState: state,
      toState: state,
      motionCurve: Curves.easeInOutCubic,
      displayShape: DisplayShape.circle,
      visualMoodOverride: KissCutVisualMood.curious,
    );
    final second = KissCutPaintScene(
      fromState: state,
      toState: state,
      motionCurve: Curves.easeInOutCubic,
      displayShape: DisplayShape.circle,
      visualMoodOverride: KissCutVisualMood.curious,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  for (final size in [64.0, 240.0]) {
    testWidgets('all moods paint without errors at ${size.toInt()} px', (
      tester,
    ) async {
      for (final mood in KissCutVisualMood.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.square(
                dimension: size,
                child: KissCutEyesView(
                  state: KissCutStudyPose.forMood(mood),
                  visualMoodOverride: mood,
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

  testWidgets('reduced motion freezes the Kiss Cut renderer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const MaterialApp(
              home: SizedBox.square(
                dimension: 240,
                child: ProceduralEyesView(
                  initialEmotion: EyeEmotion.neutral,
                  rendererVariant: EyeRendererVariant.kissCutV2,
                ),
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

    final painter = _kissCutPainter(tester);
    expect(painter.scene.fromState, painter.scene.toState);
    expect(painter.currentState.emotion, EyeEmotion.sleepy);
  });

  testWidgets('manual blink drives Kiss Cut and returns open', (tester) async {
    final container = await _pumpAnimatedKissCut(tester);

    container.read(eyePreviewControllerProvider.notifier).requestBlink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      _kissCutPainter(tester).currentState.motionPhase,
      anyOf(EyeMotionPhase.closing, EyeMotionPhase.closed),
    );

    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 30));
    final state = _kissCutPainter(tester).currentState;
    expect(state.eyelidOpen, greaterThan(0.8));
  });

  testWidgets('study surface compares renderers, moods, scale and motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const CharacterStudyScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('kiss_cut_eye_painter')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('study_renderer_legacy')));
    await tester.tap(find.byKey(const Key('study_renderer_legacy')));
    await tester.pump();
    expect(find.byKey(const Key('procedural_eyes_painter')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('study_renderer_kissCutV2')),
    );
    await tester.tap(find.byKey(const Key('study_renderer_kissCutV2')));
    await tester.ensureVisible(find.byKey(const Key('study_mood_flirty')));
    await tester.tap(find.byKey(const Key('study_mood_flirty')));
    await tester.ensureVisible(find.text('64 px'));
    await tester.tap(find.text('64 px'));
    await tester.pump();
    expect(find.byKey(const Key('kiss_cut_eye_painter')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('character_study_preview'))),
      const Size.square(64),
    );

    await tester.ensureVisible(find.byKey(const Key('study_double_blink')));
    await tester.tap(find.byKey(const Key('study_double_blink')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      _kissCutPainter(tester).currentState.motionPhase,
      isNot(EyeMotionPhase.idle),
    );
  });

  testWidgets('study surface remains usable on compact accessibility view', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 24, bottom: 24)
      ..viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3)),
            child: child!,
          ),
          home: const CharacterStudyScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('character_study_preview')), findsOneWidget);
    final finalControl = find.byKey(const Key('study_seed_42'));
    await tester.ensureVisible(finalControl);
    await tester.pump();
    expect(tester.getRect(finalControl).bottom, lessThanOrEqualTo(616));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Character Study launches both production asset clips', (
    tester,
  ) async {
    final definition = _productionDefinition();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productionEyeMotionDefinitionProvider.overrideWithValue(definition),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const CharacterStudyScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Built-in'), findsOneWidget);
    for (final clip in ChromeKissEyeClips.values) {
      expect(find.byKey(Key('study_clip_$clip')), findsOneWidget);
    }

    final productionSource = find.byKey(
      const Key('study_source_productionAsset'),
    );
    await tester.ensureVisible(productionSource);
    await tester.tap(productionSource);
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CharacterStudyScreen)),
    );
    for (final clip in ChromeKissProductionEyeClips.values) {
      final control = find.byKey(Key('study_clip_$clip'));
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump(const Duration(milliseconds: 16));
      expect(container.read(eyePreviewControllerProvider).clipName, clip);
    }

    expect(find.text('Production asset'), findsOneWidget);
  });
}

Future<ProviderContainer> _pumpAnimatedKissCut(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [eyeRandomProvider.overrideWithValue(Random(73))],
      child: const MaterialApp(
        home: SizedBox.square(
          dimension: 240,
          child: ProceduralEyesView(
            initialEmotion: EyeEmotion.neutral,
            rendererVariant: EyeRendererVariant.kissCutV2,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(
    tester.element(find.byType(ProceduralEyesView)),
  );
}

KissCutEyePainter _kissCutPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(const Key('kiss_cut_eye_painter')),
  );
  return paint.painter! as KissCutEyePainter;
}

EyeMotionDefinition _productionDefinition() {
  final decoded = decodeEyeMotionDefinition(
    File(BundledEyeMotionDefinitionLoader.productionAssetPath)
        .readAsStringSync(),
  );
  expect(decoded, isA<Ok<EyeMotionDefinition, EyeMotionFailure>>());
  return (decoded as Ok<EyeMotionDefinition, EyeMotionFailure>).value;
}
