import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/image/crop_spec.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import '../shared/chrome_kiss_fidelity_tokens.dart';
import 'image_editor_controller.dart';

enum _CreateLookEditorStep { crop, beauty }

enum _BeautyPreset { candyGloss, pearlDoll, clubKiss }

/// The Figma-faithful crop and beauty stages of the create-look workflow.
final class CreateLookEditorFlow extends ConsumerStatefulWidget {
  const CreateLookEditorFlow({
    required this.session,
    required this.originalBytes,
    required this.processing,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final bool processing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  ConsumerState<CreateLookEditorFlow> createState() =>
      _CreateLookEditorFlowState();
}

final class _CreateLookEditorFlowState
    extends ConsumerState<CreateLookEditorFlow> {
  static const _beautyAssetPaths = [
    'assets/chrome_kiss/create_beauty_blush.png',
    'assets/chrome_kiss/create_beauty_progress.png',
    'assets/chrome_kiss/create_beauty_cloud.png',
    'assets/chrome_kiss/create_beauty_halo.png',
    'assets/chrome_kiss/create_beauty_bow.png',
    'assets/chrome_kiss/create_preset_candy.png',
    'assets/chrome_kiss/create_preset_pearl.png',
    'assets/chrome_kiss/create_preset_club.png',
    'assets/chrome_kiss/create_adjustment_thumb.png',
  ];

  _CreateLookEditorStep _step = _CreateLookEditorStep.crop;
  _BeautyPreset _preset = _BeautyPreset.candyGloss;
  double _glow = 0.72;
  double _warmth = 0.58;
  bool _assetsWarmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsWarmed) return;
    _assetsWarmed = true;
    for (final path in _beautyAssetPaths) {
      unawaited(precacheImage(AssetImage(path), context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Scaffold(
      key: const Key('image_editor_screen'),
      backgroundColor: ChromeKissFidelityTokens.outside,
      body: ChromeKissFidelityFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final exact =
                constraints.maxWidth >= 380 &&
                constraints.maxHeight >= 844 &&
                textScale <= 1.15 &&
                MediaQuery.viewPaddingOf(context) == EdgeInsets.zero;
            return switch ((_step, exact)) {
              (_CreateLookEditorStep.crop, true) => _CropReferenceLayout(
                session: widget.session,
                originalBytes: widget.originalBytes,
                onBack: widget.onCancel,
                onNext: _openBeautyStep,
              ),
              (_CreateLookEditorStep.crop, false) => _CropAdaptiveLayout(
                session: widget.session,
                originalBytes: widget.originalBytes,
                onBack: widget.onCancel,
                onNext: _openBeautyStep,
              ),
              (_CreateLookEditorStep.beauty, true) => _BeautyReferenceLayout(
                session: widget.session,
                originalBytes: widget.originalBytes,
                preset: _preset,
                glow: _glow,
                warmth: _warmth,
                processing: widget.processing,
                onBack: _openCropStep,
                onPresetChanged: _selectPreset,
                onGlowChanged: (value) => setState(() => _glow = value),
                onWarmthChanged: (value) => setState(() => _warmth = value),
                onReset: _resetBeauty,
                onSave: widget.onSave,
              ),
              (_CreateLookEditorStep.beauty, false) => _BeautyAdaptiveLayout(
                session: widget.session,
                originalBytes: widget.originalBytes,
                preset: _preset,
                glow: _glow,
                warmth: _warmth,
                processing: widget.processing,
                onBack: _openCropStep,
                onPresetChanged: _selectPreset,
                onGlowChanged: (value) => setState(() => _glow = value),
                onWarmthChanged: (value) => setState(() => _warmth = value),
                onReset: _resetBeauty,
                onSave: widget.onSave,
              ),
            };
          },
        ),
      ),
    );
  }

  void _openBeautyStep() {
    setState(() => _step = _CreateLookEditorStep.beauty);
  }

  void _openCropStep() {
    if (widget.processing) return;
    setState(() => _step = _CreateLookEditorStep.crop);
  }

  void _selectPreset(_BeautyPreset preset) {
    setState(() {
      _preset = preset;
      switch (preset) {
        case _BeautyPreset.candyGloss:
          _glow = 0.72;
          _warmth = 0.58;
        case _BeautyPreset.pearlDoll:
          _glow = 0.48;
          _warmth = 0.5;
        case _BeautyPreset.clubKiss:
          _glow = 0.84;
          _warmth = 0.34;
      }
    });
  }

  void _resetBeauty() {
    _selectPreset(_BeautyPreset.candyGloss);
  }
}

