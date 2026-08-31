import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_colors.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_info.dart';
import '../../infrastructure/device/virtual_device_engine.dart';
import '../../l10n/app_localizations.dart';
import '../shared/playful_background.dart';

final class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  static const routePath = '/devices';

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() =>
      _DeviceDiscoveryScreenState();
}

final class _DeviceDiscoveryScreenState
    extends ConsumerState<DeviceDiscoveryScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devices = ref.watch(discoveredDevicesProvider);
    final connection = ref.watch(connectionStateProvider).value;
    final command = ref.watch(deviceControllerProvider);

    ref.listen(connectionStateProvider, (previous, next) {
      if (next.value == DeviceConnectionStatus.ready && mounted) {
        context.go('/device/${VirtualDeviceEngine.deviceId}');
      }
    });
    ref.listen(deviceControllerProvider, (previous, next) {
      if (next.hasError && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.connectionError)));
      }
    });

    return Scaffold(
      body: PlayfulBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 42, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow(text: l10n.discoveryEyebrow),
                    const SizedBox(height: 14),
                    Text(
                      l10n.discoveryTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.discoverySubtitle,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 36),
                    devices.when(
                      data: (items) => _DeviceCard(
                        device: items.single,
                        connectionStatus: connection,
                        isBusy: command.isLoading,
                        onConnect: () => ref
                            .read(deviceControllerProvider.notifier)
                            .connect(items.single.id),
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stackTrace) => FilledButton(
                        onPressed: () =>
                            ref.invalidate(discoveredDevicesProvider),
                        child: Text(l10n.retry),
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

final class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.mint,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.25,
        ),
      ),
    );
  }
}

final class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.connectionStatus,
    required this.isBusy,
    required this.onConnect,
  });

  final DeviceInfo device;
  final DeviceConnectionStatus? connectionStatus;
  final bool isBusy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDiscovering =
        connectionStatus == DeviceConnectionStatus.discovering;
    final buttonText = isDiscovering
        ? l10n.discovering
        : isBusy
        ? l10n.connecting
        : l10n.connect;

    return Semantics(
      container: true,
      label: l10n.demoKeychain,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MiniKeychain(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.demoKeychain,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.batteryPercent(78),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.demoMode,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const Key('connect_button'),
              onPressed: isBusy ? null : onConnect,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MiniKeychain extends StatelessWidget {
  const _MiniKeychain();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amber, width: 10),
              ),
            ),
          ),
          Positioned(
            top: 45,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1213),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.coralDark, width: 8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_Eye(), SizedBox(width: 14), _Eye()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 7),
      child: const CircleAvatar(radius: 5, backgroundColor: AppColors.amber),
    );
  }
}
