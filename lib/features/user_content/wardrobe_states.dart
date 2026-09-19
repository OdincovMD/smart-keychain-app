import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/jewel_button.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';

/// The reserved Wardrobe body shown while the scene catalogue is loading.
final class WardrobeLoadingState extends StatefulWidget {
  const WardrobeLoadingState({required this.referenceLayout, super.key});

  final bool referenceLayout;

  @override
  State<WardrobeLoadingState> createState() => _WardrobeLoadingStateState();
}

final class _WardrobeLoadingStateState extends State<WardrobeLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer
        ..stop()
        ..value = 0;
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = Semantics(
      container: true,
      label: l10n.wardrobeLoadingSemantics,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (context, child) => _LoadingComposition(
            progress: _shimmer.value,
            referenceLayout: widget.referenceLayout,
          ),
        ),
      ),
    );
    if (!widget.referenceLayout) return content;
    return SizedBox(width: 345, height: 554, child: content);
  }
}

final class _LoadingComposition extends StatelessWidget {
  const _LoadingComposition({
    required this.progress,
    required this.referenceLayout,
  });

  final double progress;
  final bool referenceLayout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final width = math.min(345.0, MediaQuery.sizeOf(context).width - 36);
    final collectionWidth = (width - 36) / 2;
    final textScaler = MediaQuery.textScalerOf(context);
    final loadingHeaderHeight = referenceLayout
        ? 48.0
        : math.max(48.0, textScaler.scale(17) + textScaler.scale(13) + 4);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: loadingHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: fidelity.glass,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: fidelity.chromeLine),
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: fidelity.lacquer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: fidelity.lacquer.withValues(alpha: 0.42),
                        blurRadius: 11,
                      ),
                    ],
                  ),
                  child: const SizedBox.square(dimension: 12),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.wardrobeLoadingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.chromeKissText.label.copyWith(
                          color: fidelity.ink,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        l10n.wardrobeLoadingMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.chromeKissText.status.copyWith(
                          color: fidelity.mutedInk,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 144,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            decoration: BoxDecoration(
              gradient: fidelity.satinGradient,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: fidelity.chromeLine),
            ),
            child: Row(
              children: [
                _SkeletonBone(
                  progress: progress,
                  width: 108,
                  height: 108,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBone(progress: progress, width: 92, height: 12),
                      const SizedBox(height: 16),
                      _SkeletonBone(progress: progress, width: 138, height: 12),
                      const SizedBox(height: 16),
                      _SkeletonBone(progress: progress, width: 110, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.myContent.toUpperCase(),
            style: context.chromeKissText.status.copyWith(
              color: fidelity.mutedInk,
              fontSize: 10,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 36,
            runSpacing: 14,
            children: [
              for (var index = 0; index < 4; index++)
                Container(
                  width: collectionWidth,
                  height: 132,
                  decoration: BoxDecoration(
                    color: fidelity.glass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: fidelity.chromeLine),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SkeletonBone(
                        progress: progress,
                        width: 59,
                        height: 59,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(height: 14),
                      _SkeletonBone(progress: progress, width: 98, height: 10),
                      const SizedBox(height: 7),
                      _SkeletonBone(progress: progress, width: 68, height: 8),
                    ],
                  ),
                ),
            ],
          ),
          if (!referenceLayout) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

final class _SkeletonBone extends StatelessWidget {
  const _SkeletonBone({
    required this.progress,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
  });

  final double progress;
  final double width;
  final double height;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    final travel = -2.2 + progress * 4.4;
    final base = Color.alphaBlend(
      fidelity.ink.withValues(alpha: 0.055),
      fidelity.controlSurface,
    );
    final highlight = Color.alphaBlend(
      fidelity.ink.withValues(alpha: 0.11),
      fidelity.controlSurface,
    );
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(height / 2)
              : null,
          gradient: LinearGradient(
            begin: Alignment(travel - 1, 0),
            end: Alignment(travel + 1, 0),
            colors: [base, highlight, base],
            stops: const [0.18, 0.5, 0.82],
          ),
        ),
      ),
    );
  }
}

/// Empty state used only for an empty user-photo tab.
final class WardrobeEmptyState extends StatelessWidget {
  const WardrobeEmptyState({
    required this.referenceLayout,
    required this.onCreate,
    super.key,
  });

  final bool referenceLayout;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _EmptyCompanion()),
        const SizedBox(height: 7),
        Center(
          child: Container(
            constraints: const BoxConstraints(minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: fidelity.controlSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: fidelity.chromeLine),
            ),
            child: Text(
              l10n.wardrobeEmptyBadge,
              style: context.chromeKissText.status.copyWith(
                color: fidelity.accentInk,
                fontSize: 10,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          l10n.myContentEmptyTitle,
          textAlign: TextAlign.center,
          style: context.chromeKissText.title.copyWith(
            color: fidelity.ink,
            fontSize: 30,
            height: 34 / 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.myContentEmptyMessage,
          textAlign: TextAlign.center,
          style: context.chromeKissText.body.copyWith(
            color: fidelity.mutedInk,
            fontSize: 13,
            height: 20 / 13,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 58,
          child: FilledButton(
            key: const Key('wardrobe_empty_create_button'),
            onPressed: onCreate,
            child: Text(l10n.createFirstLook),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            key: const Key('wardrobe_empty_add_photo_button'),
            onPressed: onCreate,
            child: Text(l10n.addPhoto),
          ),
        ),
        const SizedBox(height: 17),
        ChromeKissScriptHeartText(
          text: l10n.wardrobeEmptyAccent,
          fontSize: 18,
          centered: true,
        ),
      ],
    );
    final padded = Padding(
      padding: EdgeInsets.only(top: referenceLayout ? 18 : 12),
      child: content,
    );
    if (!referenceLayout) return padded;
    return SizedBox(width: 345, height: 548, child: padded);
  }
}

final class _EmptyCompanion extends StatelessWidget {
  const _EmptyCompanion();

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Semantics(
      label: AppLocalizations.of(context).emptyLookPreview,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      fidelity.chromeLine,
                      fidelity.specular,
                      fidelity.chromeLine,
                      context.chromeKiss.materialChampagne,
                      fidelity.chromeLine,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fidelity.lacquer.withValues(alpha: 0.14),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: fidelity.lensGradient,
                  border: Border.all(color: fidelity.chromeLine),
                  boxShadow: [
                    BoxShadow(
                      color: fidelity.lacquer.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < 2; index++) ...[
                      Container(
                        width: 23,
                        height: 38,
                        decoration: BoxDecoration(
                          color: fidelity.lacquer,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      if (index == 0) const SizedBox(width: 20),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 18,
                top: 29,
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: fidelity.specular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact retry state for a failed scene catalogue request.
final class WardrobeErrorState extends StatelessWidget {
  const WardrobeErrorState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: fidelity.lensGradient,
                border: Border.all(color: fidelity.chromeLine),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: fidelity.accentInk,
                size: 29,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.wardrobeSceneErrorTitle,
              textAlign: TextAlign.center,
              style: context.chromeKissText.title.copyWith(fontSize: 27),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wardrobeSceneErrorMessage,
              textAlign: TextAlign.center,
              style: context.chromeKissText.body.copyWith(
                color: fidelity.mutedInk,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 250,
              child: JewelButton(
                key: const Key('wardrobe_retry_button'),
                label: l10n.retry,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
