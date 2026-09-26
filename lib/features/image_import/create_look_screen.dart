import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/chrome_kiss_eye_reaction_lens.dart';
import '../device_home/widgets/kiss_cut_eye_renderer.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import '../shared/chrome_kiss_fidelity_tokens.dart';

enum CreateLookScreenResult { pickPhoto }

/// First step of the Chrome Kiss user-photo flow.
final class CreateLookScreen extends StatelessWidget {
  const CreateLookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Scaffold(
      key: const Key('create_look_screen'),
      backgroundColor: fidelity.outside,
      body: ChromeKissFidelityFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final exact =
                constraints.maxWidth >= 380 &&
                constraints.maxHeight >= 844 &&
                textScale <= 1.15 &&
                MediaQuery.viewPaddingOf(context) == EdgeInsets.zero;
            return exact
                ? const _CreateLookReferenceLayout()
                : const _CreateLookAdaptiveLayout();
          },
        ),
      ),
    );
  }
}

final class _CreateLookReferenceLayout extends StatelessWidget {
  const _CreateLookReferenceLayout();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    return SingleChildScrollView(
      key: const Key('create_look_scroll'),
      child: SizedBox(
        height: ChromeKissFidelityTokens.referenceSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _CreateLookAtmosphere()),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ChromeKissReferenceStatusBar(),
            ),
            Positioned(
              left: 24,
              top: 56,
              child: _BackButton(onPressed: () => Navigator.of(context).pop()),
            ),
            Positioned(
              left: 84,
              top: 53,
              child: Text(
                l10n.createLookStep,
                style: TextStyle(
                  color: fidelity.mutedInk,
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Positioned(
              left: 84,
              top: 71,
              child: Text(l10n.createLookTitle, style: fidelity.titleStyle),
            ),
            Positioned(
              left: 85,
              top: 103,
              child: ChromeKissScriptHeartText(text: l10n.createLookAccent),
            ),
            const Positioned(
              right: 29,
              top: 60,
              child: Image(
                image: AssetImage(
                  'assets/chrome_kiss/create_progress_jewels.png',
                ),
                width: 54,
                height: 16,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: 24,
              top: 142,
              child: _UploadCard(onPressed: () => _pickPhoto(context)),
            ),
            Positioned(
              left: 24,
              top: 448,
              child: Text(
                l10n.inspiration,
                style: TextStyle(
                  color: fidelity.ink,
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  height: 24 / 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Positioned(
              left: 20,
              top: 475,
              child: _InspirationStrip(referenceLayout: true),
            ),
            Positioned(
              left: 38,
              top: 600,
              child: Text(
                l10n.prepareForScreen,
                style: TextStyle(
                  color: fidelity.ink,
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  height: 21 / 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Positioned(left: 48, top: 645, child: _PreparationFeatures()),
            Positioned(
              left: 29,
              top: 716,
              child: _ContinueButton(label: l10n.continueAction),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 800,
              child: Text(
                l10n.choosePhotoToContinue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fidelity.mutedInk,
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  height: 15 / 11,
                ),
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

final class _CreateLookAdaptiveLayout extends StatelessWidget {
  const _CreateLookAdaptiveLayout();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    return CustomScrollView(
      key: const Key('create_look_scroll'),
      slivers: [
        const SliverToBoxAdapter(child: ChromeKissReferenceStatusBar()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.createLookStep),
                        Text(l10n.createLookTitle, style: fidelity.titleStyle),
                        ChromeKissScriptHeartText(text: l10n.createLookAccent),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: _UploadCard(onPressed: () => _pickPhoto(context))),
              const SizedBox(height: 18),
              Text(
                l10n.inspiration,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: _InspirationStrip(referenceLayout: false)),
              const SizedBox(height: 28),
              Text(
                l10n.prepareForScreen,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              const Center(child: _PreparationFeatures()),
              const SizedBox(height: 38),
              Center(child: _ContinueButton(label: l10n.continueAction)),
              const SizedBox(height: 12),
              Text(l10n.choosePhotoToContinue, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              const Center(child: ChromeKissHomeIndicator()),
            ],
          ),
        ),
      ],
    );
  }
}

void _pickPhoto(BuildContext context) {
  Navigator.of(context).pop(CreateLookScreenResult.pickPhoto);
}

final class _CreateLookAtmosphere extends StatelessWidget {
  const _CreateLookAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: context.chromeKissFidelity.atmosphereOpacity,
      child: const Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Image(
              image: AssetImage('assets/chrome_kiss/create_story_blush.png'),
              width: 108,
              height: 190,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: fidelity.controlSurface,
          shape: CircleBorder(side: BorderSide(color: fidelity.chromeLine)),
          child: InkWell(
            key: const Key('create_look_back_button'),
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(
              Icons.chevron_left_rounded,
              color: fidelity.accentInk,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}

final class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final adaptive =
        MediaQuery.sizeOf(context).width < 380 ||
        textScale > 1.15 ||
        MediaQuery.viewPaddingOf(context) != EdgeInsets.zero;
    if (adaptive) {
      return Semantics(
        button: true,
        label: l10n.choosePhoto,
        hint: l10n.photoFormatsHint,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 345),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('create_look_pick_photo'),
              onTap: onPressed,
              borderRadius: BorderRadius.circular(32),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: fidelity.satinGradient,
                  border: Border.all(color: fidelity.chromeLine),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 188,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: fidelity.atmosphereOpacity,
                              child: const Image(
                                image: AssetImage(
                                  'assets/chrome_kiss/create_upload_blush.png',
                                ),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const Image(
                            image: AssetImage(
                              'assets/chrome_kiss/create_upload_halo.png',
                            ),
                            width: 202,
                            height: 202,
                            filterQuality: FilterQuality.high,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: fidelity.uploadTargetGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: 158),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: fidelity.lensGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: fidelity.shadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: SizedBox.square(
                              dimension: 56,
                              child: Icon(
                                Icons.add_rounded,
                                color: fidelity.specular,
                                size: 29,
                              ),
                            ),
                          ),
                          const Positioned(
                            right: 16,
                            top: 2,
                            child: Image(
                              image: AssetImage(
                                'assets/chrome_kiss/create_upload_bow.png',
                              ),
                              width: 40,
                              height: 28,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.choosePhoto,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fidelity.ink,
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        height: 25 / 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.photoFormatsHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fidelity.mutedInk,
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        height: 15 / 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChromeKissScriptHeartText(
                      text: l10n.photoFantasyAccent,
                      fontSize: 20,
                      centered: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: l10n.choosePhoto,
      hint: l10n.photoFormatsHint,
      child: SizedBox(
        width: 345,
        height: 290,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('create_look_pick_photo'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(32),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: fidelity.satinGradient,
                border: Border.all(color: fidelity.chromeLine),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Opacity(
                      opacity: fidelity.atmosphereOpacity,
                      child: const Image(
                        image: AssetImage(
                          'assets/chrome_kiss/create_upload_blush.png',
                        ),
                        width: 260,
                        height: 220,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 61,
                    top: 8,
                    child: Image(
                      image: AssetImage(
                        'assets/chrome_kiss/create_upload_halo.png',
                      ),
                      width: 222,
                      height: 222,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    left: 85,
                    top: 27,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: fidelity.uploadTargetGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 174),
                    ),
                  ),
                  Positioned(
                    left: 145,
                    top: 65,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: fidelity.lensGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: fidelity.shadow,
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SizedBox.square(
                        dimension: 56,
                        child: Icon(
                          Icons.add_rounded,
                          color: fidelity.specular,
                          size: 29,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 131,
                    child: Text(
                      l10n.choosePhoto,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fidelity.ink,
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        height: 25 / 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 222,
                    child: Text(
                      l10n.photoFormatsHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fidelity.mutedInk,
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        height: 15 / 11,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 245,
                    child: ChromeKissScriptHeartText(
                      text: l10n.photoFantasyAccent,
                      fontSize: 20,
                      centered: true,
                    ),
                  ),
                  const Positioned(
                    right: 55,
                    top: 17,
                    child: Image(
                      image: AssetImage(
                        'assets/chrome_kiss/create_upload_bow.png',
                      ),
                      width: 40,
                      height: 28,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const Positioned(
                    right: 60,
                    top: 178,
                    child: Image(
                      image: AssetImage(
                        'assets/chrome_kiss/create_champagne_sparkle.png',
                      ),
                      width: 10,
                      height: 10,
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

final class _InspirationStrip extends StatelessWidget {
  const _InspirationStrip({required this.referenceLayout});

  final bool referenceLayout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final items = <(KissCutColourway?, String)>[
      (KissCutColourway.orchidLilac, l10n.inspirationOriginal),
      (KissCutColourway.icyCool, l10n.inspirationMint),
      (KissCutColourway.lilacDream, l10n.inspirationLilac),
      (null, l10n.inspirationPhoto),
    ];
    final children = [
      for (final (colourway, label) in items)
        SizedBox(
          width: 82,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (colourway != null)
                    SizedBox.square(
                      dimension: 82,
                      child: Center(
                        child: ChromeKissEyeReactionLens(
                          size: ChromeKissEyeReactionLensSize.tiny,
                          mood: KissCutVisualMood.neutral,
                          animate: false,
                          useProductionMotion: false,
                          colourway: colourway,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: fidelity.uploadTargetGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: 64),
                          ),
                          Icon(
                            Icons.add_rounded,
                            size: 22,
                            color: fidelity.lacquer,
                          ),
                        ],
                      ),
                    ),
                  if (colourway == null)
                    const Positioned(
                      right: -2,
                      top: 0,
                      child: Image(
                        image: AssetImage(
                          'assets/chrome_kiss/create_preview_sparkle.png',
                        ),
                        width: 7,
                        height: 7,
                      ),
                    ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -3),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fidelity.mutedInk,
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
    if (!referenceLayout) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
    }
    return SizedBox(
      width: 353,
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }
}

final class _PreparationFeatures extends StatelessWidget {
  const _PreparationFeatures();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 297,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Feature(icon: Icons.circle_outlined, label: l10n.circularCrop),
          _Feature(icon: Icons.auto_awesome_rounded, label: l10n.lightAndColor),
          _Feature(
            icon: Icons.favorite_border_rounded,
            label: l10n.chromeKissFeature,
          ),
        ],
      ),
    );
  }
}

final class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return SizedBox(
      width: 83,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: fidelity.mutedInk),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: fidelity.mutedInk,
                fontFamily: 'Manrope',
                fontSize: 12,
                height: 15 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    final width = math.min(335.0, MediaQuery.sizeOf(context).width - 48);
    final adaptive =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(18) > 21 ||
        MediaQuery.viewPaddingOf(context) != EdgeInsets.zero;
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          key: const Key('create_look_continue_button'),
          width: width,
          height: adaptive ? null : 72,
          constraints: const BoxConstraints(minHeight: 72),
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: adaptive ? 16 : 0,
          ),
          decoration: BoxDecoration(
            color: fidelity.controlSurface,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: fidelity.chromeLine),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: fidelity.mutedInk,
                size: 23,
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fidelity.mutedInk,
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: fidelity.mutedInk,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
