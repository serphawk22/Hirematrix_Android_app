import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData getLightTheme() => _buildTheme(Brightness.light);
  static ThemeData getDarkTheme() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final primary = AppColors.getPrimary(isDark);
    final background = AppColors.getBackground(isDark);
    final cardColor = AppColors.getCard(isDark);
    final textColor = AppColors.getText(isDark);
    final textMuted = AppColors.getTextMuted(isDark);
    final borderColor = AppColors.getBorder(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: AppSpacing.appBarHeight,
        iconTheme: IconThemeData(color: textColor, size: 20),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: cardColor,
        error: AppColors.error,
      ),

      // STANDARDIZED TYPOGRAPHY SYSTEM
      textTheme: TextTheme(
        // Page titles: 24sp w800
        displayLarge: GoogleFonts.inter(fontSize: AppTypography.display, fontWeight: FontWeight.w800, color: textColor),
        // Section titles: 20sp w700
        displayMedium: GoogleFonts.inter(fontSize: AppTypography.heading, fontWeight: FontWeight.w700, color: textColor),
        // Metric numbers: 18-22sp w800
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
        // Card titles: 14-16sp w700
        titleLarge: GoogleFonts.inter(fontSize: AppTypography.subheading, fontWeight: FontWeight.w700, color: textColor),
        // Medium body / Tabs: 14sp w600
        titleMedium: GoogleFonts.inter(fontSize: AppTypography.body, fontWeight: FontWeight.w600, color: textColor),
        // Labels: 11-13sp w400
        bodySmall: GoogleFonts.inter(fontSize: AppTypography.small, fontWeight: FontWeight.w400, color: textMuted),
        // Standard body: 14sp w400
        bodyMedium: GoogleFonts.inter(fontSize: AppTypography.body, fontWeight: FontWeight.w400, color: textColor),
        // Buttons: 13-14sp w700
        labelLarge: GoogleFonts.inter(fontSize: AppTypography.button, fontWeight: FontWeight.w700, color: textColor),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.mainCard),
          side: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: borderColor.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: AppTypography.button, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.bgSoftDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textMuted),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
