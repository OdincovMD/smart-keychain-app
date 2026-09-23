import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/content/scene.dart';
import '../../domain/device/device_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import 'connection_recovery_controller.dart';
import 'widgets/chrome_kiss_production_eyes.dart';
import 'widgets/companion_stage.dart';
import 'widgets/jewel_button.dart';
import 'widgets/kiss_cut_eye_renderer.dart';

final class ConnectionRecoveryView extends StatefulWidget {
  const ConnectionRecoveryView({
    required this.status,
    required this.snapshot,
    required this.scene,
    required this.onRetry,
    required this.onReturnToDiscovery,
    super.key,
  });

  final ConnectionRecoveryStatus status;
  final DeviceSnapshot snapshot;
  final Scene scene;
  final VoidCallback onRetry;
  final VoidCallback onReturnToDiscovery;

  @override
  State<ConnectionRecoveryView> createState() => _ConnectionRecoveryViewState();
}

final class _ConnectionRecoveryViewState extends State<ConnectionRecoveryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rimController;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _rimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _syncRim();
  }

  @override
  void didUpdateWidget(ConnectionRecoveryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncRim();
  }

  void _syncRim() {
    if (widget.status == ConnectionRecoveryStatus.reconnecting &&
        _reduceMotion == false) {
      _rimController.repeat();
    } else {
      _rimController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _rimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reconnecting = widget.status == ConnectionRecoveryStatus.reconnecting;
    final l10n = AppLocalizations.of(context);
    return ChromeKissFidelityFrame(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const Key('connection_recovery_scroll'),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 12,
              ),
              child: IntrinsicHeight(
                child: Column(
                  key: Key(
                    reconnecting
                        ? 'connection_reconnecting_state'
                        : 'connection_disconnected_state',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ChromeKissReferenceStatusBar(),
                    const SizedBox(height: 10),
                    _RecoveryHeader(reconnecting: reconnecting),
                    const SizedBox(height: 10),
                    _RecoveryCompanion(
                      status: widget.status,
                      snapshot: widget.snapshot,
                      scene: widget.scene,
                      progress: _rimController,
                    ),
                    const SizedBox(height: 2),
                    _RecoveryCopy(reconnecting: reconnecting),
                    const Spacer(),
                    const SizedBox(height: 20),
                    if (reconnecting)
                      const _ReconnectingHint()
                    else ...[
                      JewelButton(
                        key: const Key('connection_retry_button'),
                        label: l10n.recoveryRetry,
                        style: JewelButtonStyle.hero,
                        onPressed: widget.onRetry,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const Key('connection_return_to_discovery'),
                        onPressed: widget.onReturnToDiscovery,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: context.chromeKiss.textPrimary,
                          side: BorderSide(color: context.chromeKiss.divider),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(l10n.recoveryReturnToDiscovery),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Align(child: ChromeKissHomeIndicator()),
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

final class _RecoveryHeader extends StatelessWidget {
  const _RecoveryHeader({required this.reconnecting});

  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.divider),
          ),
          child: Icon(
            reconnecting ? Icons.sync_rounded : Icons.link_off_rounded,
            color: colors.materialChrome,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.recoveryHeaderEyebrow,
                style: context.chromeKissText.status.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.companionName,
                style: context.chromeKissText.title.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        _StatusPill(reconnecting: reconnecting),
      ],
    );
  }
}

final class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.reconnecting});

  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);
    final label = reconnecting
        ? l10n.recoveryStatusReconnecting
        : l10n.recoveryStatusOffline;
    return Container(
      key: const Key('connection_recovery_status'),
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: reconnecting
                  ? colors.accentOptical
                  : colors.materialChampagne,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.chromeKissText.status.copyWith(
              color: colors.textPrimary,
              fontSize: 9.5,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }
}

final class _RecoveryCompanion extends StatelessWidget {
  const _RecoveryCompanion({
    required this.status,
    required this.snapshot,
    required this.scene,
    required this.progress,
  });

