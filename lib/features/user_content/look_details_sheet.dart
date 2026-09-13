import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../domain/content/scene.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/jewel_button.dart';
import '../device_home/widgets/wardrobe_rail.dart';
import '../shared/chrome_kiss_material_sheet.dart';

enum LookDetailsAction { edit, delete }

final class LookDetailsSheet extends ConsumerStatefulWidget {
  const LookDetailsSheet({required this.scene, super.key});

  final Scene scene;

  @override
  ConsumerState<LookDetailsSheet> createState() => _LookDetailsSheetState();
}

final class _LookDetailsSheetState extends ConsumerState<LookDetailsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confirmationController;

  @override
  void initState() {
    super.initState();
    _confirmationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final snapshot = ref.watch(deviceSnapshotProvider).value;
    final command = ref.watch(deviceControllerProvider);
    final isActive = snapshot?.activeSceneId == widget.scene.id;
    final isUserLook = widget.scene.source == SceneSource.userGenerated;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    ref.listen(deviceSnapshotProvider, (previous, next) {
      final wasActive = previous?.value?.activeSceneId == widget.scene.id;
      final becameActive = next.value?.activeSceneId == widget.scene.id;
      if (!reduceMotion && !wasActive && becameActive) {
        _confirmationController.forward(from: 0);
      }
    });

    return ChromeKissMaterialSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          key: const Key('look_details_scroll'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        LookPreview(
                          key: const Key('look_details_preview'),
                          scene: widget.scene,
                          diameter: math.min(
                            218,
                            MediaQuery.sizeOf(context).width - 96,
                          ),
                          isSelected: isActive,
                          isActive: isActive,
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _LookConfirmationPainter(
                                animation: _confirmationController,
                                color: colors.accentOptical,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.scene.name,
                    textAlign: TextAlign.center,
                    style: context.chromeKissText.title.copyWith(fontSize: 23),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 15,
                        color: isActive
                            ? colors.accentOptical
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          isActive ? l10n.lookIsActive : l10n.lookReady,
                          textAlign: TextAlign.center,
                          style: context.chromeKissText.status.copyWith(
                            color: isActive
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  JewelButton(
                    key: Key('set_current_${widget.scene.id}'),
                    label: isActive ? l10n.lookIsWorn : l10n.wearLook,
                    busy: command.isLoading,
                    onPressed: isActive || command.isLoading
                        ? null
                        : () => ref
                              .read(deviceControllerProvider.notifier)
                              .setScene(widget.scene.id),
                  ),
                  if (isUserLook) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: Key('edit_${widget.scene.id}'),
                      onPressed: command.isLoading
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pop(LookDetailsAction.edit),
                      icon: const Icon(Icons.crop_rounded),
                      label: Text(l10n.editCrop),
                    ),
                    const SizedBox(height: 2),
                    TextButton.icon(
                      key: Key('delete_${widget.scene.id}'),
                      onPressed: command.isLoading
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pop(LookDetailsAction.delete),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.danger,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.delete),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LookConfirmationPainter extends CustomPainter {
  _LookConfirmationPainter({
    required Animation<double> animation,
    required this.color,
  }) : _animation = animation,
       _paint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 2.4,
       super(repaint: animation);

  final Animation<double> _animation;
  final Color color;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = _animation.value;
    if (progress == 0 || progress == 1) return;
    final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);
    _paint.color = color.withValues(alpha: opacity * 0.9);
    final radius = math.min(size.width, size.height) / 2 - 4;
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
      -math.pi / 2 + progress * math.pi * 1.3,
      math.pi * 0.28,
      false,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_LookConfirmationPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate._animation != _animation;
  }
}
