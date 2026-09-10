import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../l10n/app_localizations.dart';

final class ChromeKissBottomNavigation extends StatelessWidget {
  const ChromeKissBottomNavigation({
    required this.onLooks,
    this.onRituals,
    this.onProfile,
    super.key,
  });

  final VoidCallback onLooks;
  final VoidCallback? onRituals;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('chrome_kiss_bottom_navigation'),
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.surfaceSecondary.withValues(alpha: 0.9),
          colors.canvas,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colors.divider.withValues(alpha: 0.72),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.lens.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_rounded,
              label: l10n.homeTab,
              selected: true,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const Key('open_my_content_button'),
              icon: Icons.diamond_outlined,
              label: l10n.looksTab,
              onPressed: onLooks,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.auto_awesome_outlined,
              label: l10n.ritualsTab,
              onPressed: onRituals,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const Key('simulator_settings_button'),
              icon: Icons.person_outline_rounded,
              label: l10n.profileTab,
              onPressed: onProfile,
            ),
          ),
        ],
      ),
    );
  }
}

final class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final enabled = selected || onPressed != null;
    final foreground = selected
        ? colors.textPrimary
        : colors.textSecondary.withValues(alpha: enabled ? 0.92 : 0.54);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: selected
                ? Color.alphaBlend(
                    colors.accentPrimary.withValues(alpha: 0.24),
                    colors.surfaceSecondary,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: selected ? null : onPressed,
              borderRadius: BorderRadius.circular(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 7,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 22, color: foreground),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: context.chromeKissText.status.copyWith(
                          color: foreground,
                          fontSize: 10,
                          height: 1.15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
      ),
    );
  }
}
