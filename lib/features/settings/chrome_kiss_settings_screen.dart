import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_snapshot.dart';
import '../../domain/settings/app_appearance.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/appearance_controller.dart';
import '../device_home/widgets/brightness_control.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import '../shared/chrome_kiss_material_sheet.dart';
import 'appearance_screen.dart';
import 'settings_components.dart';

final class ChromeKissSettingsScreen extends ConsumerWidget {
  const ChromeKissSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(deviceSnapshotProvider);
    return Scaffold(
      body: ChromeKissFidelityFrame(
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: 0,
              width: 190,
              height: 150,
              child: _SettingsAtmosphere(),
            ),
            Positioned.fill(
              child: snapshot.when(
                data: (value) => _SettingsContent(
                  snapshot: value,
                  onBack: () => Navigator.of(context).pop(),
                  onAppearance: () => _showAppearance(context),
                  onBrightness: value.capabilities.supportsBrightness
                      ? () => _showBrightness(context)
                      : null,
                  onDeviceInformation: () =>
                      _showDeviceInformation(context, ref, value),
                ),
                loading: () => _SettingsUnavailable(
                  key: const Key('settings_loading'),
                  onBack: () => Navigator.of(context).pop(),
                  child: const CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => _SettingsUnavailable(
                  key: const Key('settings_snapshot_unavailable'),
                  onBack: () => Navigator.of(context).pop(),
                  child: FilledButton(
                    onPressed: () => ref.invalidate(deviceSnapshotProvider),
                    child: Text(AppLocalizations.of(context).retry),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAppearance(BuildContext context) async {
    await showChromeKissMaterialSheet<void>(
      context: context,
      builder: (context) =>
          const ChromeKissMaterialSheet(child: AppearanceScreen()),
    );
  }

  Future<void> _showBrightness(BuildContext context) async {
    await showChromeKissMaterialSheet<void>(
      context: context,
      builder: (context) =>
          const ChromeKissMaterialSheet(child: SettingsBrightnessSheet()),
    );
  }

  Future<void> _showDeviceInformation(
    BuildContext context,
    WidgetRef ref,
    DeviceSnapshot snapshot,
  ) async {
    final disconnect = await showChromeKissMaterialSheet<bool>(
      context: context,
      builder: (context) => ChromeKissMaterialSheet(
        child: DeviceInformationSheet(snapshot: snapshot),
      ),
    );
    if (disconnect != true || !context.mounted) return;
    ref.read(deviceControllerProvider.notifier).disconnect();
    Navigator.of(context).pop();
  }
}

final class _SettingsAtmosphere extends StatelessWidget {
  const _SettingsAtmosphere();

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.85, -0.72),
            radius: 1.05,
            colors: [
              fidelity.lacquer.withValues(alpha: 0.94),
              fidelity.lacquer.withValues(alpha: 0.28),
              fidelity.canvas.withValues(alpha: 0),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

final class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({
    required this.snapshot,
    required this.onBack,
    required this.onAppearance,
    required this.onBrightness,
    required this.onDeviceInformation,
  });

  final DeviceSnapshot snapshot;
  final VoidCallback onBack;
  final VoidCallback onAppearance;
  final VoidCallback? onBrightness;
  final VoidCallback onDeviceInformation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appearance = ref.watch(appAppearanceProvider);
    final command = ref.watch(deviceControllerProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final connected = snapshot.connectionStatus == DeviceConnectionStatus.ready;
    final connection = settingsConnectionLabel(l10n, snapshot.connectionStatus);
    return SingleChildScrollView(
      key: const Key('settings_screen_scroll'),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 12 + bottomInset),
      child: Column(
        key: const Key('production_settings_screen'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ChromeKissReferenceStatusBar(),
          const SizedBox(height: 28),
          SettingsHeader(onBack: onBack),
          const SizedBox(height: 18),
          SettingsIdentityCard(snapshot: snapshot),
          const SizedBox(height: 8),
          SettingsSectionLabel(l10n.settingsApplicationSection),
          const SizedBox(height: 2),
          SettingsActionRow(
            key: const Key('settings_appearance_row'),
            icon: Icons.auto_awesome_rounded,
            title: l10n.appearance,
            value: _appearanceLabel(l10n, appearance),
            semanticLabel:
                '${l10n.appearance}, ${_appearanceLabel(l10n, appearance)}',
            onPressed: onAppearance,
          ),
          const SizedBox(height: 10),
          SettingsActionRow(
            key: const Key('settings_brightness_row'),
            icon: Icons.light_mode_outlined,
            title: l10n.settingsBrightnessTitle,
            value: l10n.percentValue((snapshot.brightness * 100).round()),
            semanticLabel:
                '${l10n.settingsBrightnessTitle}, '
                '${l10n.percentValue((snapshot.brightness * 100).round())}',
            enabled: onBrightness != null && connected && !command.isLoading,
            onPressed: onBrightness ?? () {},
          ),
          const SizedBox(height: 8),
          SettingsSectionLabel(l10n.settingsDeviceSection),
          const SizedBox(height: 2),
          SettingsActionRow(
            key: const Key('settings_device_information_row'),
            icon: Icons.bluetooth_rounded,
            title: l10n.settingsConnectionTitle,
            value:
                '${l10n.companionName} $connection · '
                '${l10n.percentValue(snapshot.batteryPercent)}',
            semanticLabel:
                '${l10n.settingsConnectionTitle}, $connection, '
                '${l10n.batteryPercent(snapshot.batteryPercent)}',
            onPressed: onDeviceInformation,
          ),
          const SizedBox(height: 36),
          const Align(
            alignment: Alignment.bottomCenter,
            child: ChromeKissHomeIndicator(),
          ),
        ],
      ),
    );
  }
}

final class _SettingsUnavailable extends StatelessWidget {
  const _SettingsUnavailable({
    required this.onBack,
    required this.child,
    super.key,
  });

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ChromeKissReferenceStatusBar(),
          const SizedBox(height: 28),
          SettingsHeader(onBack: onBack),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

final class SettingsBrightnessSheet extends ConsumerStatefulWidget {
  const SettingsBrightnessSheet({super.key});

  @override
  ConsumerState<SettingsBrightnessSheet> createState() =>
      _SettingsBrightnessSheetState();
}

final class _SettingsBrightnessSheetState
    extends ConsumerState<SettingsBrightnessSheet> {
  bool _waitingForCommand = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(deviceSnapshotProvider).value;
    final command = ref.watch(deviceControllerProvider);
    ref.listen(deviceControllerProvider, (previous, next) {
      if (!_waitingForCommand || next.isLoading || !mounted) return;
      setState(() {
        _waitingForCommand = false;
        _failed = next.hasError;
      });
    });

    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final enabled =
        snapshot.connectionStatus == DeviceConnectionStatus.ready &&
        !command.isLoading;
    return Column(
      key: const Key('settings_brightness_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrightnessControl(
          key: ValueKey(_failed),
          value: snapshot.brightness,
          enabled: enabled,
          onChangeEnd: (value) {
            setState(() {
              _waitingForCommand = true;
              _failed = false;
            });
            ref.read(deviceControllerProvider.notifier).setBrightness(value);
          },
        ),
        if (_failed) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: l10n.settingsBrightnessFailure,
            child: Container(
              key: const Key('settings_brightness_failure'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.chromeKiss.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.chromeKiss.danger.withValues(alpha: 0.58),
                ),
              ),
              child: Text(
                l10n.settingsBrightnessFailure,
                style: context.chromeKissText.body.copyWith(fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

final class DeviceInformationSheet extends StatefulWidget {
  const DeviceInformationSheet({required this.snapshot, super.key});

  final DeviceSnapshot snapshot;

  @override
  State<DeviceInformationSheet> createState() => _DeviceInformationSheetState();
}

final class _DeviceInformationSheetState extends State<DeviceInformationSheet> {
  bool _confirmingDisconnect = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = widget.snapshot;
    final connection = settingsConnectionLabel(l10n, snapshot.connectionStatus);
    return Column(
      key: const Key('device_information_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsDeviceInformation,
          style: context.chromeKissText.title,
        ),
        const SizedBox(height: 16),
        _InformationValue(
          label: l10n.settingsDeviceIdentifier,
          value: snapshot.deviceId,
        ),
        _InformationValue(label: l10n.connected, value: connection),
        _InformationValue(
          label: l10n.settingsBattery,
          value: l10n.percentValue(snapshot.batteryPercent),
        ),
        _InformationValue(
          label: l10n.brightness,
          value: l10n.percentValue((snapshot.brightness * 100).round()),
        ),
        _InformationValue(
          label: l10n.settingsDisplay,
          value: l10n.settingsDisplayProfile(
            snapshot.displayProfile.width,
            snapshot.displayProfile.height,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : context.chromeKissMotion.interaction.duration,
          child: _confirmingDisconnect
              ? Container(
                  key: const Key('disconnect_confirmation'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.chromeKiss.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.chromeKiss.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.settingsDisconnectQuestion,
                        style: context.chromeKissText.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsDisconnectHint,
                        style: context.chromeKissText.body.copyWith(
                          color: context.chromeKiss.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _confirmingDisconnect = false),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            key: const Key('disconnect_confirm_button'),
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.chromeKiss.danger,
                              foregroundColor: context.chromeKiss.canvas,
                            ),
                            child: Text(l10n.confirmDisconnect),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  key: const Key('disconnect_button'),
                  onPressed:
                      snapshot.connectionStatus ==
                          DeviceConnectionStatus.disconnected
                      ? null
                      : () => setState(() => _confirmingDisconnect = true),
                  icon: const Icon(Icons.link_off_rounded, size: 20),
                  label: Text(l10n.disconnect),
                ),
        ),
      ],
    );
  }
}

final class _InformationValue extends StatelessWidget {
  const _InformationValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.chromeKiss.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.chromeKissText.body.copyWith(
                color: context.chromeKiss.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.chromeKissText.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

String _appearanceLabel(AppLocalizations l10n, AppAppearance appearance) {
  return switch (appearance) {
    AppAppearance.obsidian => l10n.appearanceObsidian,
    AppAppearance.pearl => l10n.appearancePearl,
    AppAppearance.system => l10n.appearanceSystem,
  };
}
