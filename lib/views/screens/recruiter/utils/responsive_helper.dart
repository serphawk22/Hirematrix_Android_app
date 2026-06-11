import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  static late bool isSmallPhone;
  static late bool isMediumPhone;
  static late bool isLargePhone;
  static late bool isTablet;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    isSmallPhone = screenWidth < 360;
    isMediumPhone = screenWidth >= 360 && screenWidth < 420;
    isLargePhone = screenWidth >= 420 && screenWidth < 600;
    isTablet = screenWidth >= 600;
  }

  // Adaptive Font Sizing
  static double fontSize(double size) {
    if (isSmallPhone) return size * 0.9;
    if (isTablet) return size * 1.15;
    return size;
  }

  // Adaptive Spacing
  static double spacing(double size) {
    if (isSmallPhone) return size * 0.85;
    if (isTablet) return size * 1.25;
    return size;
  }

  // Adaptive Icon Sizing
  static double iconSize(double size) {
    if (isSmallPhone) return size * 0.9;
    if (isTablet) return size * 1.2;
    return size;
  }

  // Adaptive Card Radius
  static double get cardRadius => isSmallPhone ? 14.0 : (isTablet ? 20.0 : 18.0);

  // Adaptive Horizontal Padding
  static double get paddingH => isSmallPhone ? 12.0 : (isTablet ? 24.0 : 16.0);

  // Adaptive Search Bar Height
  static double get searchHeight => isSmallPhone ? 38.0 : (isTablet ? 48.0 : 42.0);

  // Adaptive Button Height
  static double get btnHeight => isSmallPhone ? 32.0 : (isTablet ? 44.0 : 38.0);

  // Adaptive Grid Aspect Ratio
  static double gridRatio(double base) {
    if (isSmallPhone) return base * 0.95;
    if (isTablet) return base * 1.1;
    return base;
  }

  // Scaled values
  static double scale(double size) {
    double scaleFactor = screenWidth / 375.0; // Base width for scaling
    return size * scaleFactor;
  }
}
