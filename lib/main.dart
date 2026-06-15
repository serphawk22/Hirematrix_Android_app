import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/notification_controller.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/services/local_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart' as rec_auth_ctrl;
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart' as rec_jobs_ctrl;
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart' as rec_dash_ctrl;
import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart' as rec_app_ctrl;
import 'package:hirematrix/controllers/recruiter_controller/candidates_controller.dart' as rec_candidates_ctrl;
import 'package:hirematrix/views/screens/recruiter/utils/theme_provider.dart' as rec_theme;
import 'package:hirematrix/controllers/recruiter_controller/leaderboard_controller.dart' as rec_leaderboard_ctrl;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // Register AuthController globally
  final authController = Get.put(AuthController(), permanent: true);

  // Register NotificationController globally for polling
  Get.put(NotificationController(), permanent: true);

  // Load persisted user if exists
  final savedUserStr = prefs.getString('currentUser');
  String initialRoute = AppRoutes.landing;

  if (savedUserStr != null) {
    try {
      final user = jsonDecode(savedUserStr);
      authController.currentUser.value = user;

      final onboardingCompleted =
          int.tryParse(user['onboarding_completed']?.toString() ?? '0') ?? 0;
      if (user['role'] == 'candidate' && onboardingCompleted == 0) {
        initialRoute = AppRoutes.onboarding;
      } else if (user['role'] == 'recruiter') {
        initialRoute = AppRoutes.recruiterDashboard;
      } else {
        initialRoute = AppRoutes.dashboard;
      }
    } catch (e) {
      // ignore
      debugPrint("Error loading user: $e");
    }
  }

  runApp(HireMatrixApp(isDarkMode: isDarkMode, initialRoute: initialRoute));
}

class HireMatrixApp extends StatelessWidget {
  final bool isDarkMode;
  final String initialRoute;
  const HireMatrixApp({
    super.key,
    required this.isDarkMode,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize theme controller
    final themeController = Get.put(ThemeController(isDarkMode: isDarkMode));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => rec_auth_ctrl.AuthController()),
        ChangeNotifierProvider(create: (_) => rec_jobs_ctrl.JobsController()),
        ChangeNotifierProvider(create: (_) => rec_dash_ctrl.DashboardController()),
        ChangeNotifierProvider(create: (_) => rec_app_ctrl.ApplicationsController()),
        ChangeNotifierProvider(create: (_) => rec_candidates_ctrl.CandidatesController()),
        ChangeNotifierProvider(create: (_) => rec_theme.ThemeProvider()),
        ChangeNotifierProvider(create: (_) => rec_leaderboard_ctrl.LeaderboardController()),
      ],
      child: Obx(
        () => GetMaterialApp(
          title: 'HireMatrix',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          getPages: AppRoutes.pages,
          theme: ThemeData(
            fontFamily: GoogleFonts.inter().fontFamily,
            scaffoldBackgroundColor: AppColors.bgLight,
            primaryColor: AppColors.primaryLight,
            cardColor: AppColors.cardLight,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight,
              secondary: AppColors.secondaryLight,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: GoogleFonts.inter().fontFamily,
            scaffoldBackgroundColor: AppColors.bgDark,
            primaryColor: AppColors.primaryDark,
            cardColor: AppColors.bgCardDark,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryDark,
              secondary: AppColors.secondaryDark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          themeMode: themeController.themeMode,
        ),
      ),
    );
  }
}
