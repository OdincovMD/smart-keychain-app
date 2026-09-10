import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  final unbounded = FontLoader('Unbounded')
    ..addFont(rootBundle.load('assets/fonts/Unbounded.ttf'));
  final manrope = FontLoader('Manrope')
    ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
  final fredoka = FontLoader('Fredoka')
    ..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'));
  final nunitoSans = FontLoader('NunitoSans')
    ..addFont(rootBundle.load('assets/fonts/NunitoSans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));

  await Future.wait([
    unbounded.load(),
    manrope.load(),
    fredoka.load(),
    nunitoSans.load(),
    materialIcons.load(),
  ]);
}

Future<void> loadCompanionHomeFonts() async {
  await loadAppFonts();
  final greatVibes = FontLoader('GreatVibes')
    ..addFont(rootBundle.load('assets/fonts/GreatVibes-Regular.ttf'));
  final cormorantGaramond = FontLoader('CormorantGaramond')
    ..addFont(rootBundle.load('assets/fonts/CormorantGaramond.ttf'));

  await Future.wait([greatVibes.load(), cormorantGaramond.load()]);
}