final class _CropReferenceLayout extends ConsumerWidget {
  const _CropReferenceLayout({
    required this.session,
    required this.originalBytes,
    required this.onBack,
    required this.onNext,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final crop = ref.watch(imageEditorControllerProvider(session));
    return SingleChildScrollView(
      key: const Key('image_editor_crop_scroll'),
      child: SizedBox(
        height: ChromeKissFidelityTokens.referenceSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 274,
              top: 17,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_crop_blush.png',
                width: 190,
                height: 190,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ChromeKissReferenceStatusBar(),
            ),
            Positioned(
              left: 24,
              top: 49,
              child: _CreateLookHeader(
                step: l10n.createLookCropStep,
                title: l10n.createLookCropTitle,
                accent: l10n.createLookCropAccent,
                progressAsset: 'assets/chrome_kiss/create_crop_progress.png',
                onBack: onBack,
              ),
            ),
            Positioned(
              left: 24,
              top: 142,
              child: _CropStage(
                session: session,
                originalBytes: originalBytes,
                reference: true,
              ),
            ),
            Positioned(
              left: 24,
              top: 529,
              child: SizedBox(
                width: 345,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.zoomLabel,
                      style: _labelStyle(
                        color: ChromeKissFidelityTokens.mutedInk,
                      ),
                    ),
                    Text(
                      _zoomLabel(crop.scale),
                      style: _labelStyle(
                        color: ChromeKissFidelityTokens.accentInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 560,
              child: _ZoomControl(session: session),
            ),
            Positioned(
              left: 24,
              top: 615,
              child: _CropQuickActions(session: session),
            ),
            Positioned(
              left: 28,
              top: 680,
              child: _PrimaryFidelityButton(
                key: const Key('image_editor_next'),
                label: l10n.nextAction,
                onPressed: onNext,
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 771,
              child: Text(
                l10n.nextLightColorHint,
                textAlign: TextAlign.center,
                style: _hintStyle,
              ),
            ),
            const Positioned(
              left: 138.5,
              top: 833,
              child: ChromeKissHomeIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CropAdaptiveLayout extends ConsumerWidget {
  const _CropAdaptiveLayout({
    required this.session,
    required this.originalBytes,
    required this.onBack,
    required this.onNext,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final crop = ref.watch(imageEditorControllerProvider(session));
    return CustomScrollView(
      key: const Key('image_editor_crop_scroll'),
      slivers: [
        const SliverToBoxAdapter(child: ChromeKissReferenceStatusBar()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          sliver: SliverList.list(
            children: [
              _CreateLookAdaptiveHeader(
                step: l10n.createLookCropStep,
                title: l10n.createLookCropTitle,
                accent: l10n.createLookCropAccent,
                progressAsset: 'assets/chrome_kiss/create_crop_progress.png',
                onBack: onBack,
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 345),
                  child: _CropStage(
                    session: session,
                    originalBytes: originalBytes,
                    reference: false,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.zoomLabel, style: _adaptiveLabelStyle),
                  Text(
                    _zoomLabel(crop.scale),
                    style: _adaptiveLabelStyle.copyWith(
                      color: ChromeKissFidelityTokens.accentInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: _ZoomControl(session: session, adaptive: true)),
              const SizedBox(height: 12),
              Center(
                child: _CropQuickActions(session: session, adaptive: true),
              ),
              const SizedBox(height: 20),
              Center(
                child: _PrimaryFidelityButton(
                  key: const Key('image_editor_next'),
                  label: l10n.nextAction,
                  onPressed: onNext,
                  adaptive: true,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.nextLightColorHint,
                textAlign: TextAlign.center,
                style: _hintStyle,
              ),
              const SizedBox(height: 30),
              const Center(child: ChromeKissHomeIndicator()),
            ],
          ),
        ),
      ],
    );
  }
}

final class _BeautyReferenceLayout extends StatelessWidget {
  const _BeautyReferenceLayout({
    required this.session,
    required this.originalBytes,
    required this.preset,
    required this.glow,
    required this.warmth,
    required this.processing,
    required this.onBack,
    required this.onPresetChanged,
    required this.onGlowChanged,
    required this.onWarmthChanged,
    required this.onReset,
    required this.onSave,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final _BeautyPreset preset;
  final double glow;
  final double warmth;
  final bool processing;
  final VoidCallback onBack;
  final ValueChanged<_BeautyPreset> onPresetChanged;
  final ValueChanged<double> onGlowChanged;
  final ValueChanged<double> onWarmthChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const Key('image_editor_beauty_scroll'),
      child: SizedBox(
        height: ChromeKissFidelityTokens.referenceSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 274,
              top: 17,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_beauty_blush.png',
                width: 190,
                height: 190,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ChromeKissReferenceStatusBar(),
            ),
            Positioned(
              left: 24,
              top: 49,
              child: _CreateLookHeader(
                step: l10n.createLookBeautyStep,
                title: l10n.createLookBeautyTitle,
                accent: l10n.createLookBeautyAccent,
                progressAsset: 'assets/chrome_kiss/create_beauty_progress.png',
                onBack: onBack,
              ),
            ),
            Positioned(
              left: 24,
              top: 142,
              child: _BeautyPreview(
                session: session,
                originalBytes: originalBytes,
                preset: preset,
                glow: glow,
                warmth: warmth,
                reference: true,
              ),
            ),
            Positioned(
              left: 24,
              top: 401,
              child: _MoodPresets(
                selected: preset,
                onChanged: onPresetChanged,
                reference: true,
              ),
            ),
            Positioned(
              left: 24,
              top: 515,
              child: _FineTunePanel(
                glow: glow,
                warmth: warmth,
                onGlowChanged: onGlowChanged,
                onWarmthChanged: onWarmthChanged,
                onReset: onReset,
                reference: true,
              ),
            ),
            Positioned(
              left: 28,
              top: 669,
              child: _PrimaryFidelityButton(
                key: const Key('image_editor_save'),
                label: processing ? l10n.preparingLook : l10n.saveLook,
                onPressed: processing ? null : onSave,
                busy: processing,
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 755,
              child: Text(
                l10n.lookAppearsInWardrobe,
                textAlign: TextAlign.center,
                style: _hintStyle,
              ),
            ),
            const Positioned(
              left: 138.5,
              top: 833,
              child: ChromeKissHomeIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BeautyAdaptiveLayout extends StatelessWidget {
  const _BeautyAdaptiveLayout({
    required this.session,
    required this.originalBytes,
    required this.preset,
    required this.glow,
    required this.warmth,
    required this.processing,
    required this.onBack,
    required this.onPresetChanged,
    required this.onGlowChanged,
    required this.onWarmthChanged,
    required this.onReset,
    required this.onSave,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final _BeautyPreset preset;
  final double glow;
  final double warmth;
  final bool processing;
  final VoidCallback onBack;
  final ValueChanged<_BeautyPreset> onPresetChanged;
  final ValueChanged<double> onGlowChanged;
  final ValueChanged<double> onWarmthChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      key: const Key('image_editor_beauty_scroll'),
      slivers: [
        const SliverToBoxAdapter(child: ChromeKissReferenceStatusBar()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          sliver: SliverList.list(
            children: [
              _CreateLookAdaptiveHeader(
                step: l10n.createLookBeautyStep,
                title: l10n.createLookBeautyTitle,
                accent: l10n.createLookBeautyAccent,
                progressAsset: 'assets/chrome_kiss/create_beauty_progress.png',
                onBack: onBack,
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 345),
                  child: _BeautyPreview(
                    session: session,
                    originalBytes: originalBytes,
                    preset: preset,
                    glow: glow,
                    warmth: warmth,
                    reference: false,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _MoodPresets(
                selected: preset,
                onChanged: onPresetChanged,
                reference: false,
              ),
              const SizedBox(height: 22),
              _FineTunePanel(
                glow: glow,
                warmth: warmth,
                onGlowChanged: onGlowChanged,
                onWarmthChanged: onWarmthChanged,
                onReset: onReset,
                reference: false,
              ),
              const SizedBox(height: 22),
              Center(
                child: _PrimaryFidelityButton(
                  key: const Key('image_editor_save'),
                  label: processing ? l10n.preparingLook : l10n.saveLook,
                  onPressed: processing ? null : onSave,
                  busy: processing,
                  adaptive: true,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.lookAppearsInWardrobe,
                textAlign: TextAlign.center,
                style: _hintStyle,
              ),
              const SizedBox(height: 30),
              const Center(child: ChromeKissHomeIndicator()),
            ],
          ),
        ),
      ],
    );
  }
}

final class _CreateLookHeader extends StatelessWidget {
  const _CreateLookHeader({
    required this.step,
    required this.title,
    required this.accent,
    required this.progressAsset,
    required this.onBack,
  });

  final String step;
  final String title;
  final String accent;
  final String progressAsset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 345,
      height: 84,
      child: Stack(
        children: [
          Positioned(top: 6, child: _BackButton(onPressed: onBack)),
          Positioned(left: 60, top: 0, child: Text(step, style: _stepStyle)),
          Positioned(
            left: 60,
            top: 17,
            child: Text(title, style: ChromeKissFidelityTokens.titleStyle),
          ),
          Positioned(
            left: 61,
            top: 55,
            child: ChromeKissScriptHeartText(text: accent, fontSize: 20),
          ),
          Positioned(
            left: 291,
            top: 10,
            child: _FidelityAsset(path: progressAsset, width: 54, height: 16),
          ),
        ],
      ),
    );
  }
}

final class _CreateLookAdaptiveHeader extends StatelessWidget {
  const _CreateLookAdaptiveHeader({
    required this.step,
    required this.title,
    required this.accent,
    required this.progressAsset,
    required this.onBack,
  });

  final String step;
  final String title;
  final String accent;
  final String progressAsset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onPressed: onBack),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step, style: _stepStyle),
              const SizedBox(height: 2),
              Text(title, style: ChromeKissFidelityTokens.titleStyle),
              ChromeKissScriptHeartText(text: accent, fontSize: 20),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 350)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _FidelityAsset(path: progressAsset, width: 54, height: 16),
          ),
      ],
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.cancel,
      child: ExcludeSemantics(
        child: Material(
          color: const Color(0xD1FFFFFF),
          shape: const CircleBorder(
            side: BorderSide(color: ChromeKissFidelityTokens.chromeLine),
          ),
          child: InkWell(
            key: const Key('image_editor_cancel'),
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox.square(
              dimension: 44,
              child: Center(
                child: Text(
                  '‹',
                  style: TextStyle(
                    color: ChromeKissFidelityTokens.accentInk,
                    fontFamily: 'Manrope',
                    fontSize: 27,
                    height: 30 / 27,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CropStage extends ConsumerWidget {
  const _CropStage({
    required this.session,
    required this.originalBytes,
    required this.reference,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final bool reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (reference) {
      return Container(
        width: 345,
        height: 372,
        decoration: _pearlPanelDecoration(radius: 32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 7,
              top: -21,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_crop_cloud.png',
                width: 330,
                height: 300,
              ),
            ),
            const Positioned(
              left: 10.5,
              top: 8,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_crop_halo.png',
                width: 322,
                height: 322,
              ),
            ),
            Positioned(
              left: 36.5,
              top: 29,
              child: _EditablePortrait(
                session: session,
                originalBytes: originalBytes,
                diameter: 270,
                guides: true,
              ),
            ),
            const Positioned(
              left: 256,
              top: 14,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_crop_bow.png',
                width: 42,
                height: 30,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 315,
              child: Text(
                l10n.movePhotoInsideCircle,
                textAlign: TextAlign.center,
                style: ChromeKissFidelityTokens.bodyStyle,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 338,
              child: ChromeKissScriptHeartText(
                text: l10n.pinchZoomAccent,
                fontSize: 20,
                centered: true,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.max(
          214.0,
          math.min(270.0, constraints.maxWidth - 46),
        );
        return Container(
          constraints: const BoxConstraints(minHeight: 360),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: _pearlPanelDecoration(radius: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _FidelityAsset(
                    path: 'assets/chrome_kiss/create_crop_halo.png',
                    width: diameter + 52,
                    height: diameter + 52,
                  ),
                  _EditablePortrait(
                    session: session,
                    originalBytes: originalBytes,
                    diameter: diameter,
                    guides: true,
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    child: const _FidelityAsset(
                      path: 'assets/chrome_kiss/create_crop_bow.png',
                      width: 42,
                      height: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.movePhotoInsideCircle,
                textAlign: TextAlign.center,
                style: ChromeKissFidelityTokens.bodyStyle,
              ),
              ChromeKissScriptHeartText(
                text: l10n.pinchZoomAccent,
                fontSize: 20,
                centered: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _EditablePortrait extends ConsumerStatefulWidget {
  const _EditablePortrait({
    required this.session,
    required this.originalBytes,
    required this.diameter,
    required this.guides,
    this.colorFilter,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final double diameter;
  final bool guides;
  final ColorFilter? colorFilter;

  @override
  ConsumerState<_EditablePortrait> createState() => _EditablePortraitState();
}

final class _EditablePortraitState extends ConsumerState<_EditablePortrait> {
  CropSpec _gestureStart = CropSpec.centered;
  Offset _gestureFocalStart = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final crop = ref.watch(imageEditorControllerProvider(widget.session));
    final l10n = AppLocalizations.of(context);
    Widget photo = Transform.rotate(
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
            width: widget.diameter,
            height: widget.diameter,
            cacheWidth: 960,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
    final filter = widget.colorFilter;
    if (filter != null) {
      photo = ColorFiltered(colorFilter: filter, child: photo);
    }

    return Semantics(
      image: true,
      label: l10n.imageCropPreview,
      hint: l10n.imageCropGestureHint,
      child: ExcludeSemantics(
        child: Container(
          width: widget.diameter,
          height: widget.diameter,
          decoration: BoxDecoration(
            color: ChromeKissFidelityTokens.lens,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF302A3C)),
          ),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            key: const Key('image_crop_gesture'),
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              _gestureStart = crop;
              _gestureFocalStart = details.localFocalPoint;
            },
            onScaleUpdate: (details) {
              final delta = details.localFocalPoint - _gestureFocalStart;
              ref
                  .read(imageEditorControllerProvider(widget.session).notifier)
                  .applyGesture(
                    start: _gestureStart,
                    deltaX: delta.dx / widget.diameter,
                    deltaY: delta.dy / widget.diameter,
                    scaleFactor: details.scale,
                  );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [photo, if (widget.guides) const _CropGuides()],
            ),
          ),
        ),
      ),
    );
  }
}

final class _CropGuides extends StatelessWidget {
  const _CropGuides();

  @override
  Widget build(BuildContext context) {
    const line = ChromeKissFidelityTokens.specular;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final third = constraints.maxWidth / 3;
          return Stack(
            children: [
              Positioned(
                left: third,
                top: 0,
                bottom: 0,
                child: _GuideLine.vertical(line),
              ),
              Positioned(
                left: third * 2,
                top: 0,
                bottom: 0,
                child: _GuideLine.vertical(line),
              ),
              Positioned(
                top: third,
                left: 0,
                right: 0,
                child: _GuideLine.horizontal(line),
              ),
              Positioned(
                top: third * 2,
                left: 0,
                right: 0,
                child: _GuideLine.horizontal(line),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _GuideLine extends StatelessWidget {
  const _GuideLine.vertical(this.color) : vertical = true;
  const _GuideLine.horizontal(this.color) : vertical = false;

  final Color color;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.35),
      child: SizedBox(width: vertical ? 1 : null, height: vertical ? null : 1),
    );
  }
}

final class _ZoomControl extends ConsumerWidget {
  const _ZoomControl({required this.session, this.adaptive = false});

  final ImageEditorSession session;
  final bool adaptive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crop = ref.watch(imageEditorControllerProvider(session));
    final width = adaptive
        ? math.min(345.0, MediaQuery.sizeOf(context).width - 36)
        : 345.0;
    final normalized = (0.63 + (crop.scale - 1) / 7 * 0.37).clamp(0.63, 1.0);
    return Semantics(
      slider: true,
      label: AppLocalizations.of(context).zoomLabel,
      value: _zoomLabel(crop.scale),
      increasedValue: _zoomLabel(_changedScale(crop.scale, 0.12)),
      decreasedValue: _zoomLabel(_changedScale(crop.scale, -0.12)),
      onIncrease: () => _setScale(ref, crop, _changedScale(crop.scale, 0.12)),
      onDecrease: () => _setScale(ref, crop, _changedScale(crop.scale, -0.12)),
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: 44,
          decoration: _pearlPanelDecoration(radius: 999),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth - 92;
              final activeWidth = trackWidth * normalized;
              final thumbLeft = 45 + activeWidth - 12;
              void update(double localX) {
                final next = ((localX - 45) / trackWidth).clamp(0.63, 1.0);
                final scale = 1 + (next - 0.63) / 0.37 * 7;
                _setScale(ref, crop, scale);
              }

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 44,
                    child: _SliderStepButton(
                      label: '−',
                      color: ChromeKissFidelityTokens.mutedInk,
                      onPressed: () => _setScale(
                        ref,
                        crop,
                        _changedScale(crop.scale, -0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 44,
                    child: _SliderStepButton(
                      label: '+',
                      color: ChromeKissFidelityTokens.accentInk,
                      onPressed: () =>
                          _setScale(ref, crop, _changedScale(crop.scale, 0.12)),
                    ),
                  ),
                  Positioned(
                    left: 45,
                    top: 10,
                    width: trackWidth,
                    height: 24,
                    child: GestureDetector(
                      key: const Key('image_editor_zoom'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => update(details.localPosition.dx),
                      onHorizontalDragUpdate: (details) =>
                          update(details.localPosition.dx),
                    ),
                  ),
                  Positioned(
                    left: 45,
                    top: 19,
                    child: Container(
                      width: trackWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ChromeKissFidelityTokens.chromeLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 45,
                    top: 19,
                    child: Container(
                      width: activeWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ChromeKissFidelityTokens.lacquer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbLeft,
                    top: 9,
                    child: const _FidelityAsset(
                      path: 'assets/chrome_kiss/create_crop_zoom_thumb.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static double _changedScale(double value, double amount) {
    return (value + amount).clamp(CropSpec.minScale, CropSpec.maxScale);
  }

  void _setScale(WidgetRef ref, CropSpec crop, double scale) {
    ref
        .read(imageEditorControllerProvider(session).notifier)
        .applyGesture(
          start: crop,
          deltaX: 0,
          deltaY: 0,
          scaleFactor: scale / crop.scale,
        );
  }
}

final class _SliderStepButton extends StatelessWidget {
  const _SliderStepButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: 'Manrope',
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

final class _CropQuickActions extends ConsumerWidget {
  const _CropQuickActions({required this.session, this.adaptive = false});

  final ImageEditorSession session;
  final bool adaptive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = [
      _QuickAction(
        key: const Key('image_editor_rotate'),
        icon: Icons.rotate_left_rounded,
        symbolColor: ChromeKissFidelityTokens.ink,
        label: l10n.rotate,
        onPressed: () => ref
            .read(imageEditorControllerProvider(session).notifier)
            .rotateQuarterTurn(),
      ),
      _QuickAction(
        key: const Key('image_editor_reset'),
        icon: Icons.flare_rounded,
        symbolColor: ChromeKissFidelityTokens.accentInk,
        label: l10n.autoCenter,
        onPressed: () => _centerCrop(ref),
      ),
    ];
    final stack =
        adaptive &&
        (MediaQuery.sizeOf(context).width < 350 ||
            MediaQuery.textScalerOf(context).scale(13) > 17);
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [actions.first, const SizedBox(height: 10), actions.last],
      );
    }
    return SizedBox(
      width: adaptive
          ? math.min(345.0, MediaQuery.sizeOf(context).width - 36)
          : 345,
      child: Row(
        children: [
          Expanded(child: actions.first),
          const SizedBox(width: 12),
          Expanded(child: actions.last),
        ],
      ),
    );
  }

  void _centerCrop(WidgetRef ref) {
    final crop = ref.read(imageEditorControllerProvider(session));
    ref
        .read(imageEditorControllerProvider(session).notifier)
        .applyGesture(
          start: crop,
          deltaX: (crop.centerX - 0.5) * crop.scale,
          deltaY: (crop.centerY - 0.5) * crop.scale,
          scaleFactor: 1,
        );
  }
}

final class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.symbolColor,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color symbolColor;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(13) > 17;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        height: largeText ? null : 48,
        decoration: _pearlPanelDecoration(radius: 999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: largeText ? 12 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: symbolColor, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ChromeKissFidelityTokens.ink,
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      height: 20 / 13,
                      fontWeight: FontWeight.w500,
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

final class _BeautyPreview extends StatelessWidget {
  const _BeautyPreview({
    required this.session,
    required this.originalBytes,
    required this.preset,
    required this.glow,
    required this.warmth,
    required this.reference,
  });

  final ImageEditorSession session;
  final Uint8List originalBytes;
  final _BeautyPreset preset;
  final double glow;
  final double warmth;
  final bool reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status =
        '${_presetLabel(l10n, preset).toUpperCase()} · '
        '${(glow * 100).round()}%';
    if (reference) {
      return Container(
        width: 345,
        height: 246,
        decoration: _pearlPanelDecoration(radius: 32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 39,
              top: -20,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_beauty_cloud.png',
                width: 266,
                height: 246,
              ),
            ),
            const Positioned(
              left: 63.5,
              top: 0,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_beauty_halo.png',
                width: 216,
                height: 216,
              ),
            ),
            Positioned(
              left: 81.5,
              top: 13,
              child: _EditablePortrait(
                session: session,
                originalBytes: originalBytes,
                diameter: 180,
                guides: false,
                colorFilter: _beautyFilter(preset, glow, warmth),
              ),
            ),
            const Positioned(
              left: 18,
              top: 16,
              child: _FidelityAsset(
                path: 'assets/chrome_kiss/create_beauty_bow.png',
                width: 42,
                height: 30,
              ),
            ),
            Positioned(
              left: 254,
              top: 15,
              child: _LiveBadge(label: l10n.liveLabel),
            ),
            Positioned(
              left: 17,
              top: 209,
              child: ChromeKissScriptHeartText(
                text: l10n.glowingAccent,
                fontSize: 20,
              ),
            ),
            Positioned(
              left: 164,
              top: 209,
              child: _BeautyStatus(label: status),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: _pearlPanelDecoration(radius: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const _FidelityAsset(
                path: 'assets/chrome_kiss/create_beauty_halo.png',
                width: 216,
                height: 216,
              ),
              _EditablePortrait(
                session: session,
                originalBytes: originalBytes,
                diameter: 180,
                guides: false,
                colorFilter: _beautyFilter(preset, glow, warmth),
              ),
              Positioned(
                left: -4,
                top: 2,
                child: _LiveBadge(label: l10n.liveLabel),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              ChromeKissScriptHeartText(text: l10n.glowingAccent, fontSize: 20),
              _BeautyStatus(label: status),
            ],
          ),
        ],
      ),
    );
  }
}

final class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 15;
    return Container(
      width: largeText ? null : 72,
      height: largeText ? null : 28,
      constraints: const BoxConstraints(minWidth: 72, minHeight: 28),
      padding: EdgeInsets.symmetric(
        horizontal: largeText ? 9 : 0,
        vertical: largeText ? 6 : 0,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: ChromeKissFidelityTokens.chromeLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ChromeKissFidelityTokens.ink,
              fontFamily: 'Manrope',
              fontSize: 11,
              height: 16 / 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.88,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.flare_rounded,
            color: ChromeKissFidelityTokens.ink,
            size: 10,
          ),
        ],
      ),
    );
  }
}

final class _BeautyStatus extends StatelessWidget {
  const _BeautyStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 15;
    return Container(
      width: largeText ? null : 162,
      height: largeText ? null : 30,
      constraints: const BoxConstraints(minWidth: 162, minHeight: 30),
      padding: EdgeInsets.symmetric(
        horizontal: largeText ? 12 : 0,
        vertical: largeText ? 6 : 0,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: _lensGradient,
        border: Border.all(color: const Color(0xFF302A3C), width: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ChromeKissFidelityTokens.specular,
          fontFamily: 'Manrope',
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

final class _MoodPresets extends StatelessWidget {
  const _MoodPresets({
    required this.selected,
    required this.onChanged,
    required this.reference,
  });

  final _BeautyPreset selected;
  final ValueChanged<_BeautyPreset> onChanged;
  final bool reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      for (final preset in _BeautyPreset.values)
        _PresetCard(
          preset: preset,
          label: _presetLabel(l10n, preset),
          selected: preset == selected,
          adaptive: !reference,
          onPressed: () => onChanged(preset),
        ),
    ];
    return SizedBox(
      width: reference ? 345 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.moodLabel, style: _sectionLabelStyle),
          const SizedBox(height: 8),
          if (reference)
            Row(
              children: [
                cards[0],
                const SizedBox(width: 9),
                cards[1],
                const SizedBox(width: 9),
                cards[2],
              ],
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 9.0;
                final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final card in cards)
                      SizedBox(width: cardWidth, child: card),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

final class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.label,
    required this.selected,
    required this.adaptive,
    required this.onPressed,
  });

  final _BeautyPreset preset;
  final String label;
  final bool selected;
  final bool adaptive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: 109,
            height: adaptive
                ? 58 + MediaQuery.textScalerOf(context).scale(32)
                : 68,
            decoration: BoxDecoration(
              color: selected ? null : Colors.transparent,
              gradient: selected ? _lensGradient : null,
              border: Border.all(
                color: selected
                    ? const Color(0xFF302A3C)
                    : ChromeKissFidelityTokens.chromeLine,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: InkWell(
              key: Key('beauty_preset_${preset.name}'),
              onTap: onPressed,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FidelityAsset(
                      path: _presetAsset(preset),
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? ChromeKissFidelityTokens.specular
                            : ChromeKissFidelityTokens.ink,
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        height: 16 / 11,
                        fontWeight: FontWeight.w500,
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

final class _FineTunePanel extends StatelessWidget {
  const _FineTunePanel({
    required this.glow,
    required this.warmth,
    required this.onGlowChanged,
    required this.onWarmthChanged,
    required this.onReset,
    required this.reference,
  });

  final double glow;
  final double warmth;
  final ValueChanged<double> onGlowChanged;
  final ValueChanged<double> onWarmthChanged;
  final VoidCallback onReset;
  final bool reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: reference ? 345 : double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reference)
              SizedBox(
                height: 18,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fineTuneLabel,
                        style: _sectionLabelStyle,
                      ),
                    ),
                    InkWell(
                      key: const Key('beauty_reset'),
                      onTap: onReset,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        child: Text(
                          l10n.reset,
                          style: _labelStyle(
                            color: ChromeKissFidelityTokens.accentInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.fineTuneLabel, style: _sectionLabelStyle),
                  ),
                  InkWell(
                    key: const Key('beauty_reset'),
                    onTap: onReset,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      child: Text(
                        l10n.reset,
                        style: _labelStyle(
                          color: ChromeKissFidelityTokens.accentInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            _FineTuneSlider(
              key: const Key('beauty_glow_slider'),
              label: l10n.glowLabel,
              valueLabel: '${(glow * 100).round()}%',
              value: glow,
              activeColor: ChromeKissFidelityTokens.accentInk,
              onChanged: onGlowChanged,
              adaptive: !reference,
            ),
            const SizedBox(height: 8),
            _FineTuneSlider(
              key: const Key('beauty_warmth_slider'),
              label: l10n.warmthLabel,
              valueLabel: _warmthLabel(warmth),
              value: warmth,
              activeColor: const Color(0xFFE7C98B),
              onChanged: onWarmthChanged,
              adaptive: !reference,
            ),
          ],
        ),
      ),
    );
  }
}

final class _FineTuneSlider extends StatelessWidget {
  const _FineTuneSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    this.adaptive = false,
    super.key,
  });

  final String label;
  final String valueLabel;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final bool adaptive;

  @override
  Widget build(BuildContext context) {
    if (adaptive) {
      return Semantics(
        slider: true,
        label: label,
        value: valueLabel,
        increasedValue: '${((value + 0.05).clamp(0, 1) * 100).round()}%',
        decreasedValue: '${((value - 0.05).clamp(0, 1) * 100).round()}%',
        onIncrease: () => onChanged((value + 0.05).clamp(0, 1)),
        onDecrease: () => onChanged((value - 0.05).clamp(0, 1)),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label, style: _tuneStyle)),
                  const SizedBox(width: 12),
                  Text(
                    valueLabel,
                    textAlign: TextAlign.end,
                    style: _tuneStyle.copyWith(
                      color: activeColor == ChromeKissFidelityTokens.accentInk
                          ? ChromeKissFidelityTokens.accentInk
                          : ChromeKissFidelityTokens.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    void update(double x) {
                      onChanged((x / constraints.maxWidth).clamp(0, 1));
                    }

                    final thumbLeft = (constraints.maxWidth * value - 9)
                        .clamp(0.0, constraints.maxWidth - 18)
                        .toDouble();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => update(details.localPosition.dx),
                      onHorizontalDragUpdate: (details) =>
                          update(details.localPosition.dx),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 14,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: ChromeKissFidelityTokens.chromeLine,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 14,
                            child: Container(
                              width: constraints.maxWidth * value,
                              height: 4,
                              decoration: BoxDecoration(
                                color: activeColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            left: thumbLeft,
                            top: 5,
                            child: const _FidelityAsset(
                              path: 'assets/chrome_kiss/create_adjustment_thumb.png',
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      slider: true,
      label: label,
      value: valueLabel,
      increasedValue: '${((value + 0.05).clamp(0, 1) * 100).round()}%',
      decreasedValue: '${((value - 0.05).clamp(0, 1) * 100).round()}%',
      onIncrease: () => onChanged((value + 0.05).clamp(0, 1)),
      onDecrease: () => onChanged((value - 0.05).clamp(0, 1)),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void update(double x) {
                onChanged((x / constraints.maxWidth).clamp(0, 1));
              }

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(label, style: _tuneStyle),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      valueLabel,
                      style: _tuneStyle.copyWith(
                        color: activeColor == ChromeKissFidelityTokens.accentInk
                            ? ChromeKissFidelityTokens.accentInk
                            : ChromeKissFidelityTokens.ink,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 18,
                    height: 22,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => update(details.localPosition.dx),
                      onHorizontalDragUpdate: (details) =>
                          update(details.localPosition.dx),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 28,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: ChromeKissFidelityTokens.chromeLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 28,
                    child: Container(
                      width: constraints.maxWidth * value,
                      height: 4,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * value - 9,
                    top: 21,
                    child: const _FidelityAsset(
                      path: 'assets/chrome_kiss/create_adjustment_thumb.png',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _PrimaryFidelityButton extends StatelessWidget {
  const _PrimaryFidelityButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.adaptive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool adaptive;

  @override
  Widget build(BuildContext context) {
    final width = adaptive
        ? math.min(336.0, MediaQuery.sizeOf(context).width - 56)
        : 336.0;
    final largeText =
        adaptive && MediaQuery.textScalerOf(context).scale(18) > 22;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: largeText ? null : 72,
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? const LinearGradient(
                    colors: [Color(0xFFCB9AB8), Color(0xFF84536F)],
                  )
                : ChromeKissFidelityTokens.lacquerGradient,
            border: Border.all(color: ChromeKissFidelityTokens.lacquer),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x387D45FF),
                offset: Offset(0, 14),
                blurRadius: 36,
              ),
              BoxShadow(color: Color(0x57FF4FB8), blurRadius: 24),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: largeText ? 16 : 0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ChromeKissFidelityTokens.specular,
                              ),
                            )
                          : const Icon(
                              Icons.flare_rounded,
                              color: ChromeKissFidelityTokens.specular,
                              size: 22,
                            ),
                    ),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ChromeKissFidelityTokens.specular,
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          height: 24 / 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 24,
                      child: Text(
                        '›',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ChromeKissFidelityTokens.specular,
                          fontFamily: 'Manrope',
                          fontSize: 30,
                          height: 36 / 30,
                        ),
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

final class _FidelityAsset extends StatelessWidget {
  const _FidelityAsset({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}

BoxDecoration _pearlPanelDecoration({required double radius}) {
  return BoxDecoration(
    gradient: ChromeKissFidelityTokens.pearlGradient,
    border: Border.all(color: ChromeKissFidelityTokens.chromeLine),
    borderRadius: BorderRadius.circular(radius),
  );
}

ColorFilter? _beautyFilter(_BeautyPreset preset, double glow, double warmth) {
  if (preset == _BeautyPreset.candyGloss && glow == 0.72 && warmth == 0.58) {
    return null;
  }
  final brightness = (glow - 0.72) * 0.24;
  final heat = (warmth - 0.58) * 34;
  final violet = switch (preset) {
    _BeautyPreset.candyGloss => 0.0,
    _BeautyPreset.pearlDoll => 4.0,
    _BeautyPreset.clubKiss => 10.0,
  };
  return ColorFilter.matrix([
    1 + brightness,
    0,
    0,
    0,
    heat + violet,
    0,
    1 + brightness,
    0,
    0,
    brightness * 90,
    0,
    0,
    1 + brightness,
    0,
    -heat + violet,
    0,
    0,
    0,
    1,
    0,
  ]);
}

String _presetAsset(_BeautyPreset preset) => switch (preset) {
  _BeautyPreset.candyGloss => 'assets/chrome_kiss/create_preset_candy.png',
  _BeautyPreset.pearlDoll => 'assets/chrome_kiss/create_preset_pearl.png',
  _BeautyPreset.clubKiss => 'assets/chrome_kiss/create_preset_club.png',
};

String _presetLabel(AppLocalizations l10n, _BeautyPreset preset) =>
    switch (preset) {
      _BeautyPreset.candyGloss => l10n.candyGloss,
      _BeautyPreset.pearlDoll => l10n.pearlDoll,
      _BeautyPreset.clubKiss => l10n.clubKiss,
    };

String _zoomLabel(double scale) {
  return '${(108 + (scale - 1) * (692 / 7)).round()}%';
}

String _warmthLabel(double value) {
  final warmth = ((value - 0.5) * 100).round();
  return warmth >= 0 ? '+$warmth' : '$warmth';
}

const _lensGradient = LinearGradient(
  begin: Alignment(-0.7, -1),
  end: Alignment(0.8, 1),
  colors: [
    Color(0xFF291F3D),
    Color(0xFF030308),
    Color(0xFF0D081A),
    Color(0xFF381433),
  ],
  stops: [0.146, 0.344, 0.656, 0.854],
);

const _stepStyle = TextStyle(
  color: ChromeKissFidelityTokens.mutedInk,
  fontFamily: 'Manrope',
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w400,
);

const _hintStyle = TextStyle(
  color: ChromeKissFidelityTokens.mutedInk,
  fontFamily: 'Manrope',
  fontSize: 12,
  height: 18 / 12,
  fontWeight: FontWeight.w400,
);

const _adaptiveLabelStyle = TextStyle(
  color: ChromeKissFidelityTokens.mutedInk,
  fontFamily: 'Manrope',
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w500,
);

const _sectionLabelStyle = TextStyle(
  color: ChromeKissFidelityTokens.mutedInk,
  fontFamily: 'Manrope',
  fontSize: 12,
  height: 18 / 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.84,
);

const _tuneStyle = TextStyle(
  color: ChromeKissFidelityTokens.ink,
  fontFamily: 'Manrope',
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w500,
);

TextStyle _labelStyle({required Color color}) => TextStyle(
  color: color,
  fontFamily: 'Manrope',
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w500,
);