  final ConnectionRecoveryStatus status;
  final DeviceSnapshot snapshot;
  final Scene scene;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final reconnecting = status == ConnectionRecoveryStatus.reconnecting;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: reconnecting
          ? l10n.recoveryReconnectingSemantics
          : l10n.recoveryDisconnectedSemantics,
      child: ExcludeSemantics(
        child: Center(
          child: SizedBox(
            key: const Key('connection_recovery_companion'),
            width: 250,
            height: 305,
            child: Stack(
              children: [
                AnimatedOpacity(
                  opacity: reconnecting ? 1 : 0.62,
                  duration: reduceMotion
                      ? Duration.zero
                      : context.chromeKissMotion.interaction.duration,
                  child: CompanionStage(
                    scene: scene,
                    displayProfile: snapshot.displayProfile,
                    snapshot: snapshot,
                    diameter: 250,
                    jewelryMode: true,
                    visualStudyOverride: Center(
                      child: ChromeKissProductionEyes(
                        scale: ChromeKissEyeScale.hero,
                        mood: reconnecting
                            ? KissCutVisualMood.neutral
                            : KissCutVisualMood.sleepy,
                        animate: reconnecting,
                        useProductionMotion: reconnecting,
                      ),
                    ),
                  ),
                ),
                if (reconnecting)
                  Positioned(
                    left: 17,
                    top: 66,
                    width: 216,
                    height: 216,
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const Key('connection_recovery_rim'),
                        painter: _RecoveryRimPainter(
                          progress: progress,
                          accent: context.chromeKiss.accentPrimary,
                          optical: context.chromeKiss.accentOptical,
                          staticPose: reduceMotion,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _RecoveryCopy extends StatelessWidget {
  const _RecoveryCopy({required this.reconnecting});

  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);
    final name = l10n.companionName;
    return Column(
      children: [
        Text(
          reconnecting
              ? l10n.recoveryReconnectingTitle(name)
              : l10n.recoveryDisconnectedTitle(name),
          textAlign: TextAlign.center,
          style: context.chromeKissText.display.copyWith(fontSize: 36),
        ),
        const SizedBox(height: 8),
        Text(
          reconnecting
              ? l10n.recoveryReconnectingBody
              : l10n.recoveryDisconnectedBody,
          textAlign: TextAlign.center,
          style: context.chromeKissText.body.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

final class _ReconnectingHint extends StatelessWidget {
  const _ReconnectingHint();

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.recoveryHintSemantics,
      child: Container(
        key: const Key('connection_reconnecting_hint'),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: colors.accentOptical,
              size: 17,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                l10n.recoveryHint,
                textAlign: TextAlign.center,
                style: context.chromeKissText.label.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RecoveryRimPainter extends CustomPainter {
  const _RecoveryRimPainter({
    required this.progress,
    required this.accent,
    required this.optical,
    required this.staticPose,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color optical;
  final bool staticPose;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final strokeWidth = math.max(2.5, size.shortestSide * 0.016);
    final rect = bounds.deflate(strokeWidth * 1.4);
    final phase = staticPose ? -math.pi * 0.72 : progress.value * math.pi * 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        transform: GradientRotation(phase),
        colors: [
          accent.withValues(alpha: 0),
          accent,
          optical,
          accent.withValues(alpha: 0),
        ],
        stops: const [0, 0.42, 0.72, 1],
      ).createShader(rect);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * 2.2
      ..color = accent.withValues(alpha: 0.16)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 1.6);
    canvas.drawArc(rect, phase, math.pi * 1.22, false, glowPaint);
    canvas.drawArc(rect, phase, math.pi * 1.22, false, paint);

    final dotAngle = phase + math.pi * 1.22;
    final center = rect.center;
    final radius = rect.width / 2;
    final dot = Offset(
      center.dx + math.cos(dotAngle) * radius,
      center.dy + math.sin(dotAngle) * radius,
    );
    canvas.drawCircle(dot, strokeWidth * 1.45, Paint()..color = optical);
  }

  @override
  bool shouldRepaint(_RecoveryRimPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.optical != optical ||
      oldDelegate.staticPose != staticPose;
}
