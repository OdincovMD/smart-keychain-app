import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  final fredoka = FontLoader('Fredoka')
    ..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'));
  final nunitoSans = FontLoader('NunitoSans')
    ..addFont(rootBundle.load('assets/fonts/NunitoSans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));

  await Future.wait([fredoka.load(), nunitoSans.load(), materialIcons.load()]);
}
