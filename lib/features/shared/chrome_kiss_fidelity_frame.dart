import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chrome_kiss_fidelity_tokens.dart';

/// Phone-shaped pearl canvas used by the Figma fidelity screens.
final class ChromeKissFidelityFrame extends StatelessWidget {
  const ChromeKissFidelityFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChromeKissFidelityTokens.outside,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            constraints.maxWidth,
            ChromeKissFidelityTokens.referenceSize.width,
          );
          final radius = width >= 380 ? 48.0 : 36.0;
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ChromeKissFidelityTokens.canvas,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: ChromeKissFidelityTokens.chromeLine,
                  ),
                ),
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Draws the Figma status symbols only in zero-inset renderers such as goldens.
final class ChromeKissReferenceStatusBar extends StatelessWidget {
  const ChromeKissReferenceStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewPaddingOf(context).top > 0) {
      return const SizedBox(height: 44);
    }
    return const SizedBox(
      height: 44,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 14,
            child: Text(
              '9:41',
              style: TextStyle(
                color: ChromeKissFidelityTokens.ink,
                fontFamily: 'Manrope',
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(left: 127, top: 10, child: _DynamicIsland()),
          Positioned(right: 24, top: 17, child: _StatusGlyphs()),
        ],
      ),
    );
  }
}

final class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: ChromeKissFidelityTokens.lens,
        borderRadius: BorderRadius.all(Radius.circular(13)),
      ),
      child: SizedBox(width: 104, height: 24),
    );
  }
}

final class _StatusGlyphs extends StatelessWidget {
  const _StatusGlyphs();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final height in <double>[10, 11, 12]) ...[
          DecoratedBox(
            decoration: const BoxDecoration(
              color: ChromeKissFidelityTokens.ink,
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
            child: SizedBox(width: 3, height: height),
          ),
          const SizedBox(width: 6),
        ],
        const Icon(
          Icons.bolt_rounded,
          size: 11,
          color: ChromeKissFidelityTokens.ink,
        ),
        const SizedBox(width: 4),
        const DecoratedBox(
          decoration: BoxDecoration(
            color: ChromeKissFidelityTokens.ink,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          child: SizedBox(width: 13, height: 7),
        ),
      ],
    );
  }
}

final class ChromeKissHomeIndicator extends StatelessWidget {
  const ChromeKissHomeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewPaddingOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: ChromeKissFidelityTokens.ink,
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      child: SizedBox(width: 116, height: 4),
    );
  }
}

final class ChromeKissScriptHeartText extends StatelessWidget {
  const ChromeKissScriptHeartText({
    required this.text,
    this.fontSize = 22,
    this.centered = false,
    super.key,
  });

  final String text;
  final double fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.favorite_border_rounded,
              size: fontSize * 0.72,
              color: ChromeKissFidelityTokens.accentInk,
            ),
          ),
        ],
      ),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      softWrap: true,
      style: ChromeKissFidelityTokens.scriptStyle.copyWith(fontSize: fontSize),
    );
  }
}
