import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/content/scene.dart';
import '../device_home/widgets/jewel_button.dart';
import '../device_home/widgets/wardrobe_rail.dart';
import 'look_application_controller.dart';

final class LookApplicationView extends StatefulWidget {
  const LookApplicationView({
    required this.scene,
    required this.status,
    required this.onRetry,
    required this.onReturn,
    super.key,
  });

  final Scene scene;
  final LookApplicationStatus status;
  final VoidCallback onRetry;
  final VoidCallback onReturn;

  @override
  State<LookApplicationView> createState() => _LookApplicationViewState();
}

final class _LookApplicationViewState extends State<LookApplicationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      _syncProgressAnimation();
    }
  }

  @override
  void didUpdateWidget(LookApplicationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncProgressAnimation();
  }

  void _syncProgressAnimation() {
    if (widget.status == LookApplicationStatus.applying &&
        _reduceMotion == false) {
      _progress.repeat();
    } else {
      _progress
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final copy = _copyFor(status, widget.scene.name);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final contentHeight = (screenHeight * 0.86).clamp(520.0, 730.0);

    return SizedBox(
      key: Key('look_${status.name}_state'),
      height: contentHeight,
      child: SingleChildScrollView(
        key: const Key('look_application_scroll'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: contentHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LifecycleHeading(copy: copy),
              const SizedBox(height: 16),
              Center(
                child: _ApplicationPreview(
                  scene: widget.scene,
                  status: status,
                  progress: _progress,
                ),
              ),
              const SizedBox(height: 16),
              _LifecycleMessage(status: status, copy: copy),
              const SizedBox(height: 14),
              if (status == LookApplicationStatus.applied)
                JewelButton(
                  key: const Key('close_applied_look'),
                  label: 'Вернуться в гардероб',
                  style: JewelButtonStyle.hero,
                  onPressed: widget.onReturn,
                )
              else if (status == LookApplicationStatus.failed) ...[
                JewelButton(
                  key: const Key('retry_apply_look'),
                  label: 'Попробовать снова',
                  style: JewelButtonStyle.hero,
                  onPressed: widget.onRetry,
                ),
                const SizedBox(height: 6),
                TextButton(
                  key: const Key('return_from_apply_error'),
                  onPressed: widget.onReturn,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Вернуться в гардероб'),
                ),
              ] else
                const _ApplyingHint(),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LifecycleCopy {
  const _LifecycleCopy({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.messageTitle,
    required this.message,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String messageTitle;
  final String message;
}

_LifecycleCopy _copyFor(LookApplicationStatus status, String sceneName) {
  return switch (status) {
    LookApplicationStatus.applying => _LifecycleCopy(
      eyebrow: 'ПРИМЕРЯЕМ ОБРАЗ',
      title: sceneName,
      subtitle: 'Передаём образ на ваш брелок',
      messageTitle: 'Брелок на связи',
      message:
          'Оставьте приложение открытым — это займёт совсем немного времени.',
    ),
    LookApplicationStatus.applied => _LifecycleCopy(
      eyebrow: 'ОБРАЗ НАДЕТ',
      title: sceneName,
      subtitle: 'Новый образ уже сияет на брелоке',
      messageTitle: 'Надето',
      message: 'Брелок подтвердил образ. Можно возвращаться к коллекции.',
    ),
    LookApplicationStatus.failed => const _LifecycleCopy(
      eyebrow: 'НЕ ПОЛУЧИЛОСЬ',
      title: 'Магия прервалась',
      subtitle: 'Брелок не смог принять образ',
      messageTitle: 'Образ не изменён',
      message:
          'Проверьте, что брелок рядом и подключён, затем попробуйте снова.',
    ),
    LookApplicationStatus.ready => throw StateError(
      'Ready state is rendered by LookDetailsReady.',
    ),
  };
}

final class _LifecycleHeading extends StatelessWidget {
  const _LifecycleHeading({required this.copy});

  final _LifecycleCopy copy;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Column(
      children: [
        Text(
          copy.eyebrow,
          textAlign: TextAlign.center,
          style: context.chromeKissText.status.copyWith(
            color: fidelity.accentInk,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          copy.title,
          textAlign: TextAlign.center,
          style: context.chromeKissText.display.copyWith(fontSize: 38),
        ),
        const SizedBox(height: 7),
        Text(
          copy.subtitle,
          textAlign: TextAlign.center,
          style: context.chromeKissText.body.copyWith(
            color: fidelity.mutedInk,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

final class _ApplicationPreview extends StatelessWidget {
  const _ApplicationPreview({
    required this.scene,
    required this.status,
    required this.progress,
  });

  final Scene scene;
  final LookApplicationStatus status;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final diameter = math.min(MediaQuery.sizeOf(context).width - 122, 214.0);
    final colors = context.chromeKiss;
    final semanticLabel = switch (status) {
      LookApplicationStatus.applying => 'Образ передаётся на брелок',
      LookApplicationStatus.applied => 'Брелок подтвердил новый образ',
      LookApplicationStatus.failed => 'Передать образ не удалось',
      LookApplicationStatus.ready => '',
    };
    return Semantics(
      key: const Key('look_application_progress'),
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: diameter + 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ApplicationRingPainter(
                    progress: progress,
                    status: status,
                    accent: colors.accentPrimary,
                    optical: colors.accentOptical,
                    success: colors.success,
                    danger: colors.danger,
                    track: colors.divider,
                  ),
                ),
              ),
              LookPreview(
                key: const Key('look_details_preview'),
                scene: scene,
                diameter: diameter,
                isSelected: status == LookApplicationStatus.applied,
                isActive: status == LookApplicationStatus.applied,
              ),
              if (status
                  case LookApplicationStatus.applied ||
                      LookApplicationStatus.failed)
                Positioned(
                  right: 2,
                  bottom: 30,
                  child: _StatusSeal(status: status),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatusSeal extends StatelessWidget {
  const _StatusSeal({required this.status});

  final LookApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final applied = status == LookApplicationStatus.applied;
    final color = applied ? colors.success : colors.danger;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.26), blurRadius: 18),
        ],
      ),
      child: Icon(
        applied ? Icons.check_rounded : Icons.priority_high_rounded,
        color: color,
        size: 27,
      ),
    );
  }
}

final class _LifecycleMessage extends StatelessWidget {
  const _LifecycleMessage({required this.status, required this.copy});

  final LookApplicationStatus status;
  final _LifecycleCopy copy;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final fidelity = context.chromeKissFidelity;
    final color = switch (status) {
      LookApplicationStatus.applied => colors.success,
      LookApplicationStatus.failed => colors.danger,
      _ => fidelity.accentInk,
    };
    final icon = switch (status) {
      LookApplicationStatus.applied => Icons.check_circle_outline_rounded,
      LookApplicationStatus.failed => Icons.error_outline_rounded,
      _ => Icons.bluetooth_connected_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fidelity.controlSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.58)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.messageTitle,
                  style: context.chromeKissText.label.copyWith(color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  copy.message,
                  style: context.chromeKissText.body.copyWith(
                    color: fidelity.mutedInk,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ApplyingHint extends StatelessWidget {
  const _ApplyingHint();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ожидание подтверждения от брелока',
      child: Text(
        'Ждём подтверждения от брелока',
        textAlign: TextAlign.center,
        style: context.chromeKissText.status.copyWith(
          color: context.chromeKissFidelity.mutedInk,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}

final class _ApplicationRingPainter extends CustomPainter {
  _ApplicationRingPainter({
    required this.progress,
    required this.status,
    required this.accent,
    required this.optical,
    required this.success,
    required this.danger,
    required this.track,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final LookApplicationStatus status;
  final Color accent;
  final Color optical;
  final Color success;
  final Color danger;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = track.withValues(alpha: 0.8);
    canvas.drawCircle(center, radius, base);

    switch (status) {
      case LookApplicationStatus.applying:
        final phase = progress.value * math.pi * 2;
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..color = accent.withValues(alpha: 0.23);
        final arc = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.2
          ..shader = SweepGradient(
            colors: [accent, optical, accent.withValues(alpha: 0.12)],
          ).createShader(rect);
        canvas
          ..drawArc(rect, phase - math.pi / 2, math.pi * 0.82, false, glow)
          ..drawArc(rect, phase - math.pi / 2, math.pi * 0.82, false, arc)
          ..drawArc(rect, phase + math.pi * 0.68, math.pi * 0.2, false, arc);
      case LookApplicationStatus.applied:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = success;
        canvas.drawCircle(center, radius, paint);
        for (final angle in const [0.2, 1.7, 3.2, 4.8]) {
          final point =
              center + Offset(math.cos(angle), math.sin(angle)) * radius;
          canvas.drawCircle(point, 2.5, Paint()..color = optical);
        }
      case LookApplicationStatus.failed:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3
          ..color = danger;
        canvas
          ..drawArc(rect, -math.pi * 0.43, math.pi * 0.64, false, paint)
          ..drawArc(rect, math.pi * 0.4, math.pi * 0.76, false, paint);
      case LookApplicationStatus.ready:
        break;
    }
  }

  @override
  bool shouldRepaint(_ApplicationRingPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.accent != accent ||
        oldDelegate.optical != optical ||
        oldDelegate.success != success ||
        oldDelegate.danger != danger ||
        oldDelegate.track != track ||
        oldDelegate.progress != progress;
  }
}
