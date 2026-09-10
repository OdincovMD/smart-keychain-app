import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../domain/device/device_snapshot.dart';
import '../../../domain/device/display_profile.dart';
import '../../../l10n/app_localizations.dart';
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
          Align(
            alignment: const Alignment(0, -0.17),
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.accentPrimary.withValues(alpha: 0.3),
                    colors.accentPrimary.withValues(alpha: 0.1),
                    colors.canvas.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 92,
            width: 88,
            child: Semantics(
              label: '${l10n.companionWelcome}, ${l10n.heartSymbolLabel}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.companionWelcome,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'GreatVibes',
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: colors.textPrimary,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 27,
            top: 54,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: colors.accentOptical,
              size: 22,
            ),
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
