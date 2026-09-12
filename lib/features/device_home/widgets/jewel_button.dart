import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import 'chrome_kiss_sparkle.dart';
import 'companion_home_tokens.dart';

enum JewelButtonStyle { standard, hero }

final class JewelButton extends StatefulWidget {
  const JewelButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.style = JewelButtonStyle.standard,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final JewelButtonStyle style;

  @override
  State<JewelButton> createState() => _JewelButtonState();
}

final class _JewelButtonState extends State<JewelButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(JewelButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onPressed != null;
    final pressDuration = reduceMotion || _pressed
        ? Duration.zero
        : motion.micro.duration;
    if (widget.style == JewelButtonStyle.hero) {
      return _buildHero(
        context,
        enabled: enabled,
        pressDuration: pressDuration,
        reduceMotion: reduceMotion,
      );
    }
    final lacquer = enabled || widget.busy
        ? colors.accentPrimary
        : Color.alphaBlend(
            colors.surfaceSecondary.withValues(alpha: 0.42),
            colors.accentPrimary,
          );
    final lacquerTop = Color.alphaBlend(
      colors.materialChrome.withValues(alpha: _pressed ? 0.1 : 0.2),
      lacquer,
    );
    final lacquerDepth = Color.alphaBlend(
      colors.lens.withValues(alpha: _pressed ? 0.18 : 0.11),
      lacquer,
    );
    final materialEdge = Color.alphaBlend(
      colors.materialChrome.withValues(alpha: 0.74),
      colors.lens,
    );
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(22),
      topRight: Radius.circular(13),
      bottomRight: Radius.circular(22),
      bottomLeft: Radius.circular(13),
    );
    const shape = RoundedRectangleBorder(borderRadius: borderRadius);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: reduceMotion || !_pressed ? 1 : 0.976,
          duration: pressDuration,
          curve: motion.micro.curve,
          child: AnimatedContainer(
            duration: pressDuration,
            curve: motion.micro.curve,
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: materialEdge, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: colors.lens.withValues(alpha: _pressed ? 0.12 : 0.2),
                  blurRadius: _pressed ? 5 : 10,
                  spreadRadius: -3,
                  offset: Offset(0, _pressed ? 2 : 6),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [lacquerTop, lacquer, lacquerDepth],
                    stops: const [0, 0.24, 1],
                  ),
                ),
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: shape,
                  onHighlightChanged: enabled
                      ? (pressed) => setState(() => _pressed = pressed)
                      : null,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 32,
                        right: 48,
                        child: AnimatedOpacity(
                          opacity: _pressed ? 0.45 : 1,
                          duration: pressDuration,
                          child: const _JewelHighlight(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 13, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                style: context.chromeKissText.label.copyWith(
                                  color: colors.onAccent.withValues(
                                    alpha: enabled || widget.busy ? 1 : 0.58,
                                  ),
                                  fontSize: 15.5,
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _JewelActionGlyph(
                              busy: widget.busy,
                              enabled: enabled,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context, {
    required bool enabled,
    required Duration pressDuration,
    required bool reduceMotion,
  }) {
    final colors = context.chromeKiss;
    final home = context.companionHome;
    final motion = context.chromeKissMotion;
    final foreground = home.ctaForeground.withValues(
      alpha: enabled || widget.busy ? 1 : 0.6,
    );
    const radius = BorderRadius.all(Radius.circular(36));
    const shape = RoundedRectangleBorder(borderRadius: radius);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: reduceMotion || !_pressed ? 1 : 0.982,
          duration: pressDuration,
          curve: motion.micro.curve,
          child: AnimatedContainer(
            duration: pressDuration,
            curve: motion.micro.curve,
            constraints: const BoxConstraints(minHeight: 72),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: colors.accentPrimary.withValues(alpha: 0.92),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7D45FF)
                      .withValues(alpha: _pressed ? 0.14 : 0.22),
                  blurRadius: _pressed ? 22 : 36,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: colors.accentPrimary.withValues(
                    alpha: _pressed ? 0.24 : 0.34,
                  ),
                  blurRadius: _pressed ? 16 : 24,
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      home.lacquerHighlight,
                      home.lacquerPrimary,
                      home.lacquerMid,
                      home.lacquerDepth,
                    ],
                    stops: const [0, 0.34, 0.7, 1],
                  ),
                ),
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: shape,
                  onHighlightChanged: enabled
                      ? (pressed) => setState(() => _pressed = pressed)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 28,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 24,
                              child: ChromeKissSparkle(color: foreground),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: context.chromeKissText.label.copyWith(
                              color: foreground,
                              fontSize: 18,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: widget.busy
                              ? Center(
                                  child: SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      color: foreground,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Text(
                                  '›',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: foreground,
                                    fontFamily: 'Manrope',
                                    fontSize: 30,
                                    height: 1,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _JewelHighlight extends StatelessWidget {
  const _JewelHighlight();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: context.chromeKiss.materialChrome.withValues(alpha: 0.7),
      ),
      child: const SizedBox(height: 1),
    );
  }
}

final class _JewelActionGlyph extends StatelessWidget {
  const _JewelActionGlyph({required this.busy, required this.enabled});

  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final glyphColor = colors.onAccent.withValues(
      alpha: enabled || busy ? 1 : 0.58,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onAccent.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: colors.onAccent.withValues(alpha: 0.14)),
      ),
      child: SizedBox.square(
        dimension: 31,
        child: Center(
          child: busy
              ? SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    color: glyphColor,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.arrow_forward_rounded, color: glyphColor, size: 19),
        ),
      ),
    );
  }
}
