import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';

final class PlayfulBackground extends StatelessWidget {
  const PlayfulBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.canvas),
        Positioned(
          top: -100,
          right: -90,
          child: _Glow(color: colors.accentPrimary.withValues(alpha: 0.09)),
        ),
        Positioned(
          top: 310,
          left: -130,
          child: _Glow(color: colors.accentOptical.withValues(alpha: 0.07)),
        ),
        child,
      ],
    );
  }
}

final class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
