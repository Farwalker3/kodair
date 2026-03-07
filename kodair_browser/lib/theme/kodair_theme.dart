import 'package:flutter/material.dart';

class KodairTheme {
  // Core gradients from style.css
  static const Color primaryBlue = Color(0xFF6688FF);
  static const Color primaryGreen = Color(0xFF66FF88);
  static const Color darkBg = Color(0xFF002B36);
  static const Color lightBg = Color(0xFFFDF6E3);

  // App button colors
  static const Color appButtonBg = Color(0xBF64C8FA); // rgba(100,200,250,0.75)
  static const Color appButtonText = Color(0xBFC8FAFA); // rgba(200,250,250,0.75)
  static const Color appButtonHover = Color(0xFF446688);

  // Size bar colors
  static const Color sizeBarBg = Color(0x80646464); // rgba(100,100,100,0.5)
  static const Color sizeActionBg = Color(0xBFC8FAFA);

  // Traffic light buttons
  static const Color closeRed = Color(0xFFFF0000);
  static const Color refreshYellow = Color(0xFFDDDD50);
  static const Color fullscreenGreen = Color(0xFF50DD50);
  static const Color backBlue = Color(0xFF0000FF);
  static const Color forwardCyan = Color(0xFF00EEFF);

  // Panel colors
  static const Color panelBg = Color(0xBFC8FAC8); // rgba(200,250,200,0.75)
  static const Color appBarBg = Color(0x800A0A0A); // rgba(10,10,10,0.5)
  static const Color sockBg = Color(0x809696C8); // rgba(150,150,200,0.5)
  static const Color searchBg = Color(0xE6969696); // rgba(150,150,150,0.9)
  static const Color searchInputBg = Color(0x806496C8); // rgba(100,150,200,0.5)

  // Tor indicator
  static const Color torPurple = Color(0xFF7D4698);

  // Sidebar gradients
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBlue, primaryGreen],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGreen, primaryBlue],
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryBlue,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: darkBg,
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryBlue,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: lightBg,
  );
}
