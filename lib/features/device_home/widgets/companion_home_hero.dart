import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../domain/device/device_snapshot.dart';
import '../../../domain/device/display_profile.dart';
import '../../../l10n/app_localizations.dart';
import 'chrome_kiss_sparkle.dart';
import 'companion_stage.dart';

final class CompanionHomeHero extends StatelessWidget {
  const CompanionHomeHero({
    required this.scene,
    required this.displayProfile,
    required this.snapshot,
    super.key,
  });

  static const height = 334.0;

  final Scene scene;
  final DisplayProfile displayProfile;
  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      key: const Key('companion_home_hero'),
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -2,
            top: -22,
            width: 398,
            height: 398,
            child: IgnorePointer(
              child: Image.asset(
                'assets/chrome_kiss/atmosphere_orchid_halo.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 97,
            width: 64,
            child: Semantics(
              label: '${l10n.companionWelcome}, ${l10n.heartSymbolLabel}',
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: 8 * math.pi / 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.companionWelcome,
                        style: TextStyle(
                          color: colors.accentOptical,
                          fontFamily: 'GreatVibes',
                          fontSize: 20,
                          height: 1.1,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                      Icon(
                        Icons.favorite_border_rounded,
                        color: colors.accentOptical,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 338,
            top: 60,
            width: 11,
            height: 11,
            child: ChromeKissSparkle(color: colors.accentPrimary),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CompanionStage(
              scene: scene,
              displayProfile: displayProfile,
              snapshot: snapshot,
              diameter: 274,
              jewelryMode: true,
            ),
          ),
        ],
      ),
    );
  }
}
