import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

final class PlayfulBackground extends StatelessWidget {
  const PlayfulBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Positioned(
          top: -100,
          right: -90,
          child: _Glow(color: AppColors.coral.withValues(alpha: 0.12)),
        ),
        Positioned(
          top: 310,
          left: -130,
          child: _Glow(color: AppColors.mint.withValues(alpha: 0.08)),
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
