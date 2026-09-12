import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import '../shared/chrome_kiss_fidelity_tokens.dart';

enum CreateLookScreenResult { pickPhoto }

/// First step of the Chrome Kiss user-photo flow.
final class CreateLookScreen extends StatelessWidget {
  const CreateLookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('create_look_screen'),
      backgroundColor: ChromeKissFidelityTokens.outside,
      body: ChromeKissFidelityFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final exact = constraints.maxWidth >= 380 && textScale <= 1.15;
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
                style: const TextStyle(
                  color: ChromeKissFidelityTokens.mutedInk,
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
              child: Text(
                l10n.createLookTitle,
                style: ChromeKissFidelityTokens.titleStyle,
              ),
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
                style: const TextStyle(
                  color: ChromeKissFidelityTokens.ink,
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
                style: const TextStyle(
                  color: ChromeKissFidelityTokens.ink,
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
                style: const TextStyle(
                  color: ChromeKissFidelityTokens.mutedInk,
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
                        Text(
                          l10n.createLookTitle,
                          style: ChromeKissFidelityTokens.titleStyle,
                        ),
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
    return const Stack(
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
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: const Color(0xCCFFFFFF),
          shape: const CircleBorder(
            side: BorderSide(color: ChromeKissFidelityTokens.chromeLine),
          ),
          child: InkWell(
            key: const Key('create_look_back_button'),
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const Icon(
              Icons.chevron_left_rounded,
              color: ChromeKissFidelityTokens.accentInk,
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
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE8FFFFFF),
                    Color(0x88FFFFFF),
                    Color(0x44ECDDE8),
                  ],
                ),
                border: Border.all(color: ChromeKissFidelityTokens.chromeLine),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    left: 0,
                    top: 0,
                    child: Image(
                      image: AssetImage(
                        'assets/chrome_kiss/create_upload_blush.png',
                      ),
                      width: 260,
                      height: 220,
                      filterQuality: FilterQuality.high,
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
                  const Positioned(
                    left: 85,
                    top: 27,
                    child: Image(
                      image: AssetImage(
                        'assets/chrome_kiss/create_photo_target.png',
                      ),
                      width: 174,
                      height: 174,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const Positioned(
                    left: 145,
                    top: 65,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF171122),
                            ChromeKissFidelityTokens.lens,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33470533),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SizedBox.square(
                        dimension: 56,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
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
                      style: const TextStyle(
                        color: ChromeKissFidelityTokens.ink,
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
                      style: const TextStyle(
                        color: ChromeKissFidelityTokens.mutedInk,
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
    final items = <(String?, String)>[
      (
        'assets/chrome_kiss/create_preview_original.png',
        l10n.inspirationOriginal,
      ),
      ('assets/chrome_kiss/create_preview_mint.png', l10n.inspirationMint),
      ('assets/chrome_kiss/create_preview_lilac.png', l10n.inspirationLilac),
      (null, l10n.inspirationPhoto),
    ];
    final children = [
      for (final (asset, label) in items)
        SizedBox(
          width: 82,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (asset != null)
                    Image.asset(
                      asset,
                      width: 82,
                      height: 82,
                      filterQuality: FilterQuality.high,
                    )
                  else
                    const SizedBox(
                      width: 82,
                      height: 82,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image(
                            image: AssetImage(
                              'assets/chrome_kiss/create_photo_target.png',
                            ),
                            width: 64,
                            height: 64,
                            filterQuality: FilterQuality.high,
                          ),
                          Icon(
                            Icons.add_rounded,
                            size: 22,
                            color: ChromeKissFidelityTokens.lacquer,
                          ),
                        ],
                      ),
                    ),
                  if (asset == null)
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
                  style: const TextStyle(
                    color: ChromeKissFidelityTokens.mutedInk,
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
    return SizedBox(
      width: 83,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: ChromeKissFidelityTokens.mutedInk),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ChromeKissFidelityTokens.mutedInk,
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
    final width = math.min(335.0, MediaQuery.sizeOf(context).width - 48);
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          key: const Key('create_look_continue_button'),
          width: width,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xBFFFFFFF),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: ChromeKissFidelityTokens.chromeLine),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: ChromeKissFidelityTokens.mutedInk,
                size: 23,
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ChromeKissFidelityTokens.mutedInk,
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ChromeKissFidelityTokens.mutedInk,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
