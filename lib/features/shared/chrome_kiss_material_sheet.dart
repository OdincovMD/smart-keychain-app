import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';

final class ChromeKissMaterialSheet extends StatelessWidget {
  const ChromeKissMaterialSheet({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 10, 24, 24),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: colors.divider.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: colors.lens.withValues(alpha: 0.24),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [
                        colors.materialChrome.withValues(alpha: 0.34),
                        colors.materialChrome.withValues(alpha: 0.86),
                        colors.materialChampagne.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 42, height: 4),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showChromeKissMaterialSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final colors = context.chromeKiss;
  final motion = context.chromeKissMotion;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: colors.lens.withValues(alpha: 0.72),
    sheetAnimationStyle: AnimationStyle(
      duration: reduceMotion ? Duration.zero : motion.transition.duration,
      reverseDuration: reduceMotion
          ? Duration.zero
          : motion.interaction.duration,
      curve: motion.transition.curve,
      reverseCurve: motion.interaction.curve,
    ),
    builder: builder,
  );
}
