import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/image/crop_spec.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/jewel_button.dart';
import 'create_look_editor_flow.dart';
import 'image_editor_controller.dart';

enum ImageEditorMode { create, edit }

typedef ImageEditorSaveCallback = Future<bool> Function(CropSpec cropSpec);

final class ImageEditorScreen extends ConsumerStatefulWidget {
  const ImageEditorScreen({
    required this.assetId,
    required this.originalBytes,
    this.initialCropSpec = CropSpec.centered,
    this.mode = ImageEditorMode.create,
    this.onSave,
    super.key,
  });

  final String assetId;
  final Uint8List originalBytes;
  final CropSpec initialCropSpec;
  final ImageEditorMode mode;
  final ImageEditorSaveCallback? onSave;

  @override
  ConsumerState<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

final class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  late final ImageEditorSession _session;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _session = ImageEditorSession(
      assetId: widget.assetId,
      initialCropSpec: widget.initialCropSpec,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == ImageEditorMode.create) {
      return CreateLookEditorFlow(
        session: _session,
        originalBytes: widget.originalBytes,
        processing: _processing,
        onCancel: () => Navigator.of(context).pop(),
        onSave: _save,
      );
    }

    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final title = l10n.adjustLookCrop;
    final saveLabel = l10n.saveLookChanges;

