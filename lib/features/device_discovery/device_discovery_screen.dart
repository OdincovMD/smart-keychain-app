import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_info.dart';
import '../../domain/device/device_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/jewel_button.dart';
import '../shared/playful_background.dart';
import 'pairing_presentation_state.dart';
import 'widgets/pairing_lens_stage.dart';

final class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  static const routePath = '/devices';

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() =>
      _DeviceDiscoveryScreenState();
}

final class _DeviceDiscoveryScreenState
    extends ConsumerState<DeviceDiscoveryScreen> {
  Timer? _homeTransitionTimer;
  bool _searchStarted = false;
  bool _connectionFailed = false;
  String? _connectedDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSearch();
    });
  }

  @override
  void dispose() {
    _homeTransitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(discoveredDevicesProvider);
    final connection = ref.watch(connectionStateProvider).value;
    final snapshot = ref.watch(deviceSnapshotProvider).value;
    final command = ref.watch(deviceControllerProvider);
    final items = devices.value;
    final device = items == null || items.isEmpty ? null : items.first;

    ref.listen(deviceSnapshotProvider, _handleSnapshot);
    ref.listen(deviceControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && !_connectionFailed) {
        setState(() => _connectionFailed = true);
      } else if (next.isLoading && _connectionFailed) {
        setState(() => _connectionFailed = false);
      }
    });

    final state = _resolvePresentationState(
      devices: devices,
      connection: connection,
      command: command,
      device: device,
    );

    return PairingDiscoveryView(
      state: state,
      batteryPercent: snapshot?.batteryPercent,
      onPrimaryAction: switch (state) {
        PairingPresentationState.idle => _startSearch,
        PairingPresentationState.found when device != null => () => _connect(
          device,
        ),
        PairingPresentationState.error => () => _retry(device),
        PairingPresentationState.searching ||
        PairingPresentationState.connecting ||
        PairingPresentationState.connected ||
        PairingPresentationState.found => null,
      },
    );
  }

  PairingPresentationState _resolvePresentationState({
    required AsyncValue<List<DeviceInfo>> devices,
    required DeviceConnectionStatus? connection,
    required AsyncValue<void> command,
    required DeviceInfo? device,
  }) {
    if (!_searchStarted) return PairingPresentationState.idle;
    if (_connectionFailed || devices.hasError) {
      return PairingPresentationState.error;
    }
    if (_connectedDeviceId != null) {
      return PairingPresentationState.connected;
    }
    if (command.isLoading ||
        connection == DeviceConnectionStatus.connecting ||
        connection == DeviceConnectionStatus.discovering ||
        connection == DeviceConnectionStatus.reconnecting) {
      return PairingPresentationState.connecting;
    }
    if (devices.isLoading) return PairingPresentationState.searching;
    if (device != null) return PairingPresentationState.found;
    return PairingPresentationState.error;
  }

  void _startSearch() {
    if (!mounted) return;
    setState(() {
      _searchStarted = true;
      _connectionFailed = false;
    });
  }

  void _connect(DeviceInfo device) {
    setState(() => _connectionFailed = false);
    ref.read(deviceControllerProvider.notifier).connect(device.id);
  }

  void _retry(DeviceInfo? device) {
    if (device == null) {
      setState(() => _connectionFailed = false);
      ref.invalidate(discoveredDevicesProvider);
      return;
    }
    _connect(device);
  }

  void _handleSnapshot(
    AsyncValue<DeviceSnapshot>? previous,
    AsyncValue<DeviceSnapshot> next,
  ) {
    final snapshot = next.value;
    if (!mounted ||
        snapshot?.connectionStatus != DeviceConnectionStatus.ready ||
        _connectedDeviceId != null) {
      return;
    }
    final readySnapshot = snapshot!;
    setState(() => _connectedDeviceId = readySnapshot.deviceId);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final delay = reduceMotion
        ? context.chromeKissMotion.interaction.duration
        : context.chromeKissMotion.delight.duration;
    _homeTransitionTimer = Timer(delay, () {
      if (mounted) context.go('/device/${readySnapshot.deviceId}');
    });
  }
}

final class PairingDiscoveryView extends StatelessWidget {
  const PairingDiscoveryView({
    required this.state,
    required this.onPrimaryAction,
    this.batteryPercent,
    super.key,
  });

  final PairingPresentationState state;
  final int? batteryPercent;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final stateCopy = _PairingStateCopy.resolve(l10n, state);
    final showDeviceMeta = switch (state) {
      PairingPresentationState.found ||
      PairingPresentationState.connecting ||
      PairingPresentationState.connected => true,
      _ => false,
    };

