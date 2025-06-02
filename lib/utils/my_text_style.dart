import 'package:flutter/material.dart';

class MyTextStyle {
  static TextStyle getTextStyle({
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    String fontFamily = 'Poppins', // Assuming Poppins is the default font
    double fontSize = 14.0, // Default size, can be adjusted
  }) {
    return TextStyle(
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
  }

  static TextStyle get size12 => getTextStyle(fontSize: 12.0);
  static TextStyle get size15 => getTextStyle(fontSize: 15.0);
  static TextStyle get size18 => getTextStyle(fontSize: 18.0);
  static TextStyle get size21 => getTextStyle(fontSize: 21.0);
  static TextStyle get size24 => getTextStyle(fontSize: 24.0);
  static TextStyle get size32 => getTextStyle(fontSize: 32.0);
  static TextStyle get size48 => getTextStyle(fontSize: 48.0);
  static TextStyle get size54 => getTextStyle(fontSize: 54.0);

  // Example usage with custom parameters:
  // static TextStyle get boldBlueSize24 => getTextStyle(
  //       fontWeight: FontWeight.bold,
  //       color: Colors.blue,
  //       fontSize: 24.0,
  //     );
}
