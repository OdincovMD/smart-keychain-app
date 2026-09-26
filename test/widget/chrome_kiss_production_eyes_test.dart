import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/app/providers.dart';
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/eye_motion_ticker.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';
import 'package:smart_keychain_app/features/device_home/widgets/wardrobe_rail.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

void main() {
  testWidgets('Hero Medium and Tiny preserve the production size contract', (
    tester,
  ) async {
    for (final scale in ChromeKissEyeScale.values) {
      await _pumpEyes(
        tester,
        ChromeKissProductionEyes(
          scale: scale,
          mood: KissCutVisualMood.neutral,
          animate: false,
          useProductionMotion: false,
        ),
      );

      expect(
        tester.getSize(
          find.byKey(Key('production_eyes_${scale.name}_neutral')),
        ),
        scale.size,
      );
      final owner = tester.widget<ProceduralEyesView>(
        find.byType(ProceduralEyesView),
      );
      expect(owner.rendererVariant, EyeRendererVariant.kissCutV21);
      expect(owner.backgroundColor, KissCutEyePainter.lensColor);
      expect(owner.kissCutColourway, KissCutColourway.orchidLilac);
      expect(owner.kissCutVisualMoodOverride, KissCutVisualMood.neutral);
    }
  });

  testWidgets('all visual moods delegate to the V2.1 optical-glint painter', (
    tester,
  ) async {
    for (final mood in KissCutVisualMood.values) {
      await _pumpEyes(
        tester,
        ChromeKissProductionEyes(
          scale: ChromeKissEyeScale.tiny,
          mood: mood,
          animate: false,
          useProductionMotion: false,
        ),
      );

      final painter = _painter(tester);
      expect(painter.scene.style, KissCutRendererStyle.v21OpticalGlint);
      expect(painter.scene.visualMoodOverride, mood);
      expect(painter.scene.colourway, KissCutColourway.orchidLilac);
    }
  });

  testWidgets(
    'embedded production eyes can omit their rectangular background',
    (tester) async {
      await _pumpEyes(
        tester,
        const ChromeKissProductionEyes(
          scale: ChromeKissEyeScale.tiny,
          mood: KissCutVisualMood.neutral,
          animate: false,
          useProductionMotion: false,
          background: ChromeKissEyeBackground.transparent,
        ),
      );

      final owner = tester.widget<ProceduralEyesView>(
        find.byType(ProceduralEyesView),
      );
      expect(owner.backgroundColor, Colors.transparent);
    },
  );

  testWidgets('round LookPreview owns the lens behind embedded eyes', (
    tester,
  ) async {
    const previewKey = Key('round_eye_preview');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Center(
            child: LookPreview(
              key: previewKey,
              scene: Scene(
                id: 'embedded-eyes',
                name: 'Оригинал',
                source: SceneSource.builtIn,
                content: ProceduralEyesContent(
                  defaultEmotion: EyeEmotion.neutral,
                ),
              ),
              diameter: 75,
              isSelected: false,
              isActive: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byKey(previewKey));
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(previewKey),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, context.chromeKiss.lens);
    final eyes = tester.widget<ChromeKissProductionEyes>(
      find.descendant(
        of: find.byKey(previewKey),
        matching: find.byType(ChromeKissProductionEyes),
      ),
    );
    expect(eyes.background, ChromeKissEyeBackground.transparent);
  });

  testWidgets('Tiny static instances never start their runtime ticker', (
    tester,
  ) async {
    await _pumpEyes(
      tester,
      const ChromeKissProductionEyes(
        scale: ChromeKissEyeScale.tiny,
        mood: KissCutVisualMood.neutral,
        animate: false,
        useProductionMotion: false,
      ),
    );
    final ticker = _painter(tester).stateSource! as EyeMotionTicker;
    final initial = ticker.state;

    await tester.pump(const Duration(seconds: 8));

    expect(ticker.isTicking, isFalse);
    expect(ticker.state, initial);
  });

  testWidgets('reduced motion holds an animated production pose stable', (
    tester,
  ) async {
    final definition = _productionDefinition();
    await _pumpEyes(
      tester,
      const ChromeKissProductionEyes(
        scale: ChromeKissEyeScale.hero,
        mood: KissCutVisualMood.neutral,
        animate: true,
        useProductionMotion: true,
      ),
      disableAnimations: true,
      definition: definition,
    );
    final ticker = _painter(tester).stateSource! as EyeMotionTicker;
    final initial = ticker.state;

    await tester.pump(const Duration(seconds: 8));

    expect(ticker.isTicking, isFalse);
    expect(ticker.state, initial);
  });

  testWidgets('Home production eyes start on kiss-idle', (tester) async {
    final definition = _productionDefinition();
    await _pumpEyes(
      tester,
      const ChromeKissProductionEyes(
        scale: ChromeKissEyeScale.hero,
        mood: KissCutVisualMood.neutral,
        animate: true,
        useProductionMotion: true,
      ),
      definition: definition,
    );

    final ticker = _painter(tester).stateSource! as EyeMotionTicker;
    expect(ticker.player.definition, same(definition));
    expect(ticker.player.clipName, ChromeKissProductionEyeClips.kissIdle);
    expect(ticker.isTicking, isTrue);
  });
}

Future<void> _pumpEyes(
  WidgetTester tester,
  Widget eyes, {
  bool disableAnimations = false,
  EyeMotionDefinition? definition,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (definition != null)
          productionEyeMotionDefinitionProvider.overrideWithValue(definition),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: Center(child: eyes),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

KissCutEyePainter _painter(WidgetTester tester) {
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