    return Scaffold(
      key: const Key('pairing_discovery_screen'),
      backgroundColor: colors.canvas,
      body: PlayfulBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 350
                  ? 18.0
                  : 24.0;
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final stageHeightFactor = textScale > 1.45 ? 0.34 : 0.4;
              final stageDiameter = math.min<double>(
                constraints.maxWidth - horizontalPadding * 2,
                math.min<double>(
                  318,
                  math.max<double>(
                    204,
                    constraints.maxHeight * stageHeightFactor,
                  ),
                ),
              );

              return SingleChildScrollView(
                key: const Key('pairing_scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  constraints.maxHeight < 700 ? 14 : 22,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CHROME KISS',
                          style: context.chromeKissText.status.copyWith(
                            color: colors.textSecondary,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 9),
                        AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : context.chromeKissMotion.interaction.duration,
                          child: SizedBox(
                            key: ValueKey('pairing_title_${state.name}'),
                            width: double.infinity,
                            child: Text(
                              stateCopy.title,
                              textAlign: TextAlign.start,
                              style: context.chromeKissText.display.copyWith(
                                fontSize: constraints.maxWidth < 350 ? 27 : 31,
                                height: 1.12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight < 700 ? 14 : 22),
                        Center(
                          child: PairingLensStage(
                            state: state,
                            diameter: stageDiameter,
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight < 700 ? 14 : 20),
                        Text(
                          stateCopy.body,
                          key: const Key('pairing_state_message'),
                          textAlign: TextAlign.center,
                          style: context.chromeKissText.body.copyWith(
                            color: state == PairingPresentationState.error
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 15,
                            height: 1.42,
                          ),
                        ),
                        if (showDeviceMeta) ...[
                          const SizedBox(height: 14),
                          _DevicePresenceLine(batteryPercent: batteryPercent),
                        ],
                        SizedBox(height: constraints.maxHeight < 700 ? 15 : 22),
                        if (state == PairingPresentationState.connected)
                          const _ConnectedConfirmation()
                        else
                          JewelButton(
                            key: const Key('connect_button'),
                            label: stateCopy.action,
                            busy: state == PairingPresentationState.connecting,
                            onPressed: onPrimaryAction,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.pairingDemoHint,
                          textAlign: TextAlign.center,
                          style: context.chromeKissText.status.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _DevicePresenceLine extends StatelessWidget {
  const _DevicePresenceLine({required this.batteryPercent});

  final int? batteryPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    return Semantics(
      container: true,
      label: [
        l10n.pairingVirtualKeychain,
        l10n.pairingDemoMarker,
        if (batteryPercent case final value?) l10n.batteryPercent(value),
      ].join(', '),
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 7,
          children: [
            Text(
              l10n.pairingVirtualKeychain,
              style: context.chromeKissText.label.copyWith(
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
            _OpticalSeparator(color: colors.materialChrome),
            Text(
              l10n.pairingDemoMarker,
              style: context.chromeKissText.status.copyWith(
                color: colors.warning,
                fontSize: 11,
              ),
            ),
            if (batteryPercent case final value?) ...[
              _OpticalSeparator(color: colors.materialChrome),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_5_bar_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$value%',
                    style: context.chromeKissText.status.copyWith(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _OpticalSeparator extends StatelessWidget {
  const _OpticalSeparator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 3),
    );
  }
}

final class _ConnectedConfirmation extends StatelessWidget {
  const _ConnectedConfirmation();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    return Semantics(
      liveRegion: true,
      label: l10n.pairingConnectedAction,
      child: ExcludeSemantics(
        child: Container(
          key: const Key('pairing_connected_confirmation'),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(13),
              bottomRight: Radius.circular(22),
              bottomLeft: Radius.circular(13),
            ),
            border: Border.all(
              color: colors.materialChrome.withValues(alpha: 0.74),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done_rounded, color: colors.success, size: 20),
              const SizedBox(width: 9),
              Text(
                l10n.pairingConnectedAction,
                style: context.chromeKissText.label.copyWith(
                  color: colors.textPrimary,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PairingStateCopy {
  const _PairingStateCopy({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;

  static _PairingStateCopy resolve(
    AppLocalizations l10n,
    PairingPresentationState state,
  ) {
    return switch (state) {
      PairingPresentationState.idle => _PairingStateCopy(
        title: l10n.pairingTitle,
        body: l10n.pairingIntro,
        action: l10n.pairingFindAction,
      ),
      PairingPresentationState.searching => _PairingStateCopy(
        title: l10n.pairingSearchingTitle,
        body: l10n.pairingSearchingBody,
        action: l10n.pairingSearchingTitle,
      ),
      PairingPresentationState.found => _PairingStateCopy(
        title: l10n.pairingFoundTitle,
        body: l10n.pairingFoundBody,
        action: l10n.connect,
      ),
      PairingPresentationState.connecting => _PairingStateCopy(
        title: l10n.pairingConnectingTitle,
        body: l10n.pairingConnectingBody,
        action: l10n.connecting,
      ),
      PairingPresentationState.connected => _PairingStateCopy(
        title: l10n.pairingConnectedTitle,
        body: l10n.pairingConnectedBody,
        action: l10n.pairingConnectedAction,
      ),
      PairingPresentationState.error => _PairingStateCopy(
        title: l10n.pairingErrorTitle,
        body: l10n.pairingErrorBody,
        action: l10n.retry,
      ),
    };
  }
}
