import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'chrome_kiss_sparkle.dart';

enum ChromeKissNavDestination { home, looks, rituals, profile }

final class ChromeKissBottomNavigation extends StatelessWidget {
  const ChromeKissBottomNavigation({
    required this.onLooks,
    this.selectedDestination = ChromeKissNavDestination.home,
    this.selectedForeground,
    this.onHome,
    this.onRituals,
    this.onProfile,
    super.key,
  });

  final VoidCallback onLooks;
  final ChromeKissNavDestination selectedDestination;
  final Color? selectedForeground;
  final VoidCallback? onHome;
  final VoidCallback? onRituals;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final fidelity = context.chromeKissFidelity;
    final l10n = AppLocalizations.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final adaptive = largeText || constraints.maxWidth < 328;
        final items = <Widget>[
          _NavigationItem(
            icon: Icons.home_outlined,
            label: l10n.homeTab,
            selected: selectedDestination == ChromeKissNavDestination.home,
            selectedForeground: selectedForeground,
            onPressed: onHome,
            adaptive: adaptive,
          ),
          _NavigationItem(
            key: const Key('open_my_content_button'),
            icon: Icons.favorite_border_rounded,
            label: l10n.looksTab,
            selected: selectedDestination == ChromeKissNavDestination.looks,
            selectedForeground: selectedForeground,
            onPressed: onLooks,
            adaptive: adaptive,
          ),
          _NavigationItem(
            sparkle: true,
            label: l10n.ritualsTab,
            selected: selectedDestination == ChromeKissNavDestination.rituals,
            selectedForeground: selectedForeground,
            onPressed: onRituals,
            adaptive: adaptive,
          ),
          _NavigationItem(
            key: const Key('simulator_settings_button'),
            icon: Icons.person_outline_rounded,
            label: l10n.profileTab,
            selected: selectedDestination == ChromeKissNavDestination.profile,
            selectedForeground: selectedForeground,
            onPressed: onProfile,
            adaptive: adaptive,
          ),
        ];
        final indicator = IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fidelity.ink,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const SizedBox(width: 116, height: 4),
          ),
        );

        return Container(
          key: const Key('chrome_kiss_bottom_navigation'),
          height: adaptive ? null : 86,
          constraints: adaptive ? const BoxConstraints(minHeight: 86) : null,
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
          decoration: BoxDecoration(
            color: fidelity.glass,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: fidelity.chromeLine),
            boxShadow: [
              BoxShadow(
                color: colors.lens.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: adaptive ? 8 : 0),
                  child: Row(
                    mainAxisAlignment: adaptive
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: adaptive
                        ? [for (final item in items) Expanded(child: item)]
                        : items,
                  ),
                ),
              ),
              if (adaptive)
                Positioned(left: 0, right: 0, bottom: -5, child: indicator)
              else
                Positioned(left: 118.5, bottom: -5, child: indicator),
            ],
          ),
        );
      },
    );
  }
}

final class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    this.icon,
    this.sparkle = false,
    this.selected = false,
    this.selectedForeground,
    this.onPressed,
    this.adaptive = false,
    super.key,
  }) : assert(icon != null || sparkle);

  final IconData? icon;
  final String label;
  final bool sparkle;
  final bool selected;
  final Color? selectedForeground;
  final VoidCallback? onPressed;
  final bool adaptive;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 14;
    final enabled = selected || onPressed != null;
    final foreground = selected
        ? selectedForeground ?? fidelity.specular
        : fidelity.mutedInk;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: adaptive ? null : 76,
          height: adaptive ? null : (largeText ? 96 : 64),
          constraints: adaptive ? const BoxConstraints(minHeight: 64) : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: selected ? fidelity.lacquerGradient : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              onTap: selected ? null : onPressed,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: adaptive ? 2 : 0,
                  vertical: adaptive ? 8 : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sparkle)
                      SizedBox.square(
                        dimension: 23,
                        child: ChromeKissSparkle(color: foreground),
                      )
                    else
                      Icon(icon!, size: 23, color: foreground),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: context.chromeKissText.status.copyWith(
                        color: foreground,
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
