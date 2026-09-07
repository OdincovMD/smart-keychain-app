import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';

enum StatusGlyphTone { connected, battery, neutral }

final class StatusGlyph extends StatelessWidget {
  const StatusGlyph({
    required this.value,
    required this.semanticLabel,
    required this.tone,
    super.key,
  });

  final String value;
  final String semanticLabel;
  final StatusGlyphTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final accent = switch (tone) {
      StatusGlyphTone.connected => colors.success,
      StatusGlyphTone.battery => colors.materialChampagne,
      StatusGlyphTone.neutral => colors.textSecondary,
    };
    final icon = switch (tone) {
      StatusGlyphTone.connected => Icons.circle,
      StatusGlyphTone.battery => Icons.battery_5_bar_rounded,
      StatusGlyphTone.neutral => Icons.link_off_rounded,
    };

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: tone == StatusGlyphTone.connected ? 9 : 15,
                child: Center(
                  child: Icon(
                    icon,
                    color: accent.withValues(alpha: 0.9),
                    size: tone == StatusGlyphTone.connected ? 6.5 : 14,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                value,
                style: context.chromeKissText.status.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
