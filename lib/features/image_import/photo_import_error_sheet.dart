import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chrome_kiss_material_sheet.dart';

enum PhotoImportErrorAction { retry, close }

/// Recovery sheet for failures raised before the image editor is opened.
final class PhotoImportErrorSheet extends StatelessWidget {
  const PhotoImportErrorSheet({required this.failureLabel, super.key});

  final String failureLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final fidelity = context.chromeKissFidelity;
    return ChromeKissMaterialSheet(
      key: const Key('photo_import_error_sheet'),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      child: Semantics(
        container: true,
        namesRoute: true,
        label: l10n.photoImportErrorTitle,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.photoImportLabel,
                style: context.chromeKissText.status.copyWith(
                  color: fidelity.accentInk,
                  fontSize: 11,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.photoImportErrorTitle,
                style: context.chromeKissText.title.copyWith(
                  color: fidelity.ink,
                  fontSize: 31,
                  height: 36 / 31,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fidelity.controlSurface,
                      border: Border.all(color: fidelity.lacquer, width: 1.2),
                    ),
                    child: Icon(
                      Icons.hide_image_outlined,
                      color: fidelity.accentInk,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      failureLabel,
                      style: context.chromeKissText.body.copyWith(
                        color: fidelity.mutedInk,
                        fontSize: 13,
                        height: 20 / 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: fidelity.controlSurface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: fidelity.chromeLine),
                ),
                child: Text(
                  l10n.photoImportUnchanged,
                  style: context.chromeKissText.body.copyWith(
                    color: fidelity.ink,
                    fontSize: 12,
                    height: 17 / 12,
                  ),
                ),
              ),
              const SizedBox(height: 58),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const Key('photo_import_retry_button'),
                  onPressed: () =>
                      Navigator.of(context).pop(PhotoImportErrorAction.retry),
                  style: FilledButton.styleFrom(
                    backgroundColor: fidelity.lacquer,
                    foregroundColor: colors.onAccent,
                  ),
                  child: Text(l10n.chooseAnotherPhoto),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextButton(
                  key: const Key('photo_import_close_button'),
                  onPressed: () =>
                      Navigator.of(context).pop(PhotoImportErrorAction.close),
                  child: Text(
                    l10n.returnBack,
                    style: context.chromeKissText.label.copyWith(
                      color: fidelity.mutedInk,
                      fontSize: 13,
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
