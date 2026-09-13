import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'companion_home_tokens.dart';

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
    final home = context.companionHome;
    final l10n = AppLocalizations.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(13) > 17;

    return Column(
      key: const Key('companion_identity_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: largeText
              ? const BoxConstraints(minHeight: 70)
              : const BoxConstraints.tightFor(height: 70),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: largeText ? MainAxisSize.min : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deviceHomeEyebrow,
                      style: context.chromeKissText.body.copyWith(
                        color: home.textSecondary,
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    Semantics(
                      label: '${l10n.companionName}, ${l10n.heartSymbolLabel}',
                      child: ExcludeSemantics(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            Text(
                              l10n.companionName,
                              style: TextStyle(
                                color: colors.accentPrimary,
                                fontFamily: 'GreatVibes',
                                fontSize: 38,
                                height: 1.08,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            Icon(
                              Icons.favorite_border_rounded,
                              color: colors.accentPrimary,
                              size: 29,
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
        ),
        SizedBox(height: largeText ? 12 : 6),
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
              horizontalPadding: 11,
            ),
            _StatusPill(
              key: const Key('battery_status_glyph'),
              icon: Icons.battery_5_bar_rounded,
              iconColor: colors.materialChampagne,
              label: l10n.percentValue(batteryPercent),
              semanticLabel: l10n.batteryPercent(batteryPercent),
              horizontalPadding: 10,
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
    final home = context.companionHome;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.brightness,
      child: ExcludeSemantics(
        child: Material(
          color: home.glass,
          shape: CircleBorder(side: BorderSide(color: home.borderSubtle)),
          child: SizedBox.square(
            dimension: 44,
            child: IconButton(
              key: const Key('brightness_settings_button'),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              tooltip: l10n.brightness,
              icon: const Icon(Icons.settings_outlined, size: 21),
              color: home.textSecondary,
            ),
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
    required this.horizontalPadding,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String semanticLabel;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final home = context.companionHome;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: home.glass,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: home.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon == Icons.circle)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 8),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox(width: 10, height: 14),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.chromeKissText.status.copyWith(
                  color: home.textPrimary,
                  fontSize: 12,
                  height: 1.34,
                  fontWeight: FontWeight.w500,
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
