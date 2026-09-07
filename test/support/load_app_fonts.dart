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
