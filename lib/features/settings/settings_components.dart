import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_snapshot.dart';
import '../../l10n/app_localizations.dart';

final class SettingsHeader extends StatelessWidget {
  const SettingsHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    return Row(
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              shape: CircleBorder(side: BorderSide(color: fidelity.chromeLine)),
              child: IconButton(
                key: const Key('settings_back_button'),
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: fidelity.accentInk,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsEyebrow,
                style: context.chromeKissText.status.copyWith(
                  color: fidelity.accentInk,
                  fontSize: 11,
                  letterSpacing: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.settingsTitle,
                style: context.chromeKissText.title.copyWith(
                  fontSize: 30,
                  height: 34 / 30,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class SettingsIdentityCard extends StatelessWidget {
  const SettingsIdentityCard({required this.snapshot, super.key});

  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final ready = snapshot.connectionStatus == DeviceConnectionStatus.ready;
    final status = settingsConnectionLabel(l10n, snapshot.connectionStatus);
    return Semantics(
      container: true,
      label:
          '${l10n.companionName}, ${snapshot.deviceId}, $status, '
          '${l10n.batteryPercent(snapshot.batteryPercent)}',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('settings_identity_card'),
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: fidelity.controlSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: fidelity.chromeLine),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: fidelity.lens,
                  shape: BoxShape.circle,
                  border: Border.all(color: fidelity.lacquer, width: 2),
                ),
                child: Image.asset(
                  'assets/chrome_kiss/home_look_original.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.companionName,
                      style: context.chromeKissText.body.copyWith(
                        fontSize: 18,
                        height: 22 / 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.deviceId,
                      maxLines: 2,
                      style: context.chromeKissText.body.copyWith(
                        color: fidelity.mutedInk,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          ready ? Icons.circle : Icons.circle_outlined,
                          color: ready
                              ? context.chromeKiss.success
                              : fidelity.mutedInk,
                          size: 9,
                        ),
                        Text(
                          '$status · ${l10n.percentValue(snapshot.batteryPercent)}',
                          style: context.chromeKissText.status.copyWith(
                            color: ready
                                ? context.chromeKiss.success
                                : fidelity.mutedInk,
                            fontSize: 11.5,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.chromeKissText.status.copyWith(
        color: context.chromeKissFidelity.mutedInk,
        fontSize: 10,
        height: 2,
        letterSpacing: 0.8,
      ),
    );
  }
}

final class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPressed,
    required this.semanticLabel,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onPressed;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    final foreground = enabled ? fidelity.ink : fidelity.mutedInk;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: fidelity.chromeLine),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: fidelity.lacquer.withValues(
                          alpha: enabled ? 1 : 0.45,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 34,
                        child: Icon(
                          icon,
                          color: context.chromeKiss.onAccent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.chromeKissText.body.copyWith(
                              color: foreground,
                              fontSize: 13,
                              height: 20 / 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            value,
                            style: context.chromeKissText.body.copyWith(
                              color: fidelity.mutedInk,
                              fontSize: 11,
                              height: 18 / 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: foreground,
                      size: 22,
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

String settingsConnectionLabel(
  AppLocalizations l10n,
  DeviceConnectionStatus status,
) {
  return switch (status) {
    DeviceConnectionStatus.ready => l10n.online,
    DeviceConnectionStatus.connecting => l10n.connecting,
    DeviceConnectionStatus.discovering => l10n.discovering,
    DeviceConnectionStatus.disconnecting => l10n.disconnecting,
    _ => l10n.disconnected,
  };
}
