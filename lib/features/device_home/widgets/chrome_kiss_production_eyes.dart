import 'package:flutter/material.dart';

import '../../../domain/eyes/eye_emotion.dart';
import 'kiss_cut_eye_renderer.dart';
import 'procedural_eyes_view.dart';

enum ChromeKissEyeScale {
  hero(Size(216, 112)),
  medium(Size(180, 93.33)),
  tiny(Size(54, 28));

  const ChromeKissEyeScale(this.size);

  final Size size;
}

final class ChromeKissProductionEyes extends StatelessWidget {
  const ChromeKissProductionEyes({
    required this.scale,
    required this.mood,
    required this.animate,
    required this.useProductionMotion,
    this.colourway = KissCutColourway.orchidLilac,
    super.key,
  });

  final ChromeKissEyeScale scale;
  final KissCutVisualMood mood;
  final bool animate;
  final bool useProductionMotion;
  final KissCutColourway colourway;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      key: Key('production_eyes_${scale.name}_${mood.name}'),
      size: scale.size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: scale.size.width,
          maxWidth: scale.size.width,
          minHeight: scale.size.width,
          maxHeight: scale.size.width,
          child: ProceduralEyesView(
            initialEmotion: _emotionFor(mood),
            animate: animate,
            rendererVariant: EyeRendererVariant.kissCutV21,
            kissCutVisualMoodOverride: mood,
            kissCutColourway: colourway,
            useProductionMotionDefinition: useProductionMotion,
          ),
        ),
      ),
    );
  }
}

EyeEmotion _emotionFor(KissCutVisualMood mood) {
  return switch (mood) {
    KissCutVisualMood.neutral || KissCutVisualMood.flirty => EyeEmotion.neutral,
    KissCutVisualMood.happy => EyeEmotion.happy,
    KissCutVisualMood.sleepy => EyeEmotion.sleepy,
    KissCutVisualMood.curious => EyeEmotion.curious,
    KissCutVisualMood.annoyed => EyeEmotion.annoyed,
    KissCutVisualMood.surprised => EyeEmotion.surprised,
  };
}
