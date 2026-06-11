import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeController get _controller => Get.find<ThemeController>();

  ThemeMode get themeMode => _controller.themeMode;

  void toggleTheme() {
    _controller.toggleTheme();
    notifyListeners();
  }
}
