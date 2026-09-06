import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_colors.dart';
import '../../domain/image/crop_spec.dart';
import '../../l10n/app_localizations.dart';
import 'image_editor_controller.dart';

final class ImageEditorScreen extends ConsumerStatefulWidget {
  const ImageEditorScreen({
    required this.assetId,
    required this.originalBytes,
    this.initialCropSpec = CropSpec.centered,
    super.key,
  });

  final String assetId;
  final Uint8List originalBytes;
  final CropSpec initialCropSpec;

  @override
  ConsumerState<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

final class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  CropSpec _gestureStart = CropSpec.centered;
  Offset _gestureFocalStart = Offset.zero;
  late final ImageEditorSession _session;

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
    final l10n = AppLocalizations.of(context);
    final crop = ref.watch(imageEditorControllerProvider(_session));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.imageEditorTitle),
        leading: IconButton(
          key: const Key('image_editor_cancel'),
          tooltip: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            key: const Key('image_editor_save'),
            onPressed: () => Navigator.of(context).pop(crop),
            tooltip: l10n.save,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.imageEditorHint),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Semantics(
                          label: l10n.imageCropPreview,
                          child: GestureDetector(
                            key: const Key('image_crop_gesture'),
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: (details) {
                              _gestureStart = crop;
                              _gestureFocalStart = details.localFocalPoint;
                            },
                            onScaleUpdate: (details) {
                              final delta =
                                  details.localFocalPoint - _gestureFocalStart;
                              ref
                                  .read(
                                    imageEditorControllerProvider(_session)
                                        .notifier,
                                  )
                                  .applyGesture(
                                    start: _gestureStart,
                                    deltaX: delta.dx / constraints.maxWidth,
                                    deltaY: delta.dy / constraints.maxHeight,
                                    scaleFactor: details.scale,
                                  );
                            },
                            child: ClipOval(
                              child: ColoredBox(
                                color: Colors.black,
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('image_editor_rotate'),
                      onPressed: () => ref
                          .read(
                            imageEditorControllerProvider(_session).notifier,
                          )
                          .rotateQuarterTurn(),
                      icon: const Icon(Icons.rotate_90_degrees_ccw_rounded),
                      label: Text(l10n.rotate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('image_editor_reset'),
                      onPressed: () => ref
                          .read(
                            imageEditorControllerProvider(_session).notifier,
                          )
                          .reset(),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.reset),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
