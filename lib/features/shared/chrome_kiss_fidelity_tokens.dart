import 'package:flutter/material.dart';

/// Exact visual tokens shared by the Chrome Kiss Figma fidelity screens.
abstract final class ChromeKissFidelityTokens {
  static const referenceSize = Size(393, 852);

  static const outside = Color(0xFFE5E5E5);
  static const canvas = Color(0xFFF4F2F6);
  static const ink = Color(0xFF211823);
  static const mutedInk = Color(0xFF806E82);
  static const accentInk = Color(0xFFB70A6D);
  static const lacquer = Color(0xFFFF4FB8);
  static const lacquerDeep = Color(0xFF470533);
  static const lens = Color(0xFF020205);
  static const chromeLine = Color(0xFFD9D8E2);
  static const specular = Color(0xFFF8F3FF);

  static const pearlGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFBF8F7),
      Color(0xFFF2EFF5),
      Color(0xFFE7E3ED),
      Color(0xFFFAF7F4),
      Color(0xFFEDE5ED),
    ],
    stops: [0, 0.28, 0.52, 0.76, 1],
  );

  static const lacquerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8CD1), lacquer, Color(0xFFB80A6E), lacquerDeep],
    stops: [0, 0.34, 0.7, 1],
  );

  static const titleStyle = TextStyle(
    color: ink,
    fontFamily: 'CormorantGaramond',
    fontSize: 30,
    height: 32 / 30,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const scriptStyle = TextStyle(
    color: accentInk,
    fontFamily: 'GreatVibes',
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const bodyStyle = TextStyle(
    color: ink,
    fontFamily: 'Manrope',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
}
