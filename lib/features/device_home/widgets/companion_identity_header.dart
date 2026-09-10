import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../l10n/app_localizations.dart';

final class CompanionIdentityHeader extends StatelessWidget {
  const CompanionIdentityHeader({
    required this.connectionLabel,
    required this.connected,
    required this.batteryPercent,
    required this.onSettings,
    super.key,
  });

  final String connectionLabel;
  final bool connected;
  final int batteryPercent;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const Key('companion_identity_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deviceHomeEyebrow,
                    style: context.chromeKissText.body.copyWith(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Semantics(
                    label: '${l10n.companionName}, ${l10n.heartSymbolLabel}',
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.companionName,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontFamily: 'GreatVibes',
                              fontSize: 38,
                              height: 1.08,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.favorite_border_rounded,
                            color: colors.textPrimary,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _SettingsButton(onPressed: onSettings),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _StatusPill(
              key: const Key('connection_status_glyph'),
              icon: Icons.circle,
              iconColor: connected ? colors.success : colors.textSecondary,
              label: connected ? l10n.online : connectionLabel,
              semanticLabel: connectionLabel,
            ),
            _StatusPill(
              key: const Key('battery_status_glyph'),
              icon: Icons.battery_5_bar_rounded,
              iconColor: colors.materialChampagne,
              label: l10n.percentValue(batteryPercent),
              semanticLabel: l10n.batteryPercent(batteryPercent),
            ),
          ],
        ),
      ],
    );
  }
}

final class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.brightness,
      child: ExcludeSemantics(
        child: Material(
          color: colors.surfaceSecondary.withValues(alpha: 0.86),
          shape: CircleBorder(
            side: BorderSide(color: colors.divider.withValues(alpha: 0.82)),
          ),
          child: IconButton(
            key: const Key('brightness_settings_button'),
            onPressed: onPressed,
            tooltip: l10n.brightness,
            icon: const Icon(Icons.settings_outlined, size: 21),
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

final class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: colors.divider.withValues(alpha: 0.72),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: icon == Icons.circle ? 7 : 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.chromeKissText.status.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
