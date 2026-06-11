import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Aligned with Shared Website)
  static const Color primaryLight = Color(0xFF1FB7B5);
  static const Color primaryDarkLight = Color(0xFF0D8A90);
  
  static const Color secondaryLight = Color(0xFF53B86C);
  static const Color secondaryDarkLight = Color(0xFF3F9E58);
  
  static const Color accentLight = Color(0xFFB5D84E);
  static const Color accentDarkLight = Color(0xFF9DC23D);
  
  // Layout - Light Mode
  static const Color bgLight = Color(0xFFF8FCFB);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF16212B);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFD9ECE5);

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF0E1619);
  static const Color bgSoftDark = Color(0xFF1B2A2F);
  static const Color bgCardDark = Color(0xFF162327);
  static const Color textDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF23343A);
  
  static const Color primaryDark = Color(0xFF1FB7B5);
  static const Color secondaryDark = Color(0xFF53B86C);
  static const Color accentDark = Color(0xFFB5D84E);

  // Status Colors (Common)
  static const Color success = Color(0xFF53B86C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF1FB7B5);

  // Theme helper methods
  static Color getPrimary(bool isDarkMode) => isDarkMode ? primaryDark : primaryLight;
  static Color getBackground(bool isDarkMode) => isDarkMode ? bgDark : bgLight;
  static Color getCard(bool isDarkMode) => isDarkMode ? bgCardDark : cardLight;
  static Color getText(bool isDarkMode) => isDarkMode ? textDark : textLight;
  static Color getTextMuted(bool isDarkMode) => isDarkMode ? textMutedDark : textMutedLight;
  static Color getBorder(bool isDarkMode) => isDarkMode ? borderDark : borderLight;
  static Color getSecondary(bool isDarkMode) => isDarkMode ? secondaryDark : secondaryLight;
  static Color getAccent(bool isDarkMode) => isDarkMode ? accentDark : accentLight;
}

class AppSpacing {
  static const double tiny = 4.0;
  static const double inner = 8.0;
  static const double compact = 12.0;
  static const double standard = 16.0;
  static const double section = 24.0;
  static const double max = 32.0;

  static const double horizontalPadding = 16.0;
  static const double sectionGap = 20.0;
  static const double cardInternalPadding = 12.0;
  static const double cardGap = 12.0;
  
  static const double appBarHeight = 56.0;
  static const double searchBarHeight = 44.0;
}

class AppTypography {
  static const double display = 24.0;    // Page Titles
  static const double heading = 20.0;    // Section Headers
  static const double subheading = 16.0; // Card Titles / Medium headings
  static const double body = 14.0;       // Standard Body text
  static const double small = 12.0;      // Labels / Caption / Secondary text
  static const double tiny = 10.0;       // Micro text / Overline
  static const double button = 14.0;     // Buttons / Primary actions
}

class AppRadius {
  static const double mainCard = 18.0;
  static const double smallCard = 14.0;
  static const double button = 12.0;
  static const double input = 12.0;
}

class AppStrings {
  static const String appName = "HireMatrix";
}
