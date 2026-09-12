import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'chrome_kiss_sparkle.dart';
import 'companion_home_tokens.dart';

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
    final home = context.companionHome;
    final l10n = AppLocalizations.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 14;

    return Container(
      key: const Key('chrome_kiss_bottom_navigation'),
      height: largeText ? 118 : 86,
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      decoration: BoxDecoration(
        color: home.glass,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: home.borderSubtle),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavigationItem(
                  icon: Icons.home_outlined,
                  label: l10n.homeTab,
                  selected:
                      selectedDestination == ChromeKissNavDestination.home,
                  selectedForeground: selectedForeground,
                  onPressed: onHome,
                ),
                _NavigationItem(
                  key: const Key('open_my_content_button'),
                  icon: Icons.favorite_border_rounded,
                  label: l10n.looksTab,
                  selected:
                      selectedDestination == ChromeKissNavDestination.looks,
                  selectedForeground: selectedForeground,
                  onPressed: onLooks,
                ),
                _NavigationItem(
                  sparkle: true,
                  label: l10n.ritualsTab,
                  selected:
                      selectedDestination == ChromeKissNavDestination.rituals,
                  selectedForeground: selectedForeground,
                  onPressed: onRituals,
                ),
                _NavigationItem(
                  key: const Key('simulator_settings_button'),
                  icon: Icons.person_outline_rounded,
                  label: l10n.profileTab,
                  selected:
                      selectedDestination == ChromeKissNavDestination.profile,
                  selectedForeground: selectedForeground,
                  onPressed: onProfile,
                ),
              ],
            ),
          ),
          Positioned(
            left: 118.5,
            bottom: -5,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: home.textPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const SizedBox(width: 116, height: 4),
              ),
            ),
          ),
        ],
      ),
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
    super.key,
  }) : assert(icon != null || sparkle);

  final IconData? icon;
  final String label;
  final bool sparkle;
  final bool selected;
  final Color? selectedForeground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final home = context.companionHome;
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 14;
    final enabled = selected || onPressed != null;
    final foreground = selected
        ? selectedForeground ?? home.ctaForeground
        : home.textSecondary;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: 76,
          height: largeText ? 96 : 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      home.lacquerHighlight,
                      home.lacquerPrimary,
                      home.lacquerMid,
                      home.lacquerDepth,
                    ],
                    stops: const [0, 0.34, 0.7, 1],
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              onTap: selected ? null : onPressed,
              borderRadius: BorderRadius.circular(32),
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
    );
  }
}
