import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import 'chrome_kiss_production_eyes.dart';
import 'kiss_cut_eye_renderer.dart';

enum ChromeKissEyeReactionLensSize {
  tiny(
    eyeScale: ChromeKissEyeScale.tiny,
    outerSize: Size(68, 40),
    outerInset: 4,
    rimWidth: 1.1,
    glowBlur: 13,
  ),
  medium(
    eyeScale: ChromeKissEyeScale.medium,
    outerSize: Size(204, 117),
    outerInset: 6,
    rimWidth: 1.4,
    glowBlur: 22,
  );

  const ChromeKissEyeReactionLensSize({
    required this.eyeScale,
    required this.outerSize,
    required this.outerInset,
    required this.rimWidth,
    required this.glowBlur,
  });

  final ChromeKissEyeScale eyeScale;
  final Size outerSize;
  final double outerInset;
  final double rimWidth;
  final double glowBlur;
}

/// Presentation-only jewel lens for a secondary Chrome Kiss reaction.
///
/// The component clips the existing production renderer; it does not own an
/// eye runtime or alter Kiss Cut V2.1 anatomy.
final class ChromeKissEyeReactionLens extends StatelessWidget {
  const ChromeKissEyeReactionLens({
    required this.size,
    required this.mood,
    required this.animate,
    required this.useProductionMotion,
    this.colourway = KissCutColourway.orchidLilac,
    this.reactionKey,
    super.key,
  });

  final ChromeKissEyeReactionLensSize size;
  final KissCutVisualMood mood;
  final bool animate;
  final bool useProductionMotion;
  final KissCutColourway colourway;
  final Key? reactionKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final fidelity = context.chromeKissFidelity;
    final radius = BorderRadius.circular(size.outerSize.height / 2);

    return SizedBox.fromSize(
      size: size.outerSize,
      child: Padding(
        padding: EdgeInsets.all(size.outerInset),
        child: DecoratedBox(
          key: Key('chrome_kiss_reaction_lens_${size.name}'),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fidelity.chromeLine,
                colors.accentOptical.withValues(alpha: 0.92),
                fidelity.lacquer.withValues(alpha: 0.84),
                fidelity.chromeLine,
              ],
              stops: const [0, 0.32, 0.7, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: fidelity.lacquer.withValues(alpha: 0.2),
                blurRadius: size.glowBlur,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: colors.accentOptical.withValues(alpha: 0.16),
                blurRadius: size.glowBlur * 0.72,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size.rimWidth),
            child: ClipRRect(
              key: Key('chrome_kiss_reaction_lens_clip_${size.name}'),
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: fidelity.lensGradient,
                      border: Border.all(
                        color: fidelity.lensBorder,
                        width: 0.7,
                      ),
                    ),
                  ),
                  Center(
                    child: ChromeKissProductionEyes(
                      key: reactionKey,
                      scale: size.eyeScale,
                      mood: mood,
                      animate: animate,
                      useProductionMotion: useProductionMotion,
                      colourway: colourway,
                      background: ChromeKissEyeBackground.transparent,
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-0.8, -1),
                          end: const Alignment(0.35, 0.65),
                          colors: [
                            fidelity.specular.withValues(alpha: 0.15),
                            fidelity.specular.withValues(alpha: 0.025),
                            fidelity.specular.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.22, 0.52],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
