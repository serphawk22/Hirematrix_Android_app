import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFF1FB7B5); // --primary
  static const Color primaryDarkLight = Color(0xFF0D8A90); // --primary-dark
  static const Color secondaryLight = Color(0xFF53B86C); // --secondary
  static const Color secondaryDarkLight = Color(0xFF3F9E58); // --secondary-dark
  static const Color accentLight = Color(0xFFB5D84E); // --accent
  static const Color accentDarkLight = Color(0xFF9DC23D); // --accent-dark

  static const Color bgLight = Color(0xFFF8FCFB); // --background
  static const Color textLight = Color(0xFF16212B); // --foreground
  static const Color cardLight = Color(0xFFFFFFFF); // --card
  static const Color mutedBgLight = Color(0xFFEDF8F5); // --muted
  static const Color textMutedLight = Color(0xFF64748B); // --muted-foreground
  static const Color borderLight = Color(0xFFD9ECE5); // --border
  static const Color textLightSecondary = Color(0xFF94A3B8); // --text-light

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF1FB7B5); // --primary
  static const Color primaryDarkDark = Color(0xFF0D8A90); // --primary-dark
  static const Color secondaryDark = Color(0xFF53B86C); // --secondary
  static const Color secondaryDarkDark = Color(0xFF3F9E58); // --secondary-dark
  static const Color accentDark = Color(0xFFB5D84E); // --accent
  static const Color accentDarkDark = Color(0xFF9DC23D); // --accent-dark

  static const Color bgDark = Color(0xFF0E1619); // --background
  static const Color textDark = Color(0xFFF8FAFC); // --foreground
  static const Color bgCardDark = Color(0xFF162327); // --card
  static const Color bgSoftDark = Color(0xFF1B2A2F); // --muted
  static const Color textMutedDark = Color(0xFF94A3B8); // --muted-foreground
  static const Color borderDark = Color(0xFF23343A); // --border
  static const Color textDarkSecondary = Color(0xFF7A8B96); // --text-light

  // Status Colors (Common)
  static const Color success = Color(0xFF53B86C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF1FB7B5);

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1FB7B5),
      Color(0xFF53B86C),
      Color(0xFFB5D84E),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const Gradient softGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF4FBFA),
      Color(0xFFEEF9F2),
    ],
    stops: [0.0, 1.0],
  );

  static const Gradient softGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF162327),
      Color(0xFF1B2A2F),
    ],
    stops: [0.0, 1.0],
  );

  // Theme helper methods
  static Color getPrimary(bool isDarkMode) =>
      isDarkMode ? primaryDark : primaryLight;
  static Color getPrimaryDark(bool isDarkMode) =>
      isDarkMode ? primaryDarkDark : primaryDarkLight;
  static Color getSecondary(bool isDarkMode) =>
      isDarkMode ? secondaryDark : secondaryLight;
  static Color getSecondaryDark(bool isDarkMode) =>
      isDarkMode ? secondaryDarkDark : secondaryDarkLight;
  static Color getAccent(bool isDarkMode) =>
      isDarkMode ? accentDark : accentLight;
  static Color getAccentDark(bool isDarkMode) =>
      isDarkMode ? accentDarkDark : accentDarkLight;
  static Color getBackground(bool isDarkMode) => isDarkMode ? bgDark : bgLight;
  static Color getCard(bool isDarkMode) => isDarkMode ? bgCardDark : cardLight;
  static Color getText(bool isDarkMode) => isDarkMode ? textDark : textLight;
  static Color getTextMuted(bool isDarkMode) =>
      isDarkMode ? textMutedDark : textMutedLight;
  static Color getBorder(bool isDarkMode) =>
      isDarkMode ? borderDark : borderLight;
  static Color getMutedBg(bool isDarkMode) =>
      isDarkMode ? bgSoftDark : mutedBgLight;
  static Color getTextLight(bool isDarkMode) =>
      isDarkMode ? textDarkSecondary : textLightSecondary;

  static Gradient getSoftGradient(bool isDarkMode) =>
      isDarkMode ? softGradientDark : softGradientLight;
}
