import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hirematrix/views/screens/candidate/features_screen.dart';
import 'package:hirematrix/views/screens/landing_screen.dart';
import 'package:hirematrix/views/screens/candidate/dashboard_screen.dart';
import 'package:hirematrix/views/screens/login_screen.dart';
import 'package:hirematrix/views/screens/candidate/candidate_register_screen.dart'
    show RegisterScreen;
import 'package:hirematrix/views/screens/recruiter/auth/recruiter_register_screen.dart';
import 'package:hirematrix/views/screens/recruiter/auth/recruiter_verification_screen.dart';
import 'package:hirematrix/views/screens/candidate/onboarding_screen.dart';
import 'package:hirematrix/views/screens/candidate/smart_jobs_screen.dart';
import 'package:hirematrix/views/screens/candidate/my_interview_bookings_screen.dart';
import 'package:hirematrix/views/screens/candidate/company_discovery_screen.dart';
import 'package:hirematrix/views/screens/recruiter/dashboard/dashboard_screen.dart' as recruiter_dashboard;
import 'package:hirematrix/views/screens/candidate/job_search_strategy_screen.dart';
import 'package:hirematrix/views/screens/candidate/plans_screen.dart';
import 'package:hirematrix/views/screens/candidate/local_companies_screen.dart';
import 'package:hirematrix/views/screens/candidate/forgot_password_screen.dart';
import 'package:hirematrix/views/screens/candidate/reset_password_screen.dart';
import 'package:hirematrix/views/screens/candidate/career_transition_screen.dart';
import 'package:hirematrix/views/screens/candidate/resume_studio_screen.dart';
import 'package:hirematrix/views/screens/candidate/notification_screen.dart';
import 'package:hirematrix/views/screens/candidate/messages_screen.dart';
import 'package:hirematrix/views/screens/site/about_screen.dart';
import 'package:hirematrix/views/screens/site/contact_screen.dart';
import 'package:hirematrix/views/screens/site/privacy_policy_screen.dart';
import 'package:hirematrix/views/screens/site/terms_of_service_screen.dart';

// Recruiter Screen and Controller Imports
import 'package:hirematrix/views/screens/recruiter/main_screen.dart'
    as rec_main;
import 'package:provider/provider.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart'
    as rec_auth_ctrl;
import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart'
    as rec_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String recruiterRegister = '/recruiter/register';
  static const String recruiterVerify = '/recruiter/verify';
  static const String jobs = '/jobs';
  static const String careerTransition = '/career-transition';
  static const String features = '/features';
  static const String dashboard = '/candidate/dashboard';
  static const String onboarding = '/candidate/onboarding';
  static const String jobSearchStrategy = '/candidate/job-search-strategy';
  static const String companyDiscovery = '/candidate/company-discovery';
  static const String plans = '/premium/plans';
  static const String localCompanies = '/localcompany';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String resumeStudio = '/candidate/resume-studio';
  static const String notifications = '/candidate/notifications';
  static const String messages = '/candidate/messages';
  static const String recruiterDashboard = '/recruiter/dashboard';
  static const String recruiterLogin = '/recruiter/login';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  static List<GetPage> pages = [
    GetPage(
      name: landing,
      page: () => const LandingScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recruiterRegister,
      page: () => const RecruiterRegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recruiterVerify,
      page: () => const RecruiterVerificationScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: jobs,
      page: () => const SmartJobsScreen(showBackButton: true),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: features,
      page: () => const FeaturesScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: jobSearchStrategy,
      page: () => const JobSearchStrategyScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: companyDiscovery,
      page: () => const CompanyDiscoveryScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: plans,
      page: () => const PlansScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: localCompanies,
      page: () => const LocalCompaniesScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: resetPassword,
      page: () => const ResetPasswordScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: careerTransition,
      page: () => const CareerTransitionScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: resumeStudio,
      page: () => const ResumeStudioScreen(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: notifications,
      page: () => const NotificationScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: messages,
      page: () => const MessagesScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recruiterDashboard,
      page: () => const RecruiterProviderWrapper(child: rec_main.MainScreen()),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recruiterLogin,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: about,
      page: () => const AboutScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: contact,
      page: () => const ContactScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: termsOfService,
      page: () => const TermsOfServiceScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}

class RecruiterProviderWrapper extends StatelessWidget {
  final Widget child;
  const RecruiterProviderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final providerAuth = Provider.of<rec_auth_ctrl.AuthController>(
      context,
      listen: false,
    );
    if (providerAuth.currentRecruiter == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
          final savedId = prefs.getString('recruiterId');
          final cachedData = prefs.getString('recruiterData');
          if (isLoggedIn && savedId != null && cachedData != null) {
            final recruiter = rec_model.Recruiter.fromJson(
              jsonDecode(cachedData),
            );
            providerAuth.updateRecruiterInfo(recruiter);
          } else {
            // Also clear the global session so main.dart doesn't keep routing here on startup
            prefs.remove('currentUser');
            Get.offAllNamed(AppRoutes.landing);
          }
        } catch (e) {
          debugPrint("Wrapper: Error restoring recruiter session: $e");
          Get.offAllNamed(AppRoutes.landing);
        }
      });
    }
    return child;
  }
}
