import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appearance/appearance_controller.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'chrome_kiss_theme.dart';
import 'router.dart';

final class SmartKeychainApp extends ConsumerWidget {
  const SmartKeychainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appearance = ref.watch(appAppearanceProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ResolvedAppAppearance.pearl),
      darkTheme: buildAppTheme(ResolvedAppAppearance.obsidian),
      themeMode: themeModeFor(appearance),
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