    return Scaffold(
      key: const Key('image_editor_screen'),
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 350 ? 18.0 : 22.0;
            final previewDiameter = math.min<double>(
              constraints.maxWidth - horizontalPadding * 2,
              math.min<double>(
                360,
                math.max<double>(232, constraints.maxHeight * 0.47),
              ),
            );

            return SingleChildScrollView(
              key: const Key('image_editor_scroll'),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EditorHeader(
                        title: title,
                        enabled: !_processing,
                        onCancel: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: AnimatedOpacity(
                          opacity: _processing ? 0.82 : 1,
                          duration: reduceMotion
                              ? Duration.zero
                              : motion.interaction.duration,
                          curve: motion.interaction.curve,
                          child: SizedBox.square(
                            dimension: previewDiameter,
                            child: _CircularCropLens(
                              session: _session,
                              originalBytes: widget.originalBytes,
                              enabled: !_processing,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.imageEditorHint,
                        textAlign: TextAlign.center,
                        style: context.chromeKissText.body.copyWith(
                          color: colors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 24,
                        child: Semantics(
                          liveRegion: true,
                          label: _processing ? l10n.preparingLook : null,
                          child: ExcludeSemantics(
                            child: AnimatedOpacity(
                              opacity: _processing ? 1 : 0,
                              duration: reduceMotion
                                  ? Duration.zero
                                  : motion.micro.duration,
                              child: Text(
                                l10n.preparingLook,
                                key: const Key('image_editor_processing_label'),
                                textAlign: TextAlign.center,
                                style: context.chromeKissText.status.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EditorTools(
                        enabled: !_processing,
                        onRotate: () => ref
                            .read(
                              imageEditorControllerProvider(_session).notifier,
                            )
                            .rotateQuarterTurn(),
                        onReset: () => ref
                            .read(
                              imageEditorControllerProvider(_session).notifier,
                            )
                            .reset(),
                      ),
                      const SizedBox(height: 20),
                      JewelButton(
                        key: const Key('image_editor_save'),
                        label: _processing ? l10n.preparingLook : saveLabel,
                        busy: _processing,
                        onPressed: _processing ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_processing) return;
    final crop = ref.read(imageEditorControllerProvider(_session));
    final save = widget.onSave;
    if (save == null) {
      Navigator.of(context).pop(crop);
      return;
    }
    setState(() => _processing = true);
    final succeeded = await save(crop);
    if (!mounted) return;
    Navigator.of(context).pop(succeeded);
  }
}

final class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.title,
    required this.enabled,
    required this.onCancel,
  });

  final String title;
  final bool enabled;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EditorIconControl(
          key: const Key('image_editor_cancel'),
          semanticLabel: AppLocalizations.of(context).cancel,
          enabled: enabled,
          onPressed: onCancel,
          icon: Icons.arrow_back_rounded,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: context.chromeKissText.title.copyWith(fontSize: 23),
          ),
        ),
      ],
    );
  }
}

final class _CircularCropLens extends ConsumerStatefulWidget {
  const _CircularCropLens({
    required this.session,
    required this.originalBytes,
    required this.enabled,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final bool enabled;

  @override
  ConsumerState<_CircularCropLens> createState() => _CircularCropLensState();
}

final class _CircularCropLensState extends ConsumerState<_CircularCropLens> {
  CropSpec _gestureStart = CropSpec.centered;
  Offset _gestureFocalStart = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final crop = ref.watch(imageEditorControllerProvider(widget.session));
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      image: true,
      label: l10n.imageCropPreview,
      hint: l10n.imageCropGestureHint,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: GestureDetector(
                  key: const Key('image_crop_gesture'),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: widget.enabled
                      ? (details) {
                          _gestureStart = crop;
                          _gestureFocalStart = details.localFocalPoint;
                        }
                      : null,
                  onScaleUpdate: widget.enabled
                      ? (details) {
                          final delta =
                              details.localFocalPoint - _gestureFocalStart;
                          final size = context.size;
                          if (size == null || size.isEmpty) return;
                          ref
                              .read(
                                imageEditorControllerProvider(widget.session)
                                    .notifier,
                              )
                              .applyGesture(
                                start: _gestureStart,
                                deltaX: delta.dx / size.width,
                                deltaY: delta.dy / size.height,
                                scaleFactor: details.scale,
                              );
                        }
                      : null,
                  child: ColoredBox(
                    color: colors.lens,
                    child: Transform.rotate(
                      angle: crop.rotation,
                      child: Transform.scale(
                        scale: crop.scale,
                        child: FractionalTranslation(
                          translation: Offset(
                            (0.5 - crop.centerX) * 2,
                            (0.5 - crop.centerY) * 2,
                          ),
                          child: Image.memory(
                            widget.originalBytes,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                            cacheWidth: 1024,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CropBoundaryPainter(
                        dimColor: colors.lens.withValues(alpha: 0.43),
                        edgeColor: colors.materialChrome,
                        highlightColor: colors.accentOptical,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EditorTools extends StatelessWidget {
  const _EditorTools({
    required this.enabled,
    required this.onRotate,
    required this.onReset,
  });

  final bool enabled;
  final VoidCallback onRotate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final controls = [
          _EditorToolControl(
            key: const Key('image_editor_rotate'),
            label: l10n.rotate,
            icon: Icons.rotate_90_degrees_ccw_rounded,
            enabled: enabled,
            onPressed: onRotate,
          ),
          _EditorToolControl(
            key: const Key('image_editor_reset'),
            label: l10n.reset,
            icon: Icons.restart_alt_rounded,
            enabled: enabled,
            onPressed: onReset,
          ),
        ];
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              controls.first,
              const SizedBox(height: 10),
              controls.last,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: controls.first),
            const SizedBox(width: 12),
            Expanded(child: controls.last),
          ],
        );
      },
    );
  }
}

final class _EditorToolControl extends StatelessWidget {
  const _EditorToolControl({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Color.alphaBlend(
            colors.surfaceSecondary.withValues(alpha: 0.72),
            colors.canvas,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(11),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(11),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(11),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(11),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.materialChrome.withValues(
                    alpha: enabled ? 0.46 : 0.2,
                  ),
                  width: 0.8,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: colors.textPrimary.withValues(
                      alpha: enabled ? 1 : 0.42,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.chromeKissText.label.copyWith(
                        color: colors.textPrimary.withValues(
                          alpha: enabled ? 1 : 0.42,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _EditorIconControl extends StatelessWidget {
  const _EditorIconControl({
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
    required this.icon,
    super.key,
  });

  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: colors.surfaceSecondary,
          shape: CircleBorder(
            side: BorderSide(
              color: colors.materialChrome.withValues(alpha: 0.48),
              width: 0.8,
            ),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                icon,
                size: 21,
                color: colors.textPrimary.withValues(alpha: enabled ? 1 : 0.42),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CropBoundaryPainter extends CustomPainter {
  _CropBoundaryPainter({
    required this.dimColor,
    required this.edgeColor,
    required this.highlightColor,
  }) : _dimPaint = Paint()..color = dimColor,
       _edgePaint = Paint()
         ..color = edgeColor.withValues(alpha: 0.86)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.4,
       _highlightPaint = Paint()
         ..color = highlightColor.withValues(alpha: 0.72)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 2,
       _outside = Path()..fillType = PathFillType.evenOdd;

  final Color dimColor;
  final Color edgeColor;
  final Color highlightColor;
  final Paint _dimPaint;
  final Paint _edgePaint;
  final Paint _highlightPaint;
  final Path _outside;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 3;
    final cropRect = Rect.fromCircle(center: center, radius: radius);
    _outside
      ..reset()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(cropRect);
    canvas.drawPath(_outside, _dimPaint);
    canvas.drawCircle(center, radius, _edgePaint);
    canvas.drawArc(
      cropRect,
      math.pi * 1.04,
      math.pi * 0.34,
      false,
      _highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_CropBoundaryPainter oldDelegate) {
    return oldDelegate.dimColor != dimColor ||
        oldDelegate.edgeColor != edgeColor ||
        oldDelegate.highlightColor != highlightColor;
  }
}
