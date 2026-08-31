import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../domain/content/scene.dart';
import '../../../domain/device/device_snapshot.dart';
import '../../../domain/device/display_profile.dart';
import '../../../l10n/app_localizations.dart';
import 'virtual_screen.dart';

final class KeychainPreview extends StatelessWidget {
  const KeychainPreview({
    required this.scene,
    required this.displayProfile,
    required this.snapshot,
    super.key,
  });

  final Scene scene;
  final DisplayProfile displayProfile;
  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      image: true,
      label: l10n.devicePreviewLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bodySize = constraints.maxWidth.clamp(250.0, 330.0);
          return SizedBox(
            height: bodySize + 70,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: bodySize * 0.32,
                  height: bodySize * 0.32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.amber, width: 12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: bodySize * 0.19,
                  child: Container(
                    width: bodySize,
                    height: bodySize,
                    padding: EdgeInsets.all(bodySize * 0.14),
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x50000000),
                          blurRadius: 28,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.coralDark,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(bodySize * 0.035),
                        child: VirtualScreen(
                          scene: scene,
                          displayProfile: displayProfile,
                          snapshot: snapshot,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
